import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/note_model.dart';
import '../../core/services/security_service.dart';
import '../../core/services/vault_service.dart';
import '../../core/state/notes_provider.dart';
import '../security/lock_note_dialog.dart';
import '../theme/apple_theme.dart';
import 'clipboard_image_reader.dart';
import 'pasted_image.dart';
import 'rich_text_editing_controller.dart';
import 'text_part_context_menu.dart';
import 'text_part_split.dart';

export '../../core/models/note_model.dart' show BlockType;

class NoteBlock {
  final String id;
  final GlobalKey widgetKey;
  BlockType type;
  String text;
  bool isChecked;
  List<StyleSpan> spans;
  List<List<String>> tableData;
  RichTextEditingController? controller;
  FocusNode? focusNode;

  /// Focuses the first (`last: false`) or last (`last: true`) cell; set by the table widget.
  void Function({required bool last})? focusCell;

  /// Cursor inside a table cell as row, column and offset, or null; set by the table widget.
  ValueGetter<({int row, int column, int offset})?>? cellCaret;

  /// Puts the cursor in the given cell, clamped to the table; set by the table widget.
  void Function(int row, int column, int offset)? focusCellAt;

  Map<int, BlockType> lineStyles;

  NoteBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.isChecked = false,
    List<StyleSpan>? spans,
    List<List<String>>? tableData,
    GlobalKey? widgetKey,
    Map<int, BlockType>? lineStyles,
  }) : widgetKey = widgetKey ?? GlobalKey(),
       spans = spans ?? [],
       tableData = tableData ?? [],
       lineStyles = lineStyles ?? {};

  Map<String, dynamic> toJson() {
    final effectiveText = controller != null ? controller!.text : text;
    final effectiveSpans = controller != null ? controller!.spans : spans;
    final effectiveLineStyles = controller != null
        ? controller!.lineStyles
        : lineStyles;

    return {
      'id': id,
      'type': type.name,
      'text': effectiveText,
      'isChecked': isChecked,
      'spans': effectiveSpans.map((s) => s.toJson()).toList(),
      if (effectiveLineStyles.isNotEmpty)
        'lineStyles': effectiveLineStyles.map(
          (k, v) => MapEntry(k.toString(), v.name),
        ),
      if (tableData.isNotEmpty) 'tableData': tableData,
    };
  }

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    final Map<int, BlockType> parsedLineStyles = {};
    if (json['lineStyles'] is Map) {
      final rawMap = json['lineStyles'] as Map<String, dynamic>;
      for (final entry in rawMap.entries) {
        final lineIdx = int.tryParse(entry.key);
        if (lineIdx != null) {
          final blockType = BlockType.values.firstWhere(
            (t) => t.name == entry.value,
            orElse: () => BlockType.paragraph,
          );
          parsedLineStyles[lineIdx] = blockType;
        }
      }
    }

    return NoteBlock(
      id: json['id'] as String? ?? const Uuid().v4(),
      type: BlockType.values.firstWhere(
        (t) => t.name == (json['type'] as String?),
        orElse: () => BlockType.paragraph,
      ),
      text: json['text'] as String? ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
      spans:
          (json['spans'] as List<dynamic>?)
              ?.map((s) => StyleSpan.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      tableData:
          (json['tableData'] as List<dynamic>?)
              ?.map(
                (r) => (r as List<dynamic>).map((c) => c.toString()).toList(),
              )
              .toList() ??
          [],
      lineStyles: parsedLineStyles,
    );
  }
}

/// Native Rich Text Editor with authentic Apple Notes fidelity.
/// Real-time live typography (Bold, Italic, Underline, Strikethrough) without any visible markdown delimiters.
class NotionDocumentEditor extends StatefulWidget {
  final Note note;

  const NotionDocumentEditor({super.key, required this.note});

  @override
  State<NotionDocumentEditor> createState() => NotionDocumentEditorState();
}

class NotionDocumentEditorState extends State<NotionDocumentEditor> {
  final List<NoteBlock> _blocks = [];
  final ScrollController _scrollController = ScrollController();
  static const _uuid = Uuid();

  @visibleForTesting
  List<NoteBlock> get debugBlocks => List.unmodifiable(_blocks);

  /// Ids of the notes whose text has been shown since the app opened.
  static final Set<String> _noteIdsWithShownText = {};
  String _lastSerializedContent = '';
  // Counts the loads of the document: a table is rebuilt on each one, so its cells show the loaded text.
  int _documentLoads = 0;
  NoteBlock? _activeBlock;

  /// Last text section that had the focus; the Block menu opens under it when none has.
  NoteBlock? _lastTextBlock;
  NoteBlock? _slashMenuBlock;
  int? _tagAutocompleteBlockIndex;
  String? _tagAutocompleteQuery;
  bool _isPreviewMode = false;
  Timer? _saveDebounceTimer;
  // Set while shown, so an export can take the text still waiting in the debounce.
  NotesProvider? _provider;
  // Hands over the text still waiting when a mobile editor is left by a way back; set by keepWaitingTextOnExit.
  void Function()? _exitDelivery;

  bool get isPreviewMode => _isPreviewMode;

  /// Whether the text of this note has been shown since the app opened. Style changes do not count.
  bool get _textShown => _noteIdsWithShownText.contains(widget.note.id);

  /// Whether the active part holds text (not a table, image or divider).
  bool _isTextPart(NoteBlock b) =>
      b.type != BlockType.table &&
      b.type != BlockType.image &&
      b.type != BlockType.divider;

  NoteBlock? get _currentActiveBlock {
    for (final b in _blocks) {
      if (b.focusNode?.hasFocus ?? false) return b;
    }
    if (_activeBlock != null && _blocks.contains(_activeBlock)) {
      return _activeBlock;
    }
    return _blocks.isNotEmpty ? _blocks.last : null;
  }

  /// Position of the active part; -1 when there is none.
  int get _activeBlockPos {
    final active = _currentActiveBlock;
    return active == null ? -1 : _blocks.indexOf(active);
  }

  /// Part that is active when the note opens: the second, or the first if there is only one.
  NoteBlock? get _initialActiveBlock {
    if (_blocks.isEmpty) return null;
    return _blocks.length > 1 ? _blocks[1] : _blocks[0];
  }

  /// Text section the Block menu opens under: the focused one, else the last one used, else the last text section.
  NoteBlock? get _blockMenuTarget {
    for (final b in _blocks) {
      if (b.focusNode?.hasFocus ?? false) return b;
    }
    if (_lastTextBlock != null && _blocks.contains(_lastTextBlock)) {
      return _lastTextBlock;
    }
    for (final b in _blocks.reversed) {
      if (_isTextPart(b)) return b;
    }
    return null;
  }

  void togglePreviewMode() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
      _activeBlock = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _lastSerializedContent = widget.note.content;
    _parseContentToBlocks(widget.note.content);
    _activeBlock = _initialActiveBlock;
    _provider = context.read<NotesProvider?>();
    _provider?.attachEditorDelivery(_deliverWaitingText);
  }

  @override
  void didUpdateWidget(covariant NotionDocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      // The edit still waiting belongs to the old note: as the Model says, it is discarded, not saved.
      _saveDebounceTimer?.cancel();
      _disposeControllers();
      _slashMenuBlock = null;
      _tagAutocompleteBlockIndex = null;
      _tagAutocompleteQuery = null;
      _lastSerializedContent = widget.note.content;
      _parseContentToBlocks(widget.note.content);
      _activeBlock = _initialActiveBlock;
    } else if (oldWidget.note.content != widget.note.content) {
      // A remote version replaces the document only when the editor has no edit waiting, neither in the
      // debounce window nor in the provider. A focused text line or table cell keeps its cursor.
      final waitingInEditor = _saveDebounceTimer?.isActive ?? false;
      final waitingInProvider = _provider?.hasWaitingContent(widget.note.id) ?? false;
      if (widget.note.content != _lastSerializedContent && !waitingInEditor && !waitingInProvider) {
        // The reload rebuilds the parts: keep the active one by its position.
        final activePos = _activeBlockPos;
        final caret = _focusedTextCaret();
        final cellCaret = _focusedCellCaret();
        _slashMenuBlock = null;
        _tagAutocompleteBlockIndex = null;
        _tagAutocompleteQuery = null;
        _disposeControllers();
        _lastSerializedContent = widget.note.content;
        _parseContentToBlocks(widget.note.content);
        _activeBlock = activePos >= 0 && activePos < _blocks.length
            ? _blocks[activePos]
            : _initialActiveBlock;
        if (cellCaret != null) {
          _restoreCellCaret(cellCaret);
        } else if (caret != null) {
          _restoreCaret(caret);
        }
      }
    }
  }

  /// Cursor of the focused text line: its part index, line and column. Null when no text line has the focus.
  ({int part, int line, int column})? _focusedTextCaret() {
    for (var i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if (!(block.focusNode?.hasFocus ?? false)) continue;
      final ctrl = block.controller;
      if (ctrl == null || !_isTextPart(block)) return null;
      final text = ctrl.text;
      final sel = ctrl.selection;
      final offset = sel.isValid ? (sel.start < text.length ? sel.start : text.length) : text.length;
      final before = text.substring(0, offset);
      return (
        part: i,
        line: '\n'.allMatches(before).length,
        column: offset - before.lastIndexOf('\n') - 1,
      );
    }
    return null;
  }

  /// Puts the cursor back after a remote reload: same line and column if they still exist, else the end of the
  /// nearest line. Focus goes to the nearest text part.
  void _restoreCaret(({int part, int line, int column}) caret) {
    final textParts = [
      for (var i = 0; i < _blocks.length; i++)
        if (_isTextPart(_blocks[i])) i,
    ];
    if (textParts.isEmpty) return;
    final index = textParts.reduce(
      (a, b) => (a - caret.part).abs() <= (b - caret.part).abs() ? a : b,
    );
    final block = _blocks[index];
    _activeBlock = block;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = block.controller;
      final node = block.focusNode;
      if (!mounted || ctrl == null || node == null || !_blocks.contains(block)) return;
      final lines = ctrl.text.split('\n');
      final line = caret.line < lines.length ? caret.line : lines.length - 1;
      final lineText = lines[line];
      var offset = 0;
      for (var i = 0; i < line; i++) {
        offset += lines[i].length + 1;
      }
      offset += caret.column < lineText.length ? caret.column : lineText.length;
      node.requestFocus();
      ctrl.selection = TextSelection.collapsed(offset: offset);
    });
  }

  /// Cursor of the focused table cell: its part index, row, column and offset. Null when no cell has the focus.
  ({int part, int row, int column, int offset})? _focusedCellCaret() {
    for (var i = 0; i < _blocks.length; i++) {
      final cell = _blocks[i].cellCaret?.call();
      if (cell != null) {
        return (part: i, row: cell.row, column: cell.column, offset: cell.offset);
      }
    }
    return null;
  }

  /// Puts the cursor back in a table cell after a remote reload: same row, column and offset if they still exist.
  void _restoreCellCaret(({int part, int row, int column, int offset}) caret) {
    final tableParts = [
      for (var i = 0; i < _blocks.length; i++)
        if (_blocks[i].type == BlockType.table) i,
    ];
    if (tableParts.isEmpty) return;
    final index = tableParts.reduce(
      (a, b) => (a - caret.part).abs() <= (b - caret.part).abs() ? a : b,
    );
    final block = _blocks[index];
    _activeBlock = block;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_blocks.contains(block)) return;
      block.focusCellAt?.call(caret.row, caret.column, caret.offset);
    });
  }

  @override
  void dispose() {
    if (_exitDelivery == null) _saveDebounceTimer?.cancel();
    _provider?.detachEditorDelivery(_deliverWaitingText);
    _disposeControllers();
    _scrollController.dispose();
    super.dispose();
  }

  /// Writes the text waiting in the debounce window now; a no-op otherwise.
  void _deliverWaitingText() {
    if (_saveDebounceTimer?.isActive ?? false) {
      _serializeAndSave(immediate: true);
    }
  }

  /// Called when the mobile editor screen is left by a way back (not by a removal): the text still waiting in the
  /// debounce window is handed over when that wait ends, although this editor is gone by then.
  void keepWaitingTextOnExit() {
    final provider = _provider;
    if (provider == null || !(_saveDebounceTimer?.isActive ?? false)) return;
    final noteId = widget.note.id;
    final jsonString = _serializeBlocks();
    _exitDelivery = () => provider.updateNoteContent(noteId, jsonString);
  }

  void _disposeControllers() {
    for (final b in _blocks) {
      _disposeBlock(b);
    }
    _blocks.clear();
  }

  void _disposeBlock(NoteBlock b) {
    b.controller?.dispose();
    b.focusNode?.dispose();
  }

  /// Removes the part at [index]; if it was the active part, none is remembered.
  void _removeBlockAt(int index) {
    final block = _blocks.removeAt(index);
    _disposeBlock(block);
    if (identical(_activeBlock, block)) _activeBlock = null;
    // The tag menu is tracked by position: a removed section takes its menu, later ones shift up.
    final tagIndex = _tagAutocompleteBlockIndex;
    if (tagIndex != null && tagIndex == index) {
      _tagAutocompleteBlockIndex = null;
      _tagAutocompleteQuery = null;
    } else if (tagIndex != null && tagIndex > index) {
      _tagAutocompleteBlockIndex = tagIndex - 1;
    }
    if (identical(_lastTextBlock, block)) _lastTextBlock = null;
    if (identical(_slashMenuBlock, block)) _slashMenuBlock = null;
  }

  void _parseContentToBlocks(String rawContent) {
    _documentLoads++;
    _disposeControllers();
    _blocks.clear();

    final trimmed = rawContent.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed);
        // Only a list whose items are all objects is a block document; anything else is plain text.
        if (list is! List ||
            !list.every((item) => item is Map<String, dynamic>)) {
          throw const FormatException('not a block list');
        }
        final rawBlocks = <NoteBlock>[
          for (final item in list)
            NoteBlock.fromJson(item as Map<String, dynamic>),
        ];

        final mergedBlocks = <NoteBlock>[];
        String currentText = '';
        // A text block keeps its section even when its text is empty.
        var hasTextBlock = false;
        final currentSpans = <StyleSpan>[];
        final currentLineStyles = <int, BlockType>{};
        int currentLineIdx = 0;
        String? currentId;

        void flushText() {
          if (currentText.isNotEmpty ||
              hasTextBlock ||
              (mergedBlocks.isEmpty && rawBlocks.isEmpty)) {
            mergedBlocks.add(
              NoteBlock(
                id: currentId ?? _uuid.v4(),
                type: BlockType.paragraph,
                text: currentText,
                spans: List.from(currentSpans),
                lineStyles: Map.from(currentLineStyles),
              ),
            );
          }
          currentText = '';
          hasTextBlock = false;
          currentSpans.clear();
          currentLineStyles.clear();
          currentLineIdx = 0;
          currentId = null;
        }

        for (final b in rawBlocks) {
          if (b.type == BlockType.table ||
              b.type == BlockType.image ||
              b.type == BlockType.divider) {
            flushText();
            mergedBlocks.add(b);
          } else {
            hasTextBlock = true;
            currentId ??= b.id;

            final rawLinesInBlock = b.text.split('\n');
            final outputLineStarts = <int>[];
            final strippedLengths = <int>[];
            final displayPrefixes = <int>[];
            final rawLineStarts = <int>[];
            var rawOffset = 0;

            for (int li = 0; li < rawLinesInBlock.length; li++) {
              final rawLine = rawLinesInBlock[li];
              var line = rawLine;
              final lineTrimmed = line.trim();
              BlockType detectedStyle = BlockType.paragraph;

              if (b.lineStyles.containsKey(li)) {
                detectedStyle = b.lineStyles[li]!;
              } else if (li == 0) {
                detectedStyle = b.type;
              }

              if (line.startsWith('### ')) {
                detectedStyle = BlockType.h3;
                line = line.replaceFirst('### ', '');
              } else if (line.startsWith('## ')) {
                detectedStyle = BlockType.h2;
                line = line.replaceFirst('## ', '');
              } else if (line.startsWith('# ')) {
                detectedStyle = currentLineIdx == 0
                    ? BlockType.title
                    : BlockType.h1;
                line = line.replaceFirst('# ', '');
              }

              final lineIndent = line.substring(
                0,
                line.length - line.trimLeft().length,
              );
              String linePrefix = '';
              if (detectedStyle == BlockType.bullet) {
                linePrefix =
                    '$lineIndent${RichTextEditingController.getBulletForIndent(lineIndent.length)} ';
                line = line.trimLeft();
                detectedStyle = BlockType.paragraph;
              } else if (detectedStyle == BlockType.numbered) {
                // A number already in the text stays there, and so does the line type.
                if (!RegExp(r'^\s*\d+\.').hasMatch(line)) {
                  linePrefix = '${lineIndent}1. ';
                  line = line.trimLeft();
                  detectedStyle = BlockType.paragraph;
                }
              } else if (detectedStyle == BlockType.checklist) {
                linePrefix = b.isChecked ? '● ' : '○ ';
                detectedStyle = BlockType.paragraph;
              } else if (detectedStyle == BlockType.quote) {
                // A quote sign already in the text stays there, indent included.
                if (!RegExp(r'^\s*> ').hasMatch(line)) {
                  linePrefix = '$lineIndent> ';
                  line = line.trimLeft();
                  detectedStyle = BlockType.paragraph;
                }
              } else if (detectedStyle == BlockType.code) {
                // A fence already in the text stays there, indent included.
                if (!RegExp(r'^\s*```').hasMatch(line)) {
                  linePrefix = '$lineIndent``` ';
                  line = line.trimLeft();
                  detectedStyle = BlockType.paragraph;
                }
              } else if (RegExp(
                r'^(?:[-*•][ \t]*)?\[[ \t]*\](?: |$)',
              ).hasMatch(rawLine.trimLeft())) {
                final indent = rawLine.substring(
                  0,
                  rawLine.length - rawLine.trimLeft().length,
                );
                linePrefix = '$indent○ ';
                line = lineTrimmed.replaceFirst(
                  RegExp(r'^(?:[-*•]\s*)?\[\s*\]\s*'),
                  '',
                );
              } else if (RegExp(
                r'^(?:[-*•][ \t]*)?\[[xX]\](?: |$)',
              ).hasMatch(rawLine.trimLeft())) {
                final indent = rawLine.substring(
                  0,
                  rawLine.length - rawLine.trimLeft().length,
                );
                linePrefix = '$indent● ';
                line = lineTrimmed.replaceFirst(
                  RegExp(r'^(?:[-*•]\s*)?\[[xX]\]\s*'),
                  '',
                );
              } else if (RegExp(r'^[-*] (?![\[○●])').hasMatch(lineTrimmed)) {
                final indent = rawLine.substring(
                  0,
                  rawLine.length - rawLine.trimLeft().length,
                );
                linePrefix =
                    '$indent${RichTextEditingController.getBulletForIndent(indent.length)} ';
                line = lineTrimmed.substring(2);
              }

              outputLineStarts.add(
                currentText.length + (currentLineIdx > 0 ? 1 : 0),
              );
              rawLineStarts.add(rawOffset);
              strippedLengths.add(
                (rawLine.length - line.length).clamp(0, rawLine.length),
              );
              displayPrefixes.add(linePrefix.length);
              final finalLine = '$linePrefix$line';
              currentLineStyles[currentLineIdx] = detectedStyle;
              currentText = currentLineIdx == 0
                  ? finalLine
                  : '$currentText\n$finalLine';
              currentLineIdx++;
              rawOffset +=
                  rawLine.length + (li < rawLinesInBlock.length - 1 ? 1 : 0);
            }

            int mapSourceOffset(int sourceOffset) {
              final clamped = sourceOffset.clamp(0, b.text.length);
              for (var li = 0; li < rawLinesInBlock.length; li++) {
                final sourceStart = rawLineStarts[li];
                final sourceEnd = sourceStart + rawLinesInBlock[li].length;
                if (clamped <= sourceEnd || li == rawLinesInBlock.length - 1) {
                  final withinLine =
                      (clamped - sourceStart - strippedLengths[li]).clamp(
                        0,
                        rawLinesInBlock[li].length - strippedLengths[li],
                      );
                  return outputLineStarts[li] +
                      displayPrefixes[li] +
                      withinLine;
                }
              }
              return currentText.length;
            }

            for (final span in b.spans) {
              currentSpans.add(
                span.copyWith(
                  start: mapSourceOffset(span.start),
                  end: mapSourceOffset(span.end),
                ),
              );
            }
          }
        }
        flushText();

        if (mergedBlocks.isEmpty) {
          mergedBlocks.add(
            NoteBlock(id: _uuid.v4(), type: BlockType.paragraph, text: ''),
          );
        }
        _blocks.addAll(mergedBlocks);
        return;
      } catch (_) {}
    }

    // Fallback: parse plain text / legacy markdown lines
    final rawLines = rawContent.split('\n');
    final mergedBlocks = <NoteBlock>[];
    final currentTextLines = <String>[];
    final fallbackLineStyles = <int, BlockType>{};
    int currentLineIdx = 0;
    // True once a non-blank line that is not only tags has been seen.
    bool hasLeadingContent = false;

    void flushLines() {
      if (currentTextLines.isNotEmpty || mergedBlocks.isEmpty) {
        mergedBlocks.add(
          NoteBlock(
            id: _uuid.v4(),
            type: BlockType.paragraph,
            text: currentTextLines.join('\n'),
            lineStyles: Map.from(fallbackLineStyles),
          ),
        );
        currentTextLines.clear();
        fallbackLineStyles.clear();
        currentLineIdx = 0;
      }
    }

    int i = 0;
    while (i < rawLines.length) {
      final line = rawLines[i];
      final lineTrimmed = line.trim();
      final isFirstContentLine =
          !hasLeadingContent &&
          lineTrimmed.isNotEmpty &&
          !Note.isOnlyTags(lineTrimmed);
      if (lineTrimmed.isNotEmpty && !Note.isOnlyTags(lineTrimmed)) {
        hasLeadingContent = true;
      }
      // First text line: title style, even when it is a list item or a checkbox.
      final firstLineStyle = isFirstContentLine
          ? BlockType.title
          : BlockType.paragraph;

      // Check for Table
      if (lineTrimmed.startsWith('|') && lineTrimmed.endsWith('|')) {
        flushLines();
        final tableRows = <List<String>>[];
        while (i < rawLines.length &&
            rawLines[i].trim().startsWith('|') &&
            rawLines[i].trim().endsWith('|')) {
          final rowLine = rawLines[i].trim();
          if (!RegExp(r'^\|[\s\-:|]+\|$').hasMatch(rowLine)) {
            final rawParts = rowLine.split('|');
            final cells = <String>[];
            final startIdx = (rawParts.isNotEmpty && rawParts.first.isEmpty)
                ? 1
                : 0;
            final endIdx = (rawParts.isNotEmpty && rawParts.last.isEmpty)
                ? rawParts.length - 1
                : rawParts.length;
            for (int c = startIdx; c < endIdx; c++) {
              cells.add(rawParts[c].trim());
            }
            if (cells.isNotEmpty) {
              tableRows.add(cells);
            }
          }
          i++;
        }
        if (tableRows.isNotEmpty) {
          int maxCols = 1;
          for (final row in tableRows) {
            if (row.length > maxCols) maxCols = row.length;
          }
          for (int r = 0; r < tableRows.length; r++) {
            final row = List<String>.from(tableRows[r], growable: true);
            while (row.length < maxCols) {
              row.add('');
            }
            tableRows[r] = row;
          }
          mergedBlocks.add(
            NoteBlock(
              id: _uuid.v4(),
              type: BlockType.table,
              tableData: tableRows,
            ),
          );
        }
        continue;
      }

      if (line.startsWith('### ')) {
        final itemText = lineTrimmed.substring(4).trim();
        fallbackLineStyles[currentLineIdx] = isFirstContentLine
            ? BlockType.title
            : BlockType.h3;
        currentTextLines.add(itemText);
        currentLineIdx++;
      } else if (line.startsWith('## ')) {
        final itemText = lineTrimmed.substring(3).trim();
        fallbackLineStyles[currentLineIdx] = isFirstContentLine
            ? BlockType.title
            : BlockType.h2;
        currentTextLines.add(itemText);
        currentLineIdx++;
      } else if (line.startsWith('# ')) {
        final itemText = lineTrimmed.substring(2).trim();
        fallbackLineStyles[currentLineIdx] = isFirstContentLine
            ? BlockType.title
            : BlockType.h1;
        currentTextLines.add(itemText);
        currentLineIdx++;
      } else if (RegExp(r'^(?:[-*•][ \t]*)?\[[ \t]*\](?: |$)').hasMatch(line.trimLeft()) ||
          lineTrimmed.startsWith('○ ')) {
        final indent = line.substring(0, line.length - lineTrimmed.length);
        final itemText = lineTrimmed.replaceFirst(
          RegExp(r'^(?:[-*•]\s*)?(\[\s*\]|○)\s*'),
          '',
        );
        fallbackLineStyles[currentLineIdx] = firstLineStyle;
        currentTextLines.add(
          isFirstContentLine ? itemText : '$indent○ $itemText',
        );
        currentLineIdx++;
      } else if (RegExp(r'^(?:[-*•][ \t]*)?\[[xX]\](?: |$)').hasMatch(line.trimLeft()) ||
          lineTrimmed.startsWith('● ')) {
        final indent = line.substring(0, line.length - lineTrimmed.length);
        final itemText = lineTrimmed.replaceFirst(
          RegExp(r'^(?:[-*•]\s*)?(\[[xX]\]|●)\s*'),
          '',
        );
        fallbackLineStyles[currentLineIdx] = firstLineStyle;
        currentTextLines.add(
          isFirstContentLine ? itemText : '$indent● $itemText',
        );
        currentLineIdx++;
      } else if (RegExp(r'^[-*] (?![\[○●])').hasMatch(lineTrimmed)) {
        final indent = line.substring(0, line.length - lineTrimmed.length);
        final bulletGlyph = RichTextEditingController.getBulletForIndent(
          indent.length,
        );
        fallbackLineStyles[currentLineIdx] = firstLineStyle;
        currentTextLines.add(
          isFirstContentLine
              ? lineTrimmed.substring(2)
              : '$indent$bulletGlyph ${lineTrimmed.substring(2)}',
        );
        currentLineIdx++;
      } else if (lineTrimmed.startsWith('• ') ||
          lineTrimmed.startsWith('◦ ') ||
          lineTrimmed.startsWith('▪ ')) {
        final indent = line.substring(0, line.length - lineTrimmed.length);
        final bulletGlyph = RichTextEditingController.getBulletForIndent(
          indent.length,
        );
        fallbackLineStyles[currentLineIdx] = firstLineStyle;
        currentTextLines.add(
          isFirstContentLine
              ? lineTrimmed.substring(2)
              : '$indent$bulletGlyph ${lineTrimmed.substring(2)}',
        );
        currentLineIdx++;
      } else {
        if (isFirstContentLine && !lineTrimmed.startsWith('|')) {
          fallbackLineStyles[currentLineIdx] = BlockType.title;
        } else {
          fallbackLineStyles[currentLineIdx] = BlockType.paragraph;
        }
        currentTextLines.add(line);
        currentLineIdx++;
      }
      i++;
    }
    flushLines();

    if (mergedBlocks.isEmpty) {
      mergedBlocks.add(
        NoteBlock(id: _uuid.v4(), type: BlockType.paragraph, text: ''),
      );
    }
    _blocks.addAll(mergedBlocks);
  }

  void _serializeAndSave({bool immediate = true}) {
    if (immediate) {
      _saveDebounceTimer?.cancel();
      _doSerializeAndSave();
      return;
    }
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), _onWaitEnded);
  }

  void _onWaitEnded() {
    if (mounted) {
      _doSerializeAndSave();
      return;
    }
    _exitDelivery?.call();
  }

  void _doSerializeAndSave() {
    context.read<NotesProvider>().updateNoteContent(widget.note.id, _serializeBlocks());
  }

  // Copies what the controllers show into the blocks and returns the stored JSON of the document.
  String _serializeBlocks() {
    for (final b in _blocks) {
      if (b.controller != null) {
        b.text = b.controller!.text;
        b.spans = List.from(b.controller!.spans);
        b.lineStyles = Map.from(b.controller!.lineStyles);
      }
    }
    final blockList = _blocks.map((b) => b.toJson()).toList();
    final jsonString = jsonEncode(blockList);
    _lastSerializedContent = jsonString;
    return jsonString;
  }

  // --- External Toolbar Actions ---

  /// Applies a style to the active text part. The style applies only when the note's text has been shown since the app opened; otherwise the hidden document is just saved.
  void _toggleStyle(void Function(RichTextEditingController ctrl) toggle) {
    final b = _currentActiveBlock;
    if (b != null) {
      if (_textShown && _isTextPart(b)) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _ensureController(b, _getBaseStyleForBlock(b, isDark));
        toggle(b.controller!);
      }
      _serializeAndSave(immediate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          b.focusNode?.requestFocus();
        }
      });
    }
  }

  /// Toggles bold formatting in the currently active block
  void toggleBold() => _toggleStyle((c) => c.toggleBold());

  /// Toggles italic formatting in the currently active block
  void toggleItalic() => _toggleStyle((c) => c.toggleItalic());

  /// Toggles underline formatting in the currently active block
  void toggleUnderline() => _toggleStyle((c) => c.toggleUnderline());

  /// Toggles strikethrough formatting in the currently active block
  void toggleStrikethrough() {
    final b = _currentActiveBlock;
    if (b != null) {
      b.controller?.toggleStrikethrough();
      _serializeAndSave(immediate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          b.focusNode?.requestFocus();
        }
      });
    }
  }

  /// Opens the Block menu under the text section that has the focus, or else the last one used,
  /// and focuses it: the keyboard shows and the menu closes when the focus leaves that section.
  void openBlockMenu() => _openBlockMenu(scrolled: false);

  void _openBlockMenu({required bool scrolled}) {
    // A protected note shows only the placeholder: the Block menu stays closed until it is unlocked.
    final security = context.read<SecurityService>();
    if (widget.note.isLocked && !security.isNoteUnlocked(widget.note.id)) return;
    final block = _blockMenuTarget;
    if (block == null) return;
    if (block.focusNode == null) {
      // The list builds a section, and so its focus node, only when it is on screen. The fallback
      // target is the last text section, so scroll to the end and open the menu once it is built.
      // ponytail: assumes an unbuilt target is the last text section; an index-based scroll would cover any.
      if (scrolled || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openBlockMenu(scrolled: true);
      });
      return;
    }
    setState(() {
      _tagAutocompleteBlockIndex = null;
      _tagAutocompleteQuery = null;
      _slashMenuBlock = block;
    });
    block.focusNode!.requestFocus();
  }

  /// Sets the style of the active text section (Aa popup menu). The section
  /// stays a paragraph: the style goes to its active line, as in the open note.
  void setBlockType(BlockType newType) {
    final block = _currentActiveBlock;
    if (block == null) return;
    if (block.type == BlockType.table ||
        block.type == BlockType.image ||
        block.type == BlockType.divider) {
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    _ensureController(block, _getBaseStyleForBlock(block, isDark));
    final ctrl = block.controller!;
    final sel = ctrl.selection;
    final startOffset = sel.isValid ? sel.start : ctrl.text.length;
    final endOffset = sel.isValid ? sel.end : startOffset;
    final startLine = ctrl.getLineIndexAtOffset(startOffset);
    final endLine = ctrl.getLineIndexAtOffset(endOffset);

    // 1. Remove existing heading / markdown / list prefixes from target lines
    ctrl.removeLinePrefixes(startLine, endLine);

    // 2. Apply line style
    if (newType == BlockType.title ||
        newType == BlockType.h1 ||
        newType == BlockType.h2 ||
        newType == BlockType.h3 ||
        newType == BlockType.paragraph) {
      for (int l = startLine; l <= endLine; l++) {
        ctrl.setLineStyle(l, newType);
      }
    } else {
      for (int l = startLine; l <= endLine; l++) {
        ctrl.setLineStyle(l, BlockType.paragraph);
      }
      String prefix = '';
      switch (newType) {
        case BlockType.bullet:
          prefix = '• ';
          break;
        case BlockType.checklist:
          prefix = '○ ';
          break;
        case BlockType.numbered:
          prefix = '1. ';
          break;
        case BlockType.quote:
          prefix = '> ';
          break;
        case BlockType.code:
          prefix = '``` ';
          break;
        default:
          prefix = '';
          break;
      }
      if (prefix.isNotEmpty) {
        ctrl.applyLinePrefix(
          prefix,
          bulletByIndent: newType == BlockType.bullet,
        );
      }
    }

    _serializeAndSave(immediate: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        block.focusNode?.requestFocus();
      }
    });
  }

  /// Creates the text controller of a block on first use. Also used by
  /// setBlockType for a note whose editor was never built.
  void _ensureController(NoteBlock block, TextStyle baseStyle) {
    if (block.controller == null) {
      final initialLineStyles = Map<int, BlockType>.from(block.lineStyles);
      if (initialLineStyles.isEmpty &&
          (block.type == BlockType.title ||
              block.type == BlockType.h1 ||
              block.type == BlockType.h2 ||
              block.type == BlockType.h3)) {
        initialLineStyles[0] = block.type;
      }
      block.controller = RichTextEditingController(
        text: block.text,
        baseStyle: baseStyle,
        spans: List.from(block.spans),
        lineStyles: initialLineStyles,
      );
    } else {
      block.controller!.baseStyle = baseStyle;
      if (block.controller!.lineStyles.isEmpty &&
          (block.type == BlockType.title ||
              block.type == BlockType.h1 ||
              block.type == BlockType.h2 ||
              block.type == BlockType.h3)) {
        block.controller!.lineStyles[0] = block.type;
      }
    }
  }

  /// Toggles checklist on the cursor line of the active text part, or creates an empty one after the active non-text part. When the note's text has never been shown since the app opened, the empty one goes at the end of the document.
  void insertChecklist() {
    final block = _currentActiveBlock;
    if (block != null && _textShown && _isTextPart(block)) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _ensureController(block, _getBaseStyleForBlock(block, isDark));
      block.controller!.toggleChecklistAtCursor();
      _serializeAndSave(immediate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          block.focusNode?.requestFocus();
        }
      });
      return;
    }

    final newBlock = NoteBlock(
      id: _uuid.v4(),
      type: BlockType.paragraph,
      text: '○ ',
      isChecked: false,
    );
    final idx = _textShown ? _activeBlockPos : -1;
    setState(() {
      if (idx >= 0) {
        _blocks.insert(idx + 1, newBlock);
      } else {
        _blocks.add(newBlock);
      }
      _activeBlock = newBlock;
    });
    _serializeAndSave(immediate: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newBlock.focusNode?.requestFocus();
    });
  }

  /// Cycles heading level of currently active block
  void insertHeading() {
    final block = _currentActiveBlock;
    if (block != null && block.controller != null) {
      final ctrl = block.controller!;
      final sel = ctrl.selection;
      final offset = sel.isValid ? sel.start : ctrl.text.length;
      final lineIdx = ctrl.getLineIndexAtOffset(offset);
      final currentStyle = ctrl.getLineStyle(lineIdx);

      BlockType nextType;
      switch (currentStyle) {
        case BlockType.title:
          nextType = BlockType.h1;
          break;
        case BlockType.h1:
          nextType = BlockType.h2;
          break;
        case BlockType.h2:
          nextType = BlockType.h3;
          break;
        case BlockType.h3:
          nextType = BlockType.paragraph;
          break;
        case BlockType.paragraph:
        default:
          nextType = BlockType.h1;
          break;
      }
      setBlockType(nextType);
    }
  }

  /// Indents current line / selection (like pressing Tab on bullet/checklist)
  void indent() {
    final block = _currentActiveBlock;
    if (block?.controller != null) {
      final textBefore = block!.controller?.text;
      block.controller!.handleTabKey(outdent: false);
      _refreshSuggestionsAfterTab(block, _blocks.indexOf(block), textBefore);
      _serializeAndSave(immediate: false);
    }
  }

  /// Outdents current line / selection (like pressing Shift+Tab on bullet/checklist)
  void outdent() {
    final block = _currentActiveBlock;
    if (block?.controller != null) {
      final textBefore = block!.controller?.text;
      block.controller!.handleTabKey(outdent: true);
      _refreshSuggestionsAfterTab(block, _blocks.indexOf(block), textBefore);
      _serializeAndSave(immediate: false);
    }
  }

  /// Inserts an interactive table block
  void insertTable([int? atIndex]) {
    final newBlock = NoteBlock(
      id: _uuid.v4(),
      type: BlockType.table,
      tableData: [
        ['Colonna 1', 'Colonna 2'],
        ['Elemento 1', 'Elemento 2'],
      ],
    );

    final int insertPos;
    if (atIndex != null) {
      insertPos = atIndex.clamp(0, _blocks.length);
    } else {
      final idx = _activeBlockPos;
      insertPos = idx >= 0 ? idx + 1 : _blocks.length;
    }

    setState(() {
      _blocks.insert(insertPos, newBlock);
      // Ensure there's an editable text part after the table
      if (insertPos + 1 >= _blocks.length ||
          !_isTextPart(_blocks[insertPos + 1])) {
        _blocks.insert(
          insertPos + 1,
          NoteBlock(id: _uuid.v4(), type: BlockType.paragraph, text: ''),
        );
      }
      _activeBlock = newBlock;
    });
    _serializeAndSave();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.offset + 140,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Captures where an image pasted now goes: the text part [block] with its
  /// text and selection, so the point can follow edits made while the image is
  /// saved, plus the services the paste needs after the editor may be gone.
  _ImagePaste _startImagePaste(NoteBlock block) {
    final controller = block.controller;
    final text = controller?.text ?? block.text;
    final selection = controller?.selection;
    final valid = selection != null && selection.isValid;
    return _ImagePaste(
      vault: context.read<VaultService>(),
      messenger: ScaffoldMessenger.of(context),
      noteId: widget.note.id,
      block: block,
      text: text,
      start: valid ? selection.start : text.length,
      end: valid ? selection.end : text.length,
    );
  }

  /// Saves the clipboard image and places it at the point captured by [paste].
  /// Shows a notice when the image cannot be saved or its note is no longer open.
  Future<void> _pasteClipboardImage(
    _ImagePaste paste,
    ClipboardImage clipboard,
  ) async {
    final bytes = clipboard.bytes;
    String? relativePath;
    try {
      final prepared = await Isolate.run(() => prepareImageForNote(bytes));
      if (prepared != null) {
        relativePath = await paste.vault.saveAttachment(
          prepared.bytes,
          prepared.extension,
        );
      }
    } catch (_) {
      relativePath = null;
    }
    if (relativePath == null || !mounted || widget.note.id != paste.noteId) {
      paste.messenger.showSnackBar(
        const SnackBar(content: Text('Immagine non incollata')),
      );
      return;
    }
    if (_blocks.contains(paste.block)) {
      _insertPastedImage(paste, relativePath);
    } else {
      insertImage(relativePath);
    }
  }

  /// Divides the text part of [paste] at its point and puts the image between
  /// the two parts. Both parts are kept, even when empty.
  void _insertPastedImage(_ImagePaste paste, String relativePath) {
    final block = paste.block;
    final controller = block.controller;
    final currentText = controller?.text ?? block.text;
    final split = splitTextPartForImage(
      text: currentText,
      spans: controller?.spans ?? block.spans,
      lineStyles: controller?.lineStyles ?? block.lineStyles,
      start: mapOffsetThroughEdit(paste.text, currentText, paste.start),
      end: mapOffsetThroughEdit(paste.text, currentText, paste.end),
    );
    final imageBlock = NoteBlock(
      id: _uuid.v4(),
      type: BlockType.image,
      text: relativePath,
    );
    final afterBlock = NoteBlock(
      id: _uuid.v4(),
      type: BlockType.paragraph,
      text: split.after,
      spans: split.afterSpans,
      lineStyles: split.afterLineStyles,
    );
    _setTextPart(
      block,
      split.before,
      split.beforeSpans,
      split.beforeLineStyles,
    );
    final index = _blocks.indexOf(block);
    setState(() {
      _blocks.insert(index + 1, imageBlock);
      _blocks.insert(index + 2, afterBlock);
      _activeBlock = afterBlock;
    });
    _serializeAndSave();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      afterBlock.focusNode?.requestFocus();
      afterBlock.controller?.selection = const TextSelection.collapsed(
        offset: 0,
      );
    });
  }

  /// Replaces the text, spans and line styles of the text part [block], keeping
  /// its controller in step with the stored fields.
  void _setTextPart(
    NoteBlock block,
    String text,
    List<StyleSpan> spans,
    Map<int, BlockType> lineStyles,
  ) {
    block.text = text;
    block.spans = spans;
    block.lineStyles = lineStyles;
    final controller = block.controller;
    if (controller != null) {
      controller.spans = List.of(spans);
      controller.lineStyles = Map.of(lineStyles);
      controller.replaceTextWithoutReconciliation(text);
      controller.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  /// Ctrl/Cmd+V in a text part: pastes the clipboard image only when the
  /// clipboard holds no text, since the field itself pastes text.
  Future<void> _pasteImageIfNoText(NoteBlock block) async {
    final paste = _startImagePaste(block);
    final text = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || (text?.text ?? '').isNotEmpty) return;
    final image = await readPastedImage();
    if (image != null) {
      await _pasteClipboardImage(paste, image);
    }
  }

  /// Inserts an image block
  void insertImage(String relativePath) {
    final newBlock = NoteBlock(
      id: _uuid.v4(),
      type: BlockType.image,
      text: relativePath,
    );
    final nextParagraph = NoteBlock(
      id: _uuid.v4(),
      type: BlockType.paragraph,
      text: '',
    );

    final idx = _activeBlockPos;
    setState(() {
      _blocks.insert(idx + 1, newBlock);
      _blocks.insert(idx + 2, nextParagraph);
      _activeBlock = nextParagraph;
    });
    _serializeAndSave();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nextParagraph.focusNode?.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat("d MMMM yyyy 'alle ore' HH:mm", 'it_IT');

    // Locked Note View
    if (widget.note.isLocked && !security.isNoteUnlocked(widget.note.id)) {
      return _buildLockedPlaceholder(context, security, isDark);
    }

    return Container(
      color: isDark ? AppleTheme.darkEditor : AppleTheme.lightEditor,
      child: Stack(
        children: [
          Column(
            children: [
              // Header Date (Apple Notes native top date)
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Text(
                  dateFormat.format(widget.note.updatedAt),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppleTheme.darkTextSecondary.withOpacity(0.75)
                        : AppleTheme.lightTextSecondary,
                  ),
                ),
              ),

              // Active Note Tags (Apple Notes chips)
              if (widget.note.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: widget.note.tags.map((tag) {
                      final chipColor = isDark
                          ? AppleTheme.accentYellow
                          : AppleTheme.accentAmberLight;
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        minSize: 22,
                        color: chipColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          context.read<NotesProvider>().selectTag(tag);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.number,
                              size: 11,
                              color: chipColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: chipColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Document Body
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Clicking blank canvas focuses the last part when it is an empty text section, or appends a new one
                    if (_blocks.isNotEmpty) {
                      final last = _blocks.last;
                      if (_isTextPart(last) && last.text.isEmpty) {
                        last.focusNode?.requestFocus();
                      } else {
                        final newBlock = NoteBlock(
                          id: _uuid.v4(),
                          type: BlockType.paragraph,
                          text: '',
                        );
                        setState(() {
                          _blocks.add(newBlock);
                        });
                        _serializeAndSave();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          newBlock.focusNode?.requestFocus();
                        });
                      }
                    }
                  },
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, editorConstraints) {
                        final isCompact = editorConstraints.maxWidth < 600;
                        final horizontalPadding = isCompact ? 18.0 : 44.0;
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 780),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              8,
                              horizontalPadding,
                              140,
                            ),
                            itemCount: _blocks.length,
                            findChildIndexCallback: (Key key) {
                              final valueKey = key as ValueKey<String>?;
                              if (valueKey == null) return null;
                              final id = valueKey.value;
                              final idx = _blocks.indexWhere((b) => b.id == id);
                              return idx != -1 ? idx : null;
                            },
                            itemBuilder: (context, index) {
                              final block = _blocks[index];
                              return KeyedSubtree(
                                key: ValueKey(block.id),
                                child: _buildBlockWidget(block, index, isDark),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_tagAutocompleteBlockIndex != null &&
              _tagAutocompleteQuery != null)
            _buildFloatingTagMenu(isDark),
        ],
      ),
    );
  }

  Widget _buildBlockWidget(NoteBlock block, int index, bool isDark) {
    if (block.type == BlockType.divider) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(
          color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
          thickness: 1.2,
        ),
      );
    }

    if (block.type == BlockType.table) {
      return InteractiveTableBlock(
        key: ValueKey('${block.id}#$_documentLoads'),
        block: block,
        isDark: isDark,
        onChanged: () => _serializeAndSave(immediate: true),
        onArrowOut: (up) => _focusPartAcross(_blocks.indexOf(block), up: up),
        onFocused: () {
          _activeBlock = block;
        },
      );
    }

    if (block.type == BlockType.image) {
      return _buildImageBlock(block, index, isDark);
    }

    final baseStyle = _getBaseStyleForBlock(block, isDark);

    if (block.focusNode == null) {
      block.focusNode = FocusNode(
        debugLabel: 'block_${block.id}',
        onKeyEvent: (node, event) => _handleKeyEvent(event, index, block),
      );
      block.focusNode!.addListener(() {
        if (block.focusNode!.hasFocus) {
          _activeBlock = block;
          _lastTextBlock = block;
        } else {
          final blockIndex = _blocks.indexOf(block);
          if (_tagAutocompleteBlockIndex == blockIndex ||
              identical(_slashMenuBlock, block)) {
            setState(() {
              if (_tagAutocompleteBlockIndex == blockIndex) {
                _tagAutocompleteBlockIndex = null;
                _tagAutocompleteQuery = null;
              }
              if (identical(_slashMenuBlock, block)) {
                _slashMenuBlock = null;
              }
            });
          }
        }
      });
    } else {
      block.focusNode!.onKeyEvent = (node, event) =>
          _handleKeyEvent(event, index, block);
    }

    _ensureController(block, baseStyle);
    _noteIdsWithShownText.add(widget.note.id);

    final Widget inputWidget = TextField(
      key: ValueKey('tf_${block.id}'),
      controller: block.controller,
      focusNode: block.focusNode,
      contextMenuBuilder: (context, editableTextState) => TextPartContextMenu(
        editableTextState: editableTextState,
        onPasteImage: (image) =>
            _pasteClipboardImage(_startImagePaste(block), image),
      ),
      maxLines: null,
      cursorColor: AppleTheme.accentYellow,
      cursorWidth: 2.0,
      style: baseStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: block.type == BlockType.title ? 6 : 3,
        ),
        hintText: block.type == BlockType.title
            ? 'Titolo'
            : (index == 1 && _blocks.length <= 2 ? 'Inizia a scrivere...' : ''),
        hintStyle: TextStyle(
          color: isDark
              ? AppleTheme.darkTextSecondary.withOpacity(0.35)
              : AppleTheme.lightTextSecondary.withOpacity(0.35),
          fontWeight: block.type == BlockType.title
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
      onTap: () {
        final ctrl = block.controller;
        if (ctrl != null) {
          final sel = ctrl.selection;
          if (sel.isValid) {
            final toggled = ctrl.toggleChecklistAtOffset(sel.baseOffset);
            if (toggled) {
              _serializeAndSave(immediate: true);
            }
          }
        }
      },
      onChanged: (val) => _handleTextChanged(val, block, index),
    );

    final prefix = _buildBlockPrefix(block, index, isDark);
    final Widget contentWidget;
    if (block.type == BlockType.checklist) {
      contentWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          prefix,
          Expanded(child: inputWidget),
        ],
      );
    } else {
      contentWidget = inputWidget;
    }

    final Widget blockBody;
    if (identical(_slashMenuBlock, block)) {
      blockBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          contentWidget,
          TextFieldTapRegion(child: _buildSlashMenu(block, index, isDark)),
        ],
      );
    } else {
      blockBody = contentWidget;
    }

    return Container(
      key: block.widgetKey,
      margin: _getBlockMargin(block),
      padding: _getBlockPadding(block),
      decoration: _getBlockDecoration(block, isDark),
      child: blockBody,
    );
  }

  EdgeInsets _getBlockMargin(NoteBlock block) {
    switch (block.type) {
      case BlockType.title:
        return const EdgeInsets.only(bottom: 8);
      case BlockType.checklist:
        return const EdgeInsets.symmetric(vertical: 2.5);
      case BlockType.bullet:
      case BlockType.numbered:
        return const EdgeInsets.symmetric(vertical: 2);
      case BlockType.code:
        return const EdgeInsets.symmetric(vertical: 4);
      case BlockType.quote:
        return const EdgeInsets.symmetric(vertical: 3.5);
      case BlockType.h1:
      case BlockType.h2:
      case BlockType.h3:
      case BlockType.paragraph:
      default:
        return const EdgeInsets.symmetric(vertical: 1.5);
    }
  }

  EdgeInsets _getBlockPadding(NoteBlock block) {
    switch (block.type) {
      case BlockType.code:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      default:
        return EdgeInsets.zero;
    }
  }

  BoxDecoration? _getBlockDecoration(NoteBlock block, bool isDark) {
    if (block.type == BlockType.code) {
      return BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
          width: 0.8,
        ),
      );
    }
    return null;
  }

  Widget _buildBlockPrefix(NoteBlock block, int index, bool isDark) {
    switch (block.type) {
      case BlockType.checklist:
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                block.isChecked = !block.isChecked;
              });
              _serializeAndSave(immediate: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: 19.5,
              height: 19.5,
              margin: const EdgeInsets.only(top: 3.5, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: block.isChecked
                    ? AppleTheme.accentYellow
                    : Colors.transparent,
                border: Border.all(
                  color: block.isChecked
                      ? AppleTheme.accentYellow
                      : (isDark
                            ? AppleTheme.darkTextSecondary.withOpacity(0.5)
                            : AppleTheme.checkboxBorder),
                  width: 1.8,
                ),
              ),
              child: block.isChecked
                  ? const Icon(Icons.check, size: 12.5, color: Colors.white)
                  : null,
            ),
          ),
        );

      case BlockType.bullet:
        return Container(
          width: 5.5,
          height: 5.5,
          margin: const EdgeInsets.only(top: 9, right: 12, left: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        );

      case BlockType.numbered:
        int num = 1;
        for (int i = index - 1; i >= 0; i--) {
          if (_blocks[i].type == BlockType.numbered) {
            num++;
          } else {
            break;
          }
        }
        return SizedBox(
          width: 22,
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '$num.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppleTheme.darkTextSecondary
                    : AppleTheme.lightTextSecondary,
              ),
            ),
          ),
        );

      case BlockType.quote:
        return Container(
          width: 3.5,
          height: 20,
          margin: const EdgeInsets.only(top: 3, right: 10, left: 2),
          decoration: BoxDecoration(
            color: AppleTheme.accentYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageBlock(NoteBlock block, int index, bool isDark) {
    final vault = context.read<VaultService>();
    File file;
    if (block.text.startsWith('attachments/')) {
      file = vault.resolveAttachment(block.text);
    } else {
      file = File(block.text);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.contain)
                : Container(
                    height: 120,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(child: Text('Immagine non trovata')),
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  CupertinoIcons.trash,
                  color: Colors.white,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Rimuovi immagine',
                onPressed: () {
                  setState(() {
                    _removeBlockAt(index);
                  });
                  _serializeAndSave();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Menu for inserting blocks
  Widget _buildSlashMenu(NoteBlock block, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppleTheme.darkCard : AppleTheme.lightCard,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
          width: 0.8,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _slashMenuItem(
              icon: CupertinoIcons.checkmark_circle,
              label: 'Checklist',
              onTap: () => _transformBlock(block, BlockType.checklist, ''),
              isDark: isDark,
            ),
            _slashMenuItem(
              icon: CupertinoIcons.textformat_size,
              label: 'Intestazione',
              onTap: () => _transformBlock(block, BlockType.h1, ''),
              isDark: isDark,
            ),
            _slashMenuItem(
              icon: CupertinoIcons.textformat,
              label: 'Sottointestazione',
              onTap: () => _transformBlock(block, BlockType.h2, ''),
              isDark: isDark,
            ),
            _slashMenuItem(
              icon: CupertinoIcons.list_bullet,
              label: 'Elenco',
              onTap: () => _transformBlock(block, BlockType.bullet, ''),
              isDark: isDark,
            ),
            _slashMenuItem(
              icon: CupertinoIcons.list_number,
              label: 'Numerato',
              onTap: () => _transformBlock(block, BlockType.numbered, ''),
              isDark: isDark,
            ),
            _slashMenuItem(
              icon: CupertinoIcons.quote_bubble,
              label: 'Citazione',
              onTap: () => _transformBlock(block, BlockType.quote, ''),
              isDark: isDark,
            ),
            _slashMenuItem(
              icon: CupertinoIcons.table,
              label: 'Tabella',
              onTap: () {
                _removeSlashCommand(block);
                setState(() {
                  _slashMenuBlock = null;
                });
                insertTable(index + 1);
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _slashMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      minSize: 32,
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppleTheme.accentYellow),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppleTheme.darkTextPrimary
                  : AppleTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _getBaseStyleForBlock(NoteBlock block, bool isDark) {
    final primaryColor = isDark
        ? AppleTheme.darkTextPrimary
        : AppleTheme.lightTextPrimary;

    switch (block.type) {
      case BlockType.title:
        return TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: primaryColor,
        );
      case BlockType.h1:
        return TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: primaryColor,
        );
      case BlockType.h2:
        return TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: primaryColor,
        );
      case BlockType.h3:
        return TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: primaryColor,
        );
      case BlockType.code:
        return TextStyle(
          fontFamily: 'monospace',
          fontSize: 13.5,
          height: 1.45,
          color: primaryColor,
        );
      case BlockType.quote:
        return TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          height: 1.55,
          color: isDark
              ? AppleTheme.darkTextSecondary
              : AppleTheme.lightTextSecondary,
        );
      case BlockType.checklist:
        return TextStyle(
          fontSize: 15,
          height: 1.45,
          letterSpacing: -0.2,
          color: block.isChecked
              ? (isDark
                    ? AppleTheme.darkTextSecondary.withOpacity(0.55)
                    : AppleTheme.lightTextSecondary.withOpacity(0.55))
              : primaryColor,
          decoration: block.isChecked ? TextDecoration.lineThrough : null,
        );
      case BlockType.bullet:
      case BlockType.numbered:
      case BlockType.paragraph:
      default:
        return TextStyle(
          fontSize: 15,
          height: 1.55,
          letterSpacing: -0.2,
          color: primaryColor,
        );
    }
  }

  void _handleTextChanged(String val, NoteBlock block, int index) {
    block.text = val;
    _refreshSuggestions(val, block, index);
    _serializeAndSave(immediate: false);
  }

  /// Edits made by keys the controller handles itself (Enter, Tab, Backspace on lists and checklists)
  /// do not reach [_handleTextChanged]: the menus follow the text they leave behind, as after typing.
  void _refreshSuggestionsAfterKeyEdit(NoteBlock block, int index) {
    final val = block.controller?.text ?? block.text;
    block.text = val;
    _refreshSuggestions(val, block, index);
  }

  /// Tab and Shift+Tab refresh the menus only when they change the text of the section;
  /// a key that leaves the text as it is keeps the menus and the tag suggestions as they are.
  void _refreshSuggestionsAfterTab(
    NoteBlock block,
    int index,
    String? textBefore,
  ) {
    if (block.controller?.text == textBefore) return;
    _refreshSuggestionsAfterKeyEdit(block, index);
  }

  void _refreshSuggestions(String val, NoteBlock block, int index) {
    final sel = block.controller?.selection;
    final pos = (sel != null && sel.isValid) ? sel.start : val.length;
    final textBeforeCaret = val.substring(0, math.min(pos, val.length));
    final tagMatch = RegExp(
      r'(?:^|\s)#(' + Note.tagNameChar + r'*)$',
      unicode: true,
    ).firstMatch(textBeforeCaret);

    if (tagMatch != null) {
      final query = tagMatch.group(1) ?? '';
      setState(() {
        _tagAutocompleteBlockIndex = index;
        _tagAutocompleteQuery = query;
        _slashMenuBlock = null;
      });
    } else {
      if (_tagAutocompleteBlockIndex == index) {
        setState(() {
          _tagAutocompleteBlockIndex = null;
          _tagAutocompleteQuery = null;
        });
      }

      if (val.startsWith('/')) {
        setState(() {
          _slashMenuBlock = block;
        });
      } else if (identical(_slashMenuBlock, block)) {
        setState(() {
          _slashMenuBlock = null;
        });
      }
    }
  }

  void _selectAutocompleteTag(NoteBlock block, int index, String tagName) {
    final cleanTagName = tagName.replaceAll('#', '').trim();
    final val = block.text;
    final sel = block.controller?.selection;
    final pos = (sel != null && sel.isValid) ? sel.start : val.length;
    final textBeforeCaret = val.substring(0, math.min(pos, val.length));
    final textAfterCaret = val.substring(math.min(pos, val.length));
    final hashIndex = textBeforeCaret.lastIndexOf('#');

    if (hashIndex != -1) {
      final prefix = textBeforeCaret.substring(0, hashIndex);
      final newText = '$prefix#$cleanTagName $textAfterCaret';
      final newCaret = '$prefix#$cleanTagName '.length;

      setState(() {
        block.text = newText;
        block.controller?.text = newText;
        block.controller?.selection = TextSelection.collapsed(offset: newCaret);
        _tagAutocompleteBlockIndex = null;
        _tagAutocompleteQuery = null;
      });
      _serializeAndSave(immediate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          block.focusNode?.requestFocus();
          block.controller?.selection = TextSelection.collapsed(
            offset: newCaret,
          );
        }
      });
    }
  }

  Widget _buildFloatingTagMenu(bool isDark) {
    if (_tagAutocompleteBlockIndex == null ||
        _tagAutocompleteBlockIndex! < 0 ||
        _tagAutocompleteBlockIndex! >= _blocks.length) {
      return const SizedBox.shrink();
    }
    final block = _blocks[_tagAutocompleteBlockIndex!];
    final blockContext = block.widgetKey.currentContext;
    if (blockContext == null) return const SizedBox.shrink();

    final blockBox = blockContext.findRenderObject() as RenderBox?;
    final editorBox = context.findRenderObject() as RenderBox?;
    if (blockBox == null ||
        editorBox == null ||
        !blockBox.hasSize ||
        !editorBox.hasSize) {
      return const SizedBox.shrink();
    }

    final baseStyle = _getBaseStyleForBlock(block, isDark);
    final text = block.controller?.text ?? block.text;
    final sel = block.controller?.selection;
    final pos = (sel != null && sel.isValid) ? sel.start : text.length;
    final textBeforeCaret = text.substring(0, math.min(pos, text.length));

    final double prefixIndent = block.type == BlockType.checklist ? 28.0 : 0.0;
    final availableWidth = math.max(100.0, blockBox.size.width - prefixIndent);

    final textPainter = TextPainter(
      text: TextSpan(text: textBeforeCaret, style: baseStyle),
      textDirection: ui.TextDirection.ltr,
      maxLines: null,
    );
    textPainter.layout(maxWidth: availableWidth);
    final caretOffsetInBlock = textPainter.getOffsetForCaret(
      TextPosition(offset: textBeforeCaret.length),
      Rect.zero,
    );

    final globalCaret = blockBox.localToGlobal(
      Offset(caretOffsetInBlock.dx + prefixIndent, caretOffsetInBlock.dy),
    );
    final editorCaret = editorBox.globalToLocal(globalCaret);

    final double lineHeight =
        (baseStyle.fontSize ?? 15.0) * (baseStyle.height ?? 1.55);
    const double menuWidth = 240.0;
    const double maxMenuHeight = 200.0;

    final double left = editorCaret.dx.clamp(
      16.0,
      math.max(16.0, editorBox.size.width - menuWidth - 16.0),
    );
    double top = editorCaret.dy + lineHeight + 4.0;
    if (top + maxMenuHeight > editorBox.size.height - 20) {
      top = math.max(10.0, editorCaret.dy - maxMenuHeight - 4.0);
    }

    final provider = context.read<NotesProvider>();
    final allTags = provider.tags;
    final query = (_tagAutocompleteQuery ?? '').toLowerCase();
    final matchingTags = allTags
        .where((t) => t.name.toLowerCase().contains(query))
        .toList();
    // Nothing to propose and nothing typed after the hash: keep it plain text.
    if (matchingTags.isEmpty && query.isEmpty) {
      return const SizedBox.shrink();
    }
    final chipColor = isDark
        ? AppleTheme.accentYellow
        : AppleTheme.accentAmberLight;

    return Positioned(
      left: left,
      top: top,
      width: menuWidth,
      child: TextFieldTapRegion(
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppleTheme.darkCard : AppleTheme.lightCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? AppleTheme.darkDivider
                    : AppleTheme.lightDivider,
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.number, size: 12, color: chipColor),
                        const SizedBox(width: 5),
                        Text(
                          'TAG SUGGERITI',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: isDark
                                ? AppleTheme.darkTextSecondary
                                : AppleTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.6,
                    color: isDark
                        ? AppleTheme.darkDivider
                        : AppleTheme.lightDivider,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...matchingTags.take(5).map((t) {
                            return CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minSize: 32,
                              borderRadius: BorderRadius.zero,
                              onPressed: () => _selectAutocompleteTag(
                                block,
                                _tagAutocompleteBlockIndex!,
                                t.name,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '#${t.name}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: chipColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${t.count}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppleTheme.darkTextSecondary
                                          : AppleTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (query.isNotEmpty &&
                              !matchingTags.any(
                                (t) => t.name.toLowerCase() == query,
                              ))
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minSize: 32,
                              borderRadius: BorderRadius.zero,
                              onPressed: () => _selectAutocompleteTag(
                                block,
                                _tagAutocompleteBlockIndex!,
                                query,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.add,
                                    size: 13,
                                    color: chipColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Crea #$query',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: chipColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _transformBlock(
    NoteBlock block,
    BlockType newType,
    String cleanText, {
    bool isChecked = false,
  }) {
    if (block.controller != null) {
      _removeSlashCommand(block);
      setState(() {
        _slashMenuBlock = null;
      });
      setBlockType(newType);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    setState(() {
      block.type = newType;
      block.isChecked = isChecked;
      block.text = cleanText;
      block.controller?.text = cleanText;
      block.controller?.baseStyle = _getBaseStyleForBlock(block, isDark);
      if (newType == BlockType.title ||
          newType == BlockType.h1 ||
          newType == BlockType.h2 ||
          newType == BlockType.h3) {
        block.lineStyles[0] = newType;
        block.controller?.lineStyles[0] = newType;
      }
      block.controller?.selection = TextSelection.collapsed(
        offset: cleanText.length,
      );
      _slashMenuBlock = null;
    });
    _serializeAndSave(immediate: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        block.focusNode?.requestFocus();
        block.controller?.selection = TextSelection.collapsed(
          offset: cleanText.length,
        );
      }
    });
  }

  /// Removes the slash command from the caret line: the '/' and the tag-name characters (letters, combining marks, digits, '_' and '-') of any alphabet, then the spaces after it.
  void _removeSlashCommand(NoteBlock block) {
    final ctrl = block.controller;
    if (ctrl == null) return;
    final text = ctrl.text;
    final sel = ctrl.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final lineIdx = ctrl.getLineIndexAtOffset(pos);

    final lines = text.split('\n');
    if (lineIdx < lines.length) {
      var lStr = lines[lineIdx];
      if (lStr.startsWith('/')) {
        lStr = lStr.replaceFirst(
          RegExp('^/' + Note.tagNameChar + r'*\s*', unicode: true),
          '',
        );
      }
      lines[lineIdx] = lStr;
      final lineStart = lines
          .take(lineIdx)
          .fold<int>(0, (n, l) => n + l.length + 1);
      ctrl.text = lines.join('\n');
      // Setting the text drops the selection: put the caret back on this line
      // so the chosen style applies here, not on the last line of the section.
      ctrl.selection = TextSelection.collapsed(offset: lineStart);
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int index, NoteBlock block) {
    if (event is! KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Tag autocomplete keyboard navigation & confirmation
    if (_tagAutocompleteBlockIndex == index && _tagAutocompleteQuery != null) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _tagAutocompleteBlockIndex = null;
          _tagAutocompleteQuery = null;
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.tab ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        final allTags = context.read<NotesProvider>().tags;
        final query = (_tagAutocompleteQuery ?? '').toLowerCase();
        final matchingTags = allTags
            .where((t) => t.name.toLowerCase().contains(query))
            .toList();
        if (matchingTags.isNotEmpty) {
          _selectAutocompleteTag(block, index, matchingTags.first.name);
          return KeyEventResult.handled;
        } else if (query.isNotEmpty) {
          _selectAutocompleteTag(block, index, query);
          return KeyEventResult.handled;
        }
      }
    }

    final isCtrlOrCmd =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    // Standard Rich Text Shortcuts:
    // CTRL+B: Bold
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyB) {
      toggleBold();
      return KeyEventResult.handled;
    }

    // CTRL+I: Italic
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyI) {
      toggleItalic();
      return KeyEventResult.handled;
    }

    // CTRL+U: Underline
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyU) {
      toggleUnderline();
      return KeyEventResult.handled;
    }

    // CTRL+SHIFT+X or CTRL+ALT+S: Strikethrough
    if (isCtrlOrCmd &&
        (HardwareKeyboard.instance.isShiftPressed &&
                event.logicalKey == LogicalKeyboardKey.keyX ||
            event.logicalKey == LogicalKeyboardKey.keyS &&
                HardwareKeyboard.instance.isAltPressed)) {
      toggleStrikethrough();
      return KeyEventResult.handled;
    }

    // CTRL/CMD+V: the field pastes text as usual; an image is pasted only
    // when the clipboard holds no text.
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyV) {
      unawaited(_pasteImageIfNoText(block));
      return KeyEventResult.ignored;
    }

    final ctrl = block.controller;
    final sel = ctrl?.selection ?? const TextSelection.collapsed(offset: -1);

    // TAB and SHIFT+TAB keys (Notion-style indent / outdent)
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final isShift = HardwareKeyboard.instance.isShiftPressed;
      final textBefore = block.controller?.text;
      if (block.controller != null &&
          block.controller!.handleTabKey(outdent: isShift)) {
        _refreshSuggestionsAfterTab(block, index, textBefore);
        _serializeAndSave(immediate: false);
        return KeyEventResult.handled;
      }
    }

    // ENTER key
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      if (block.controller != null && block.controller!.handleEnterKey()) {
        _refreshSuggestionsAfterKeyEdit(block, index);
        _serializeAndSave(immediate: false);
        return KeyEventResult.handled;
      }
    }

    // BACKSPACE key
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (block.controller != null && block.controller!.handleBackspaceKey()) {
        _refreshSuggestionsAfterKeyEdit(block, index);
        _serializeAndSave(immediate: false);
        return KeyEventResult.handled;
      }
      if (sel.isCollapsed && sel.start == 0) {
        final currentText = block.controller?.text ?? block.text;
        if (block.type != BlockType.paragraph &&
            block.type != BlockType.title) {
          if (currentText.isEmpty) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            setState(() {
              block.type = BlockType.paragraph;
              block.lineStyles.clear();
              block.controller?.lineStyles.clear();
              block.controller?.baseStyle = _getBaseStyleForBlock(
                block,
                isDark,
              );
            });
            _serializeAndSave(immediate: true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                block.focusNode?.requestFocus();
                block.controller?.selection = const TextSelection.collapsed(
                  offset: 0,
                );
              }
            });
            return KeyEventResult.handled;
          } else if (index > 0) {
            _mergeBlockWithPrevious(index);
            return KeyEventResult.handled;
          }
        } else if (index > 0) {
          _mergeBlockWithPrevious(index);
          return KeyEventResult.handled;
        }
      }
    }

    // UP ARROW: moves to the end of the previous part
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (sel.isCollapsed &&
          sel.start == 0 &&
          _focusPartAcross(index, up: true)) {
        return KeyEventResult.handled;
      }
    }

    // DOWN ARROW: moves to the start of the next part
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final textLen = ctrl?.text.length ?? 0;
      if (sel.isCollapsed &&
          sel.start == textLen &&
          _focusPartAcross(index, up: false)) {
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// Moves the cursor to the end (up) or start (down) of the part next to [index].
  /// Images and dividers have no caret and are skipped; a table takes the cursor
  /// in its last (up) or first (down) cell. Returns false when there is no such part.
  bool _focusPartAcross(int index, {required bool up}) {
    var i = up ? index - 1 : index + 1;
    while (i >= 0 && i < _blocks.length) {
      final part = _blocks[i];
      if (part.type == BlockType.image || part.type == BlockType.divider) {
        i += up ? -1 : 1;
        continue;
      }
      if (part.type == BlockType.table) {
        final focusCell = part.focusCell;
        if (focusCell == null) return false;
        focusCell(last: up);
        return true;
      }
      part.focusNode?.requestFocus();
      final ctrl = part.controller;
      if (ctrl != null) {
        ctrl.selection = TextSelection.collapsed(
          offset: up ? ctrl.text.length : 0,
        );
      }
      return true;
    }
    return false;
  }

  void _mergeBlockWithPrevious(int index) {
    if (index <= 0 || index >= _blocks.length) return;
    final current = _blocks[index];
    final previous = _blocks[index - 1];

    if (previous.type == BlockType.image ||
        previous.type == BlockType.table ||
        previous.type == BlockType.divider) {
      previous.focusNode?.requestFocus();
      return;
    }

    final prevText = previous.controller?.text ?? previous.text;
    final currText = current.controller?.text ?? current.text;
    final mergedText = '$prevText$currText';

    // Merge style spans
    final prevSpans = previous.controller?.spans ?? previous.spans;
    final currSpans = current.controller?.spans ?? current.spans;
    final offset = prevText.length;
    final shiftedCurrSpans = currSpans
        .map((s) => s.copyWith(start: s.start + offset, end: s.end + offset))
        .toList();

    // Merge line styles with offset
    final prevLineStyles = Map<int, BlockType>.from(
      previous.controller?.lineStyles ?? previous.lineStyles,
    );
    if (prevLineStyles.isEmpty &&
        (previous.type == BlockType.title ||
            previous.type == BlockType.h1 ||
            previous.type == BlockType.h2 ||
            previous.type == BlockType.h3)) {
      prevLineStyles[0] = previous.type;
    }

    final currLineStyles = Map<int, BlockType>.from(
      current.controller?.lineStyles ?? current.lineStyles,
    );
    if (currLineStyles.isEmpty &&
        (current.type == BlockType.title ||
            current.type == BlockType.h1 ||
            current.type == BlockType.h2 ||
            current.type == BlockType.h3)) {
      currLineStyles[0] = current.type;
    }

    final prevLineCount = '\n'.allMatches(prevText).length;
    final mergedLineStyles = Map<int, BlockType>.from(prevLineStyles);
    if (prevText.isNotEmpty && prevText.endsWith('\n')) {
      // The joined line takes the place of the empty last line: its own style
      // wins, and a body line leaves the line body.
      mergedLineStyles.remove(prevLineCount);
    }
    for (final entry in currLineStyles.entries) {
      if (prevText.isNotEmpty && !prevText.endsWith('\n') && entry.key == 0) {
        continue;
      }
      final mergedIndex = prevLineCount + entry.key;
      if (!mergedLineStyles.containsKey(mergedIndex)) {
        mergedLineStyles[mergedIndex] = entry.value;
      }
    }

    if (prevText.isEmpty) {
      previous.type = current.type;
      previous.isChecked = current.isChecked;
      mergedLineStyles.clear();
      mergedLineStyles.addAll(currLineStyles);
    } else if (previous.type == BlockType.title ||
        previous.type == BlockType.h1 ||
        previous.type == BlockType.h2 ||
        previous.type == BlockType.h3) {
      previous.type = BlockType.paragraph;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newBaseStyle = _getBaseStyleForBlock(previous, isDark);

    previous.text = mergedText;
    previous.spans = [
      ...prevSpans.map((s) => s.copyWith()),
      ...shiftedCurrSpans,
    ];
    previous.lineStyles = mergedLineStyles;
    if (previous.controller != null) {
      previous.controller!.baseStyle = newBaseStyle;
      previous.controller!.spans = List.from(previous.spans);
      previous.controller!.lineStyles = Map.from(mergedLineStyles);
      previous.controller!.replaceTextWithoutReconciliation(mergedText);
    }

    setState(() {
      _removeBlockAt(index);
    });
    _serializeAndSave(immediate: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        previous.focusNode?.requestFocus();
        previous.controller?.selection = TextSelection.collapsed(
          offset: prevText.length,
        );
      }
    });
  }

  Widget _buildLockedPlaceholder(
    BuildContext context,
    SecurityService security,
    bool isDark,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppleTheme.accentYellow.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.lock_shield_fill,
              size: 52,
              color: AppleTheme.accentYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Questa nota è protetta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark
                  ? AppleTheme.darkTextPrimary
                  : AppleTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inserisci il PIN per visualizzare o modificare il contenuto.',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark
                  ? AppleTheme.darkTextSecondary
                  : AppleTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 22),
          CupertinoButton(
            color: AppleTheme.accentYellow,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  CupertinoIcons.lock_open_fill,
                  color: CupertinoColors.black,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Visualizza nota',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            onPressed: () async {
              final unlocked = await LockNoteDialog.showUnlockDialog(
                context,
                security,
              );
              if (unlocked) {
                security.unlockNote(widget.note.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Interactive Editable Table Block with persistent cell controllers and focus nodes
class InteractiveTableBlock extends StatefulWidget {
  final NoteBlock block;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onFocused;
  final bool Function(bool up) onArrowOut;

  const InteractiveTableBlock({
    super.key,
    required this.block,
    required this.isDark,
    required this.onChanged,
    required this.onArrowOut,
    required this.onFocused,
  });

  @override
  State<InteractiveTableBlock> createState() => _InteractiveTableBlockState();
}

class _InteractiveTableBlockState extends State<InteractiveTableBlock> {
  final List<List<TextEditingController>> _controllers = [];
  final List<List<FocusNode>> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _syncMatrix();
    widget.block.focusCell = _focusEdgeCell;
    widget.block.cellCaret = _focusedCell;
    widget.block.focusCellAt = _focusCellAt;
  }

  @override
  void didUpdateWidget(covariant InteractiveTableBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rows = widget.block.tableData;
    int maxCols = 0;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }
    if (_controllers.length != rows.length ||
        (_controllers.isNotEmpty && _controllers.first.length != maxCols)) {
      _syncMatrix();
    }
  }

  void _syncMatrix() {
    _disposeMatrix();
    final rows = widget.block.tableData;
    if (rows.isEmpty) return;

    int maxCols = 1;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }
    for (int r = 0; r < rows.length; r++) {
      final row = List<String>.from(rows[r], growable: true);
      while (row.length < maxCols) {
        row.add('');
      }
      rows[r] = row;
    }

    for (int r = 0; r < rows.length; r++) {
      final rowCtrls = <TextEditingController>[];
      final rowNodes = <FocusNode>[];
      for (int c = 0; c < maxCols; c++) {
        final ctrl = TextEditingController(text: rows[r][c]);
        final node = _newCellFocusNode();
        rowCtrls.add(ctrl);
        rowNodes.add(node);
      }
      _controllers.add(rowCtrls);
      _focusNodes.add(rowNodes);
    }
  }

  void _disposeMatrix() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    _controllers.clear();

    for (final row in _focusNodes) {
      for (final n in row) {
        n.dispose();
      }
    }
    _focusNodes.clear();
  }

  @override
  void dispose() {
    _disposeMatrix();
    widget.block.focusCell = null;
    widget.block.cellCaret = null;
    widget.block.focusCellAt = null;
    super.dispose();
  }

  ({int row, int column, int offset})? _focusedCell() {
    for (int r = 0; r < _focusNodes.length; r++) {
      for (int c = 0; c < _focusNodes[r].length; c++) {
        if (!_focusNodes[r][c].hasFocus) continue;
        final ctrl = _controllers[r][c];
        final length = ctrl.text.length;
        final start = ctrl.selection.isValid ? ctrl.selection.start : length;
        return (row: r, column: c, offset: start > length ? length : start);
      }
    }
    return null;
  }

  /// Puts the cursor in a cell, clamped to the table: the nearest row and column that still exist.
  void _focusCellAt(int row, int column, int offset) {
    if (_focusNodes.isEmpty) return;
    final r = row >= _focusNodes.length ? _focusNodes.length - 1 : row;
    final rowNodes = _focusNodes[r];
    final c = column >= rowNodes.length ? rowNodes.length - 1 : column;
    final ctrl = _controllers[r][c];
    final length = ctrl.text.length;
    rowNodes[c].requestFocus();
    ctrl.selection = TextSelection.collapsed(offset: offset > length ? length : offset);
  }

  void _addRow() {
    final rows = widget.block.tableData;
    int colCount = 2;
    if (_controllers.isNotEmpty && _controllers.first.isNotEmpty) {
      colCount = _controllers.first.length;
    } else if (rows.isNotEmpty) {
      for (final r in rows) {
        if (r.length > colCount) colCount = r.length;
      }
    }
    setState(() {
      rows.add(List.filled(colCount, '', growable: true));
      final newCtrls = List.generate(
        colCount,
        (_) => TextEditingController(text: ''),
      );
      final newNodes = List.generate(colCount, (_) => _newCellFocusNode());
      _controllers.add(newCtrls);
      _focusNodes.add(newNodes);
    });
    widget.onChanged();
  }

  void _removeRow(int rIdx) {
    final rows = widget.block.tableData;
    if (rows.length <= 1) return;
    setState(() {
      rows.removeAt(rIdx);
      for (final c in _controllers[rIdx]) {
        c.dispose();
      }
      for (final n in _focusNodes[rIdx]) {
        n.dispose();
      }
      _controllers.removeAt(rIdx);
      _focusNodes.removeAt(rIdx);
    });
    widget.onChanged();
  }

  void _addColumn() {
    final rows = widget.block.tableData;
    setState(() {
      for (int r = 0; r < rows.length; r++) {
        rows[r].add('');
      }
      for (int r = 0; r < _controllers.length; r++) {
        _controllers[r].add(TextEditingController(text: ''));
        _focusNodes[r].add(_newCellFocusNode());
      }
    });
    widget.onChanged();
  }

  void _removeColumn(int cIdx) {
    final rows = widget.block.tableData;
    if (rows.isEmpty || rows.first.length <= 1) return;
    setState(() {
      for (int r = 0; r < rows.length; r++) {
        if (cIdx < rows[r].length) {
          rows[r].removeAt(cIdx);
        }
        if (r < _controllers.length && cIdx < _controllers[r].length) {
          _controllers[r][cIdx].dispose();
          _controllers[r].removeAt(cIdx);
          _focusNodes[r][cIdx].dispose();
          _focusNodes[r].removeAt(cIdx);
        }
      }
    });
    widget.onChanged();
  }

  void _onCellChanged(int r, int c, String val) {
    widget.block.tableData[r][c] = val;
    widget.onChanged();
  }

  FocusNode _newCellFocusNode() {
    final node = FocusNode(
      onKeyEvent: (n, event) => _handleCellKeyEvent(n, event),
    );
    node.addListener(() {
      if (node.hasFocus) widget.onFocused();
    });
    return node;
  }

  void _focusCell(int r, int c, {required bool caretAtEnd}) {
    final ctrl = _controllers[r][c];
    _focusNodes[r][c].requestFocus();
    ctrl.selection = TextSelection.collapsed(
      offset: caretAtEnd ? ctrl.text.length : 0,
    );
  }

  /// Focuses the last (`last: true`) or first cell when the cursor enters the table.
  void _focusEdgeCell({required bool last}) {
    if (_focusNodes.isEmpty) return;
    final r = last ? _focusNodes.length - 1 : 0;
    final c = last ? _focusNodes[r].length - 1 : 0;
    _focusCell(r, c, caretAtEnd: last);
  }

  KeyEventResult _handleCellKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final r = _focusNodes.indexWhere((row) => row.contains(node));
    if (r < 0) return KeyEventResult.ignored;
    final c = _focusNodes[r].indexOf(node);

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final isShift = HardwareKeyboard.instance.isShiftPressed;
      if (isShift) {
        if (c > 0) {
          _focusNodes[r][c - 1].requestFocus();
        } else if (r > 0) {
          _focusNodes[r - 1][_focusNodes[r - 1].length - 1].requestFocus();
        }
      } else {
        if (c + 1 < _focusNodes[r].length) {
          _focusNodes[r][c + 1].requestFocus();
        } else if (r + 1 < _focusNodes.length) {
          _focusNodes[r + 1][0].requestFocus();
        } else {
          _addRow();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (r + 1 < _focusNodes.length && _focusNodes[r + 1].isNotEmpty) {
              _focusNodes[r + 1][0].requestFocus();
            }
          });
        }
      }
      return KeyEventResult.handled;
    }

    // Up/down move between rows of the same column; at the first or last row
    // the cursor leaves the table for the adjacent part.
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
      final target = up ? r - 1 : r + 1;
      if (target >= 0 && target < _focusNodes.length) {
        _focusCell(target, c, caretAtEnd: up);
        return KeyEventResult.handled;
      }
      return widget.onArrowOut(up)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.block.tableData;
    if (rows.isEmpty || _controllers.isEmpty) {
      return const SizedBox.shrink();
    }

    int maxCols = _controllers.first.length;
    for (final c in _controllers) {
      if (c.length > maxCols) maxCols = c.length;
    }
    if (maxCols == 0) return const SizedBox.shrink();

    final isDark = widget.isDark;
    final dividerColor = isDark
        ? AppleTheme.darkDivider
        : AppleTheme.lightDivider;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppleTheme.darkCard : AppleTheme.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: dividerColor, width: 0.8),
              verticalInside: BorderSide(color: dividerColor, width: 0.8),
            ),
            children: List.generate(rows.length, (rIdx) {
              final isHeader = rIdx == 0;

              return TableRow(
                decoration: isHeader
                    ? BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.03),
                      )
                    : null,
                children: List.generate(maxCols, (cIdx) {
                  final ctrl =
                      (rIdx < _controllers.length &&
                          cIdx < _controllers[rIdx].length)
                      ? _controllers[rIdx][cIdx]
                      : null;
                  final node =
                      (rIdx < _focusNodes.length &&
                          cIdx < _focusNodes[rIdx].length)
                      ? _focusNodes[rIdx][cIdx]
                      : null;

                  if (ctrl == null || node == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: TextField(
                      controller: ctrl,
                      focusNode: node,
                      cursorColor: AppleTheme.accentYellow,
                      cursorWidth: 2.0,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isHeader
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isDark
                            ? AppleTheme.darkTextPrimary
                            : AppleTheme.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: isHeader ? 'Colonna ${cIdx + 1}' : '',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color:
                              (isDark
                                      ? AppleTheme.darkTextSecondary
                                      : AppleTheme.lightTextSecondary)
                                  .withOpacity(0.4),
                        ),
                      ),
                      onChanged: (val) => _onCellChanged(rIdx, cIdx, val),
                    ),
                  );
                }),
              );
            }),
          ),
          // Action Bar for Table
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minSize: 28,
                  onPressed: _addRow,
                  child: Text(
                    '+ Riga',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppleTheme.accentYellow
                          : AppleTheme.accentAmberLight,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minSize: 28,
                  onPressed: _addColumn,
                  child: Text(
                    '+ Colonna',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppleTheme.accentYellow
                          : AppleTheme.accentAmberLight,
                    ),
                  ),
                ),
                const Spacer(),
                if (rows.length > 1)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minSize: 28,
                    onPressed: () => _removeRow(rows.length - 1),
                    child: Text(
                      '- Riga',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            (isDark
                                    ? AppleTheme.darkTextSecondary
                                    : AppleTheme.lightTextSecondary)
                                .withOpacity(0.7),
                      ),
                    ),
                  ),
                if (rows.isNotEmpty && rows.first.length > 1)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minSize: 28,
                    onPressed: () => _removeColumn(rows.first.length - 1),
                    child: Text(
                      '- Colonna',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            (isDark
                                    ? AppleTheme.darkTextSecondary
                                    : AppleTheme.lightTextSecondary)
                                .withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The point where a clipboard image is pasted, taken when the paste starts:
/// the text part and its selection, with the services needed once the image is
/// saved.
class _ImagePaste {
  const _ImagePaste({
    required this.vault,
    required this.messenger,
    required this.noteId,
    required this.block,
    required this.text,
    required this.start,
    required this.end,
  });

  final VaultService vault;
  final ScaffoldMessengerState messenger;
  final String noteId;
  final NoteBlock block;
  final String text;
  final int start;
  final int end;
}
