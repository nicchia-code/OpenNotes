import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/note_model.dart';

/// Native WYSIWYG rich text controller like Apple Notes.
/// Preserves clean plain text while rendering live formatting (Bold, Italic, Underline, Strikethrough)
/// without any markdown asterisks or delimiters.
class RichTextEditingController extends TextEditingController {
  TextStyle baseStyle;
  List<StyleSpan> spans;
  Map<int, BlockType> lineStyles;

  // Active styles for the next inserted character when caret is collapsed
  bool activeBold = false;
  bool activeItalic = false;
  bool activeUnderline = false;
  bool activeStrikethrough = false;

  String _previousText = '';

  TextSelection _previousSelection = const TextSelection.collapsed(offset: 0);

  RichTextEditingController({
    super.text,
    required this.baseStyle,
    List<StyleSpan>? spans,
    Map<int, BlockType>? lineStyles,
  }) : spans = spans ?? [],
       lineStyles = lineStyles != null ? Map.from(lineStyles) : {} {
    _previousText = text;
    _previousSelection = selection;
    _cleanInitialMarkdownHeadings();
    _normalizeFormatting();
    addListener(_handleTextChanges);
  }

  void replaceTextWithoutReconciliation(String newText) {
    final nextValue = TextEditingValue(text: newText, selection: selection);
    _previousText = newText;
    _previousSelection = nextValue.selection;
    super.value = nextValue;
  }

  void _cleanInitialMarkdownHeadings() {
    final lines = text.split('\n');
    final cleanedLines = <String>[];

    var offset = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = RegExp(r'^(#{1,3}) ').firstMatch(line);
      if (match == null) {
        cleanedLines.add(line);
      } else {
        final prefixLength = match.group(0)!.length;
        lineStyles[i] = switch (match.group(1)!.length) {
          1 => BlockType.h1,
          2 => BlockType.h2,
          _ => BlockType.h3,
        };
        cleanedLines.add(line.substring(prefixLength));
        _shiftSpansForReplacement(offset, offset + prefixLength, 0);
        offset -= prefixLength;
      }
      offset += line.length + (i < lines.length - 1 ? 1 : 0);
    }

    if (cleanedLines.join('\n') != text) {
      final cleaned = cleanedLines.join('\n');
      spans = spans
          .map(
            (span) => span.copyWith(
              start: span.start.clamp(0, cleaned.length),
              end: span.end.clamp(0, cleaned.length),
            ),
          )
          .where((span) => span.start < span.end && span.hasAnyStyle)
          .toList();
      text = cleaned;
      _previousText = cleaned;
      _previousSelection = selection;
    }
  }

  void _normalizeFormatting() {
    final length = text.length;
    spans = spans
        .map(
          (span) => span.copyWith(
            start: span.start.clamp(0, length),
            end: span.end.clamp(0, length),
          ),
        )
        .where((span) => span.start < span.end && span.hasAnyStyle)
        .toList();
    final lineCount = '\n'.allMatches(text).length + 1;
    lineStyles.removeWhere((line, _) => line < 0 || line >= lineCount);
    _normalizeSpans();
  }

  void _shiftSpansForReplacement(int start, int oldEnd, int newLength) {
    final delta = newLength - (oldEnd - start);
    for (final span in spans) {
      if (span.start >= oldEnd) {
        span.start += delta;
        span.end += delta;
      } else if (span.end > start) {
        span.start = math.min(span.start, start);
        span.end = math.max(start, span.end + delta);
      }
    }
  }

  BlockType getLineStyle(int lineIdx) {
    return lineStyles[lineIdx] ?? BlockType.paragraph;
  }

  void setLineStyle(int lineIdx, BlockType type) {
    lineStyles[lineIdx] = type;
    notifyListeners();
  }

  static int getLineIndexInString(String str, int charOffset) {
    int lineIdx = 0;
    final maxLen = math.min(charOffset, str.length);
    for (int i = 0; i < maxLen; i++) {
      if (str[i] == '\n') lineIdx++;
    }
    return lineIdx;
  }

  int getLineIndexAtOffset(int charOffset) {
    return getLineIndexInString(text, charOffset);
  }

  void _reconcileLineStyles(
    String oldText,
    String newText,
    int start,
    int oldEnd,
    int newEnd,
  ) {
    if (oldText == newText) return;
    final oldStartLine = getLineIndexInString(oldText, start);
    final oldEndLine = getLineIndexInString(oldText, oldEnd);
    final newEndLine = getLineIndexInString(newText, newEnd);
    final lineDelta = newEndLine - oldEndLine;
    final startOfLine = start == 0
        ? 0
        : oldText.lastIndexOf('\n', start - 1) + 1;
    final keepsStartLine = oldText.substring(startOfLine, start).isNotEmpty;
    final updated = <int, BlockType>{};

    for (final entry in lineStyles.entries) {
      if (entry.key < oldStartLine) {
        updated[entry.key] = entry.value;
      } else if (entry.key > oldEndLine) {
        final shifted = entry.key + lineDelta;
        if (shifted >= 0) updated[shifted] = entry.value;
      }
    }

    final insertedText = newText.substring(start, newEnd);
    final newlineCount = '\n'.allMatches(insertedText).length;
    if (!keepsStartLine && oldEnd == start && newlineCount > 0) {
      for (final entry in lineStyles.entries) {
        if (entry.key >= oldStartLine) {
          updated[entry.key + newlineCount] = entry.value;
        }
      }
      for (
        var line = oldStartLine;
        line < oldStartLine + newlineCount;
        line++
      ) {
        updated[line] = BlockType.paragraph;
      }
      lineStyles = updated;
      return;
    }

    final endStyle = lineStyles[oldEndLine];
    final survivingStyle =
        keepsStartLine || endStyle == null || endStyle == BlockType.paragraph
        ? lineStyles[oldStartLine]
        : endStyle;
    if (survivingStyle != null) updated[oldStartLine] = survivingStyle;
    for (var line = oldStartLine + 1; line <= newEndLine; line++) {
      updated[line] = BlockType.paragraph;
    }
    lineStyles = updated;
  }

  void removeLinePrefixes(int startLine, int endLine) {
    final fullText = text;
    final lineStarts = <int>[0];
    for (int i = 0; i < fullText.length; i++) {
      if (fullText[i] == '\n') lineStarts.add(i + 1);
    }
    if (startLine >= lineStarts.length) return;

    final actualEndLine = math.min(endLine, lineStarts.length - 1);
    final prefixRegex = RegExp(
      r'^(\s*)(#{1,3}\s+|[•○●◦▪]\s+|[-*]\s+|\[[ xX]\]\s+|\d+\.\s+|>\s+|```\s?)',
    );

    String newText = fullText;
    int shift = 0;
    final removed = <(int, int)>[];

    for (int i = startLine; i <= actualEndLine; i++) {
      final ls = lineStarts[i] + shift;
      if (ls > newText.length) break;
      // Every stacked symbol goes ("> 1. text" loses "> " and "1. "), not only the first.
      while (true) {
        final le = (i + 1 < lineStarts.length)
            ? lineStarts[i + 1] - 1 + shift
            : newText.length;
        final lineStr = newText.substring(ls, math.min(le, newText.length));
        final match = prefixRegex.firstMatch(lineStr);
        if (match == null) break;
        // The indentation (group 1) stays: only the symbol after it goes.
        final start = ls + match.group(1)!.length;
        final matchLen = match.group(2)!.length;
        newText = newText.replaceRange(start, start + matchLen, '');
        removed.add((start - shift, matchLen));
        shift -= matchLen;
      }
    }

    // Removing the symbols moves the offsets after them. The selection keeps
    // its lines, so the caller can still act on every selected line.
    final sel = selection;
    if (newText != fullText) {
      _applyRemovalsToSpans(removed);
      // The spans are already moved: marking the new text as seen stops the
      // change listener from moving them a second time.
      _previousText = newText;
      value = TextEditingValue(
        text: newText,
        selection: sel.isValid
            ? TextSelection(
                baseOffset: _offsetAfterRemovals(sel.baseOffset, removed),
                extentOffset: _offsetAfterRemovals(sel.extentOffset, removed),
              )
            : TextSelection.collapsed(offset: newText.length),
      );
      _previousSelection = selection;
      _normalizeSpans();
    }
  }

  /// Offset in the text after the [removed] symbols, given as (original
  /// offset, length) pairs in increasing order.
  static int _offsetAfterRemovals(int offset, List<(int, int)> removed) {
    var removedBefore = 0;
    for (final (from, len) in removed) {
      if (offset >= from + len) {
        removedBefore += len;
      } else if (offset > from) {
        removedBefore += offset - from;
      }
    }
    return offset - removedBefore;
  }

  void _applyRemovalsToSpans(List<(int, int)> removed) {
    for (final s in spans) {
      s.start = _offsetAfterRemovals(s.start, removed);
      s.end = _offsetAfterRemovals(s.end, removed);
    }
  }

  /// Moves the spans for [length] characters inserted at [at]: formatting
  /// starting at or after the insertion moves with the text.
  void _applyInsertionToSpans(int at, int length) {
    for (final s in spans) {
      if (s.start >= at) {
        s.start += length;
        s.end += length;
      } else if (s.end > at) {
        s.end += length;
      }
    }
  }

  void _handleTextChanges() {
    final currentText = text;
    final currentSelection = selection;
    if (currentText == _previousText) {
      _previousSelection = currentSelection;
      return;
    }

    final oldText = _previousText;
    final change = _locateChange(
      oldText,
      currentText,
      _previousSelection,
      currentSelection,
    );
    _applyChange(oldText, currentText, change.$1, change.$2, change.$3);
    _previousText = currentText;
    _previousSelection = currentSelection;
    _convertMarkdownShortcuts();
  }

  (int, int, int) _locateChange(
    String oldText,
    String newText,
    TextSelection oldSelection,
    TextSelection newSelection,
  ) {
    final lengthDelta = newText.length - oldText.length;
    if (oldSelection.isValid && newSelection.isValid) {
      final start = oldSelection.isCollapsed
          ? (lengthDelta < 0 ? newSelection.start : oldSelection.start)
          : oldSelection.start;
      final oldLength = oldSelection.isCollapsed
          ? (lengthDelta < 0 ? -lengthDelta : 0)
          : oldSelection.end - oldSelection.start;
      final oldEnd = (start + oldLength).clamp(start, oldText.length);
      final newLength = (oldLength + lengthDelta).clamp(
        0,
        newText.length - start,
      );
      final newEnd = start + newLength;
      if (start <= oldText.length &&
          start <= newText.length &&
          oldText.substring(0, start) == newText.substring(0, start) &&
          oldText.substring(oldEnd) == newText.substring(newEnd)) {
        return (start, oldEnd, newEnd);
      }
    }

    var prefix = 0;
    final minLength = math.min(oldText.length, newText.length);
    while (prefix < minLength && oldText[prefix] == newText[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText[oldText.length - suffix - 1] ==
            newText[newText.length - suffix - 1]) {
      suffix++;
    }
    return (prefix, oldText.length - suffix, newText.length - suffix);
  }

  void _applyChange(
    String oldText,
    String newText,
    int start,
    int oldEnd,
    int newEnd,
  ) {
    _reconcileLineStyles(oldText, newText, start, oldEnd, newEnd);
    final shift = newEnd - oldEnd;
    final updated = <StyleSpan>[];
    for (final original in spans) {
      final span = original.copyWith();
      if (span.end <= start) {
        updated.add(span);
      } else if (span.start >= oldEnd) {
        span.start += shift;
        span.end += shift;
        updated.add(span);
      } else {
        final newStart = span.start < start ? span.start : start;
        final spanEnd = span.end > oldEnd ? span.end + shift : newEnd;
        if (spanEnd > newStart) {
          span.start = newStart;
          span.end = spanEnd;
          updated.add(span);
        }
      }
    }
    spans = updated;
    if (newEnd > start &&
        oldEnd == start &&
        (activeBold ||
            activeItalic ||
            activeUnderline ||
            activeStrikethrough)) {
      spans.add(
        StyleSpan(
          start: start,
          end: newEnd,
          isBold: activeBold,
          isItalic: activeItalic,
          isUnderline: activeUnderline,
          isStrikethrough: activeStrikethrough,
        ),
      );
    }
    _normalizeFormatting();
  }

  void _convertMarkdownShortcuts() {
    final heading = RegExp(r'(^|\n)(#{1,3}) ');
    RegExpMatch? match;
    while ((match = heading.firstMatch(text)) != null) {
      final found = match!;
      final start = found.start + found.group(1)!.length;
      final oldEnd = found.end;
      final oldText = text;
      final newText = oldText.replaceRange(start, oldEnd, '');
      final line = getLineIndexInString(oldText, start);
      lineStyles[line] = switch (found.group(2)!.length) {
        1 => BlockType.h1,
        2 => BlockType.h2,
        _ => BlockType.h3,
      };
      _applyChange(oldText, newText, start, oldEnd, start);
      final caret = (selection.start - (oldEnd - start)).clamp(
        0,
        newText.length,
      );
      final nextValue = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: caret),
      );
      _previousText = newText;
      _previousSelection = nextValue.selection;
      super.value = nextValue;
      _previousSelection = selection;
    }

    final patterns = <(RegExp, String Function(RegExpMatch))>[
      (
        RegExp(r'(^|\n)(?:[-*•][ \t]*)?\[[ \t]*\] '),
        (m) => '${m.group(1) ?? ''}○ ',
      ),
      (
        RegExp(r'(^|\n)(?:[-*•][ \t]*)?\[[xX]\] '),
        (m) => '${m.group(1) ?? ''}● ',
      ),
      (
        RegExp(r'(^|\n)([ \t]*)[-*] (?![\[○●])'),
        (m) {
          final indent = m.group(2) ?? '';
          return '${m.group(1) ?? ''}$indent${getBulletForIndent(indent.length)} ';
        },
      ),
    ];
    for (final (pattern, replacementFor) in patterns) {
      while ((match = pattern.firstMatch(text)) != null) {
        final found = match!;
        final replacement = replacementFor(found);
        final start = found.start;
        final oldText = text;
        final newText = oldText.replaceRange(start, found.end, replacement);
        _applyChange(
          oldText,
          newText,
          start,
          found.end,
          start + replacement.length,
        );
        final caret =
            (selection.start + replacement.length - (found.end - start)).clamp(
              0,
              newText.length,
            );
        final nextValue = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: caret),
        );
        _previousText = newText;
        _previousSelection = nextValue.selection;
        super.value = nextValue;
      }
    }

    // Line types from a typed prefix: the prefix stays in the text. Only body
    // lines react; heading lines keep their style and their typed sign.
    const typedStyles = {BlockType.quote, BlockType.code, BlockType.numbered};
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final current = lineStyles[i];
      if (current != null &&
          current != BlockType.paragraph &&
          !typedStyles.contains(current)) {
        continue;
      }
      final detected = RegExp(r'^\s*> ').hasMatch(line)
          ? BlockType.quote
          : RegExp(r'^\s*```').hasMatch(line)
          ? BlockType.code
          : RegExp(r'^\s*\d+\.\s+').hasMatch(line)
          ? BlockType.numbered
          : null;
      if (detected != null) {
        lineStyles[i] = detected;
      } else if (current != null && typedStyles.contains(current)) {
        // The sign was deleted: the line is body text again.
        lineStyles[i] = BlockType.paragraph;
      }
    }
  }

  /// Handles Enter key: auto-continues or exits bullet/checklist/numbered lists, breaks headings into body
  bool handleEnterKey() {
    final sel = selection;
    if (!sel.isValid) return false;
    final pos = sel.start;
    final fullText = text;

    final lineStart = fullText.lastIndexOf('\n', math.max(0, pos - 1)) + 1;
    int nextNewline = fullText.indexOf('\n', pos);
    if (nextNewline == -1) nextNewline = fullText.length;
    final currentLine = fullText.substring(lineStart, nextNewline);

    final lineIdx = getLineIndexAtOffset(pos);
    final lineStyle = getLineStyle(lineIdx);
    final isHeading =
        lineStyle == BlockType.title ||
        lineStyle == BlockType.h1 ||
        lineStyle == BlockType.h2 ||
        lineStyle == BlockType.h3;

    final checkMatch = RegExp(
      r'^(\s*)([○●]|(?:[-*•]\s*)?\[[ xX]\](?=\s))\s*',
    ).firstMatch(currentLine);
    final bulletMatch = RegExp(
      r'^(\s*)([•◦▪]|-|\*)\s+',
    ).firstMatch(currentLine);
    final numMatch = RegExp(r'^(\s*)(\d+)\.\s+').firstMatch(currentLine);

    if (checkMatch != null && !isHeading) {
      final prefix = checkMatch.group(0)!;
      final rest = currentLine.substring(prefix.length).trim();
      final indent = checkMatch.group(1) ?? '';
      if (rest.isEmpty) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final replacement = '${newIndent}○ ';
          final newText = fullText.replaceRange(
            lineStart,
            lineStart + prefix.length,
            replacement,
          );
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: lineStart + replacement.length,
            ),
          );
          return true;
        } else {
          final newText = fullText.replaceRange(
            lineStart,
            lineStart + prefix.length,
            '',
          );
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      } else {
        // A caret before the text splits the item right after its marker.
        final splitAt = math.max(pos, lineStart + prefix.length);
        final nextCheck = '\n${indent}○ ';
        final newText = fullText.replaceRange(
          splitAt,
          math.max(sel.end, splitAt),
          nextCheck,
        );
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: splitAt + nextCheck.length,
          ),
        );
        return true;
      }
    } else if (bulletMatch != null && !isHeading) {
      final prefix = bulletMatch.group(0)!;
      final rest = currentLine.substring(prefix.length).trim();
      final indent = bulletMatch.group(1) ?? '';
      if (rest.isEmpty) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final newBullet = getBulletForIndent(newIndent.length);
          final replacement = '$newIndent$newBullet ';
          final newText = fullText.replaceRange(
            lineStart,
            lineStart + prefix.length,
            replacement,
          );
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: lineStart + replacement.length,
            ),
          );
          return true;
        } else {
          final newText = fullText.replaceRange(
            lineStart,
            lineStart + prefix.length,
            '',
          );
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      } else {
        // A caret before the text splits the item right after its marker.
        final splitAt = math.max(pos, lineStart + prefix.length);
        final bulletChar = getBulletForIndent(indent.length);
        final nextBullet = '\n$indent$bulletChar ';
        final newText = fullText.replaceRange(
          splitAt,
          math.max(sel.end, splitAt),
          nextBullet,
        );
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: splitAt + nextBullet.length,
          ),
        );
        return true;
      }
    } else if (numMatch != null && !isHeading) {
      final prefix = numMatch.group(0)!;
      final numVal = int.tryParse(numMatch.group(2) ?? '1') ?? 1;
      final rest = currentLine.substring(prefix.length).trim();
      final indent = numMatch.group(1) ?? '';
      if (rest.isEmpty) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final replacement = '$newIndent${numVal}. ';
          final newText = fullText.replaceRange(
            lineStart,
            lineStart + prefix.length,
            replacement,
          );
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: lineStart + replacement.length,
            ),
          );
          return true;
        } else {
          final newText = fullText.replaceRange(
            lineStart,
            lineStart + prefix.length,
            '',
          );
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      } else {
        // A caret before the text splits the item right after its marker.
        final splitAt = math.max(pos, lineStart + prefix.length);
        final nextNum = '\n$indent${numVal + 1}. ';
        final newText = fullText.replaceRange(
          splitAt,
          math.max(sel.end, splitAt),
          nextNum,
        );
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: splitAt + nextNum.length,
          ),
        );
        return true;
      }
    } else if (isHeading) {
      // Pressing enter on a heading keeps its style with the text below.
      final oldLineStyles = Map<int, BlockType>.from(lineStyles);
      final atLineStart = pos == lineStart && sel.isCollapsed;
      final newText = fullText.replaceRange(pos, sel.end, '\n');
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + 1),
      );
      if (atLineStart) {
        // Text on the line moves down with the heading style; on an empty
        // line the heading stays above and the cursor lands on a body line.
        final styleMoves = currentLine.isNotEmpty;
        lineStyles = {
          for (final entry in oldLineStyles.entries)
            if (entry.key > lineIdx || (entry.key == lineIdx && styleMoves))
              entry.key + 1: entry.value
            else if (entry.key < lineIdx)
              entry.key: entry.value,
          lineIdx: BlockType.paragraph,
        };
        _normalizeFormatting();
        notifyListeners();
      }
      return true;
    }

    return false;
  }

  /// Returns the authentic Notion bullet glyph based on indent level (in spaces).
  /// Level 0 (0 spaces): '•' (solid disc, \u2022)
  /// Level 1 (2 spaces): '◦' (hollow circle, \u25E6)
  /// Level 2+ (4+ spaces): '▪' (solid square, \u25AA)
  static String getBulletForIndent(int indentSpaces) {
    final level = indentSpaces ~/ 2;
    final mod = level % 3;
    if (mod == 0) return '•';
    if (mod == 1) return '◦';
    return '▪';
  }

  /// Maps an offset of the text before [edits] to the text after them. Each edit
  /// `(start, removed, inserted)` replaces [removed] characters at [start]. An offset
  /// inside removed characters goes to the start of its replacement; an end offset
  /// at [start] stays before the inserted characters.
  static int _mapOffsetThroughEdits(
    int offset,
    List<(int, int, int)> edits, {
    required bool isEnd,
  }) {
    var shift = 0;
    for (final (start, removed, inserted) in edits) {
      if (offset < start || (isEnd && offset == start)) break;
      if (offset < start + removed) return start + shift;
      shift += inserted - removed;
    }
    return offset + shift;
  }

  /// Handles Tab key (or Shift+Tab if [outdent] is true) as expected in Notion:
  /// - On bullet lists, indents to a nested internal sub-bullet ('• ' -> '  ◦ ' -> '    ▪ ')
  /// - If [outdent] is true, decreases indent level ('    ▪ ' -> '  ◦ ' -> '• ')
  /// - Also supports multi-line selection indentation and checklists/numbered lists
  bool handleTabKey({bool outdent = false}) {
    final sel = selection;
    if (!sel.isValid) return false;
    final fullText = text;
    final startPos = math.min(sel.start, sel.end);
    final endPos = math.max(sel.start, sel.end);

    final lineStart = fullText.lastIndexOf('\n', math.max(0, startPos - 1)) + 1;
    int lineEnd = fullText.indexOf('\n', endPos);
    if (lineEnd == -1) lineEnd = fullText.length;

    final selectedRegion = fullText.substring(lineStart, lineEnd);
    final lines = selectedRegion.split('\n');
    final firstLineIdx = getLineIndexInString(fullText, lineStart);
    final transformedLines = <String>[];
    int deltaTotal = 0;
    int firstLineDelta = 0;
    final edits = <(int, int, int)>[];
    var lineOffset = lineStart;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineStartOffset = lineOffset;
      lineOffset += line.length + 1;
      // Headings have no Tab action: keep the line as it is.
      final lineStyle = getLineStyle(firstLineIdx + i);
      if (lineStyle == BlockType.title ||
          lineStyle == BlockType.h1 ||
          lineStyle == BlockType.h2 ||
          lineStyle == BlockType.h3) {
        transformedLines.add(line);
        continue;
      }
      final bulletMatch = RegExp(r'^(\s*)([•◦▪]|\*|-)\s+').firstMatch(line);
      final checkMatch = RegExp(
        r'^(\s*)([○●]|(?:[-*•]\s*)?\[[ xX]\](?=\s))\s*',
      ).firstMatch(line);
      final numMatch = RegExp(r'^(\s*)(\d+)\.\s+').firstMatch(line);

      String newLine = line;
      if (bulletMatch != null) {
        final indent = bulletMatch.group(1) ?? '';
        final rest = line.substring(bulletMatch.group(0)!.length);
        if (!outdent) {
          // Indent 1 level (2 spaces)
          final newIndent = '$indent  ';
          final newGlyph = getBulletForIndent(newIndent.length);
          newLine = '$newIndent$newGlyph $rest';
        } else {
          // Outdent 1 level (2 spaces)
          if (indent.length >= 2) {
            final newIndent = indent.substring(2);
            final newGlyph = getBulletForIndent(newIndent.length);
            newLine = '$newIndent$newGlyph $rest';
          } else {
            // Level 0 outdent: remove bullet, convert to plain text
            newLine = rest;
          }
        }
      } else if (checkMatch != null) {
        final indent = checkMatch.group(1) ?? '';
        final checkSymbol = checkMatch.group(2)!;
        final rest = line.substring(checkMatch.group(0)!.length);
        if (!outdent) {
          newLine = '$indent  $checkSymbol $rest';
        } else {
          if (indent.length >= 2) {
            newLine = '${indent.substring(2)}$checkSymbol $rest';
          } else {
            newLine = rest;
          }
        }
      } else if (numMatch != null) {
        final indent = numMatch.group(1) ?? '';
        final numPart = numMatch.group(2)!;
        final rest = line.substring(numMatch.group(0)!.length);
        if (!outdent) {
          newLine = '$indent  $numPart. $rest';
        } else {
          if (indent.length >= 2) {
            newLine = '${indent.substring(2)}$numPart. $rest';
          } else {
            newLine = rest;
          }
        }
      } else {
        // Plain text line
        if (!outdent) {
          newLine = '  $line';
        } else {
          if (line.startsWith('  ')) {
            newLine = line.substring(2);
          } else if (line.startsWith(' ')) {
            newLine = line.substring(1);
          }
        }
      }

      if (newLine != line) {
        var common = 0;
        while (common < line.length &&
            common < newLine.length &&
            line[line.length - 1 - common] == newLine[newLine.length - 1 - common]) {
          common++;
        }
        edits.add((lineStartOffset, line.length - common, newLine.length - common));
      }

      final lineDelta = newLine.length - line.length;
      if (i == 0) firstLineDelta = lineDelta;
      deltaTotal += lineDelta;
      transformedLines.add(newLine);
    }

    final newSelectedRegion = transformedLines.join('\n');
    final newText = fullText.replaceRange(
      lineStart,
      lineEnd,
      newSelectedRegion,
    );

    // Update selection
    final TextSelection newSelection;
    if (sel.isCollapsed) {
      final newCaret = math.max(
        lineStart,
        math.min(newText.length, sel.start + firstLineDelta),
      );
      newSelection = TextSelection.collapsed(offset: newCaret);
    } else {
      final newStart = math.max(
        0,
        math.min(newText.length, startPos + firstLineDelta),
      );
      final newEnd = math.max(
        newStart,
        math.min(newText.length, endPos + deltaTotal),
      );
      newSelection = TextSelection(baseOffset: newStart, extentOffset: newEnd);
    }

    // Move each span through the edits, so it keeps the same characters.
    for (final span in spans) {
      span.start = _mapOffsetThroughEdits(span.start, edits, isEnd: false);
      span.end = math.max(
        span.start,
        _mapOffsetThroughEdits(span.end, edits, isEnd: true),
      );
    }

    // The spans are moved above; the change listener must not move them a second time.
    _previousText = newText;
    _previousSelection = newSelection;
    value = TextEditingValue(text: newText, selection: newSelection);
    _convertMarkdownShortcuts();
    _normalizeSpans();
    notifyListeners();
    return true;
  }

  /// Handles Backspace key on bullet / list items:
  /// - If cursor is right after prefix on empty sub-bullet ('  ◦ '): outdents to '• '
  /// - If cursor is right after the symbol of an indented item, before its space: outdents one level
  /// - If cursor is right after the symbol of a non-indented item, before its space: removes symbol and space
  /// - If cursor is right after prefix on empty bullet ('• '): exits to empty paragraph
  /// - If cursor is at start of text ('  ◦ Text'): outdents line to '• Text'
  /// - If cursor is at start of text on level 0 ('• Text'): converts to 'Text'
  bool handleBackspaceKey() {
    final sel = selection;
    if (!sel.isValid || !sel.isCollapsed) return false;
    final pos = sel.start;
    final fullText = text;

    final lineStart = fullText.lastIndexOf('\n', math.max(0, pos - 1)) + 1;
    int nextNewline = fullText.indexOf('\n', pos);
    if (nextNewline == -1) nextNewline = fullText.length;
    final currentLine = fullText.substring(lineStart, nextNewline);

    final checkMatch = RegExp(
      r'^(\s*)([○●]|(?:[-*•]\s*)?\[[ xX]\](?=\s))\s*',
    ).firstMatch(currentLine);
    if (checkMatch != null) {
      final prefix = checkMatch.group(0)!;
      final prefixEnd = lineStart + prefix.length;
      final indent = checkMatch.group(1) ?? '';
      final rest = currentLine.substring(prefix.length);

      // On indented items the caret right after the circle also outdents
      final afterMarker =
          pos == lineStart + indent.length + checkMatch.group(2)!.length;
      if (pos == prefixEnd || afterMarker) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final replacement = '$newIndent○ $rest';
          final newText = fullText.replaceRange(
            lineStart,
            nextNewline,
            replacement,
          );
          final newCaret = afterMarker
              ? lineStart + newIndent.length + 1
              : lineStart + newIndent.length + 2;
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newCaret),
          );
          return true;
        } else {
          final newText = fullText.replaceRange(lineStart, nextNewline, rest);
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      }
    }

    final bulletMatch = RegExp(
      r'^(\s*)([•◦▪]|\*|-)\s+',
    ).firstMatch(currentLine);
    if (bulletMatch != null) {
      final prefix = bulletMatch.group(0)!;
      final prefixEnd = lineStart + prefix.length;
      final indent = bulletMatch.group(1) ?? '';
      final rest = currentLine.substring(prefix.length);

      // Intercept after the bullet + space, or on an indented item after the bullet
      final afterMarker =
          pos == lineStart + indent.length + bulletMatch.group(2)!.length;
      if (pos == prefixEnd || afterMarker) {
        if (indent.length >= 2) {
          // Outdent 1 level
          final newIndent = indent.substring(2);
          final newBullet = getBulletForIndent(newIndent.length);
          final replacement = '$newIndent$newBullet $rest';
          final newText = fullText.replaceRange(
            lineStart,
            nextNewline,
            replacement,
          );
          final newCaret = afterMarker
              ? lineStart + newIndent.length + 1
              : lineStart + newIndent.length + 2;
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newCaret),
          );
          return true;
        } else {
          // Level 0: remove bullet, convert to normal text / empty paragraph
          final newText = fullText.replaceRange(lineStart, nextNewline, rest);
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      }
    }

    return false;
  }

  /// Applies a line prefix (e.g., '• ', '○ ', '> ') across current selection or line.
  /// With [bulletByIndent], each line gets the bullet of its own indent level
  /// ('•', '◦', '▪') and [prefix] is not used.
  void applyLinePrefix(String prefix, {bool bulletByIndent = false}) {
    final sel = selection;
    final fullText = text;
    final startPos = sel.isValid
        ? math.min(sel.start, sel.end)
        : fullText.length;
    final endPos = sel.isValid ? math.max(sel.start, sel.end) : fullText.length;

    final lineStart = fullText.lastIndexOf('\n', math.max(0, startPos - 1)) + 1;
    int lineEnd = fullText.indexOf('\n', endPos);
    if (lineEnd == -1) lineEnd = fullText.length;

    final selectedRegion = fullText.substring(lineStart, lineEnd);
    final lines = selectedRegion.split('\n');

    final prefixRegex = RegExp(
      r'^(```\s?|#{1,3}\s+|[•○●◦▪]\s+|[-*]\s+|\[[ xX]\]\s+|\d+\.\s+|>\s+)',
    );
    // Per line, the symbols after the indentation go and the new one takes
    // their place: (offset before the change, removed length, inserted text).
    final edits = <(int, int, String)>[];
    final transformedLines = <String>[];
    var lineOffset = lineStart;
    for (final line in lines) {
      final indent = RegExp(r'^\s*').stringMatch(line)!;
      final body = line.substring(indent.length);
      var withoutPrefix = body;
      while (prefixRegex.hasMatch(withoutPrefix)) {
        withoutPrefix = withoutPrefix.replaceFirst(prefixRegex, '');
      }
      final linePrefix = bulletByIndent
          ? '${getBulletForIndent(indent.length)} '
          : prefix;
      // Applying the same prefix again removes it.
      final insert = linePrefix.isEmpty || body.startsWith(linePrefix)
          ? ''
          : linePrefix;
      final removedLength = body.length - withoutPrefix.length;
      if (removedLength > 0 || insert.isNotEmpty) {
        edits.add((lineOffset + indent.length, removedLength, insert));
      }
      transformedLines.add('$indent$insert$withoutPrefix');
      lineOffset += line.length + 1;
    }

    final newRegion = transformedLines.join('\n');
    final newText = fullText.replaceRange(lineStart, lineEnd, newRegion);

    // Spans follow their text. Edits go from the last line to the first, so
    // every offset still refers to the text before the change it meets.
    for (final (at, removedLength, insert) in edits.reversed) {
      if (removedLength > 0) {
        _applyRemovalsToSpans([(at, removedLength)]);
      }
      if (insert.isNotEmpty) {
        _applyInsertionToSpans(at, insert.length);
      }
    }

    // The spans were moved above, so the change listener must not move them
    // again: marking the new text as seen makes it skip the change.
    _previousText = newText;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + newRegion.length,
      ),
    );
    _previousSelection = selection;
    _normalizeFormatting();
    _convertMarkdownShortcuts();
    notifyListeners();
  }

  DateTime? _lastToggleTime;

  @visibleForTesting
  void resetToggleDebounce() {
    _lastToggleTime = null;
  }

  /// Toggles checklist ○ <-> ● on the current line or adds ○ if none exists
  void toggleChecklistAtCursor() {
    final sel = selection;
    final pos = sel.isValid ? sel.start : text.length;
    final fullText = text;

    final int lineStart;
    if (pos <= 0) {
      lineStart = 0;
    } else {
      final prevNewline = fullText.lastIndexOf('\n', pos - 1);
      lineStart = prevNewline == -1 ? 0 : prevNewline + 1;
    }
    int lineEnd = fullText.indexOf('\n', pos);
    if (lineEnd == -1) lineEnd = fullText.length;

    final line = fullText.substring(lineStart, lineEnd);
    final matchUnchecked = RegExp(r'^(\s*)(?:○|\[ \](?=\s))\s*').firstMatch(line);
    final matchChecked = RegExp(r'^(\s*)(?:●|\[[xX]\](?=\s))\s*').firstMatch(line);

    if (matchUnchecked != null) {
      final indent = matchUnchecked.group(1) ?? '';
      final rest = line.substring(matchUnchecked.group(0)!.length);
      final newLine = '$indent● $rest';
      final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: math.min(newText.length, pos),
        ),
      );
      notifyListeners();
    } else if (matchChecked != null) {
      final indent = matchChecked.group(1) ?? '';
      final rest = line.substring(matchChecked.group(0)!.length);
      final newLine = '$indent○ $rest';
      final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: math.min(newText.length, pos),
        ),
      );
      notifyListeners();
    } else {
      final cursorLine = getLineIndexInString(fullText, pos);
      // The button acts on the cursor line only, the other selected lines stay as they are.
      value = value.copyWith(selection: TextSelection.collapsed(offset: pos));
      applyLinePrefix('○ ');
      // The checklist line is body text: heading styles do not apply to it.
      setLineStyle(cursorLine, BlockType.paragraph);
    }
  }

  /// Toggles checklist ○ <-> ● if click occurred within checkbox prefix
  bool toggleChecklistAtOffset(int charOffset) {
    if (charOffset < 0 || charOffset > text.length) return false;
    final now = DateTime.now();
    if (_lastToggleTime != null &&
        now.difference(_lastToggleTime!).inMilliseconds < 250) {
      return false;
    }
    final fullText = text;

    final int lineStart;
    if (charOffset <= 0) {
      lineStart = 0;
    } else {
      final prevNewline = fullText.lastIndexOf('\n', charOffset - 1);
      lineStart = prevNewline == -1 ? 0 : prevNewline + 1;
    }
    int lineEnd = fullText.indexOf('\n', charOffset);
    if (lineEnd == -1) lineEnd = fullText.length;

    final line = fullText.substring(lineStart, lineEnd);
    final matchUnchecked = RegExp(r'^(\s*)(?:○|\[ \](?=\s))\s*').firstMatch(line);
    final matchChecked = RegExp(r'^(\s*)(?:●|\[[xX]\](?=\s))\s*').firstMatch(line);

    if (matchUnchecked != null) {
      final prefixLen = matchUnchecked.group(0)!.length;
      final circleAt = lineStart + matchUnchecked.group(1)!.length;
      if (charOffset >= circleAt && charOffset <= circleAt + 1) {
        _lastToggleTime = now;
        final indent = matchUnchecked.group(1) ?? '';
        final rest = line.substring(prefixLen);
        final newLine = '$indent● $rest';
        final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: math.min(newText.length, lineStart + prefixLen),
          ),
        );
        notifyListeners();
        return true;
      }
    } else if (matchChecked != null) {
      final prefixLen = matchChecked.group(0)!.length;
      final circleAt = lineStart + matchChecked.group(1)!.length;
      if (charOffset >= circleAt && charOffset <= circleAt + 1) {
        _lastToggleTime = now;
        final indent = matchChecked.group(1) ?? '';
        final rest = line.substring(prefixLen);
        final newLine = '$indent○ $rest';
        final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: math.min(newText.length, lineStart + prefixLen),
          ),
        );
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void _normalizeSpans() {
    spans.removeWhere((s) => s.isEmpty || s.start >= text.length);
    for (final s in spans) {
      if (s.end > text.length) s.end = text.length;
    }

    if (spans.isEmpty) return;

    final boundaries = <int>{};
    for (final s in spans) {
      boundaries.add(s.start);
      boundaries.add(s.end);
    }
    final sorted = boundaries.toList()..sort();
    final merged = <StyleSpan>[];

    for (int i = 0; i < sorted.length - 1; i++) {
      final segStart = sorted[i];
      final segEnd = sorted[i + 1];
      if (segStart >= segEnd) continue;

      bool isBold = false;
      bool isItalic = false;
      bool isUnderline = false;
      bool isStrikethrough = false;

      for (final s in spans) {
        if (s.start <= segStart && s.end >= segEnd) {
          if (s.isBold) isBold = true;
          if (s.isItalic) isItalic = true;
          if (s.isUnderline) isUnderline = true;
          if (s.isStrikethrough) isStrikethrough = true;
        }
      }

      if (isBold || isItalic || isUnderline || isStrikethrough) {
        if (merged.isNotEmpty &&
            merged.last.end == segStart &&
            merged.last.isBold == isBold &&
            merged.last.isItalic == isItalic &&
            merged.last.isUnderline == isUnderline &&
            merged.last.isStrikethrough == isStrikethrough) {
          merged.last.end = segEnd;
        } else {
          merged.add(
            StyleSpan(
              start: segStart,
              end: segEnd,
              isBold: isBold,
              isItalic: isItalic,
              isUnderline: isUnderline,
              isStrikethrough: isStrikethrough,
            ),
          );
        }
      }
    }

    spans = merged;
  }

  /// Toggles bold formatting on the current selection or sets active state for next typed char
  void toggleBold() {
    _toggleStyle(
      getStyle: (s) => s.isBold,
      setStyle: (s, v) => s.isBold = v,
      getActive: () => activeBold,
      setActive: (v) => activeBold = v,
    );
  }

  /// Toggles italic formatting on the current selection
  void toggleItalic() {
    _toggleStyle(
      getStyle: (s) => s.isItalic,
      setStyle: (s, v) => s.isItalic = v,
      getActive: () => activeItalic,
      setActive: (v) => activeItalic = v,
    );
  }

  /// Toggles underline formatting on the current selection
  void toggleUnderline() {
    _toggleStyle(
      getStyle: (s) => s.isUnderline,
      setStyle: (s, v) => s.isUnderline = v,
      getActive: () => activeUnderline,
      setActive: (v) => activeUnderline = v,
    );
  }

  /// Toggles strikethrough formatting on the current selection
  void toggleStrikethrough() {
    _toggleStyle(
      getStyle: (s) => s.isStrikethrough,
      setStyle: (s, v) => s.isStrikethrough = v,
      getActive: () => activeStrikethrough,
      setActive: (v) => activeStrikethrough = v,
    );
  }

  void _toggleStyle({
    required bool Function(StyleSpan) getStyle,
    required void Function(StyleSpan, bool) setStyle,
    required bool Function() getActive,
    required void Function(bool) setActive,
  }) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) {
      setActive(!getActive());
      notifyListeners();
      return;
    }

    final start = math.min(sel.start, sel.end);
    final end = math.max(sel.start, sel.end);

    bool allStyled = true;
    for (int i = start; i < end; i++) {
      final hasIt = spans.any((s) => s.start <= i && s.end > i && getStyle(s));
      if (!hasIt) {
        allStyled = false;
        break;
      }
    }

    final targetValue = !allStyled;

    final newSpans = <StyleSpan>[];
    for (final span in spans) {
      if (span.end <= start || span.start >= end) {
        newSpans.add(span);
      } else {
        if (span.start < start) {
          newSpans.add(span.copyWith(end: start));
        }
        if (span.end > end) {
          newSpans.add(span.copyWith(start: end));
        }
        final middle = span.copyWith(
          start: math.max(span.start, start),
          end: math.min(span.end, end),
        );
        setStyle(middle, targetValue);
        if (middle.hasAnyStyle) {
          newSpans.add(middle);
        }
      }
    }

    if (targetValue) {
      final added = StyleSpan(start: start, end: end);
      setStyle(added, true);
      newSpans.add(added);
    }

    spans = newSpans;
    _normalizeSpans();
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveBase = baseStyle.merge(style);
    final rawText = text;

    if (rawText.isEmpty) {
      return TextSpan(text: '', style: effectiveBase);
    }

    // Collect all boundaries (line breaks, span boundaries, start & end)
    final boundaries = <int>{0, rawText.length};
    for (int i = 0; i < rawText.length; i++) {
      if (rawText[i] == '\n') {
        boundaries.add(i);
        boundaries.add(i + 1);
      }
    }
    for (final s in spans) {
      if (s.start >= 0 && s.start <= rawText.length) boundaries.add(s.start);
      if (s.end >= 0 && s.end <= rawText.length) boundaries.add(s.end);
    }
    // Compute line start indices
    final lineStarts = <int>[0];
    for (int i = 0; i < rawText.length; i++) {
      if (rawText[i] == '\n') {
        lineStarts.add(i + 1);
      }
    }

    // Add prefix boundaries so checklist prefixes (○, ●, [ ], [x]) are styled distinctly from body
    for (int i = 0; i < lineStarts.length; i++) {
      final ls = lineStarts[i];
      final le = (i + 1 < lineStarts.length)
          ? lineStarts[i + 1] - 1
          : rawText.length;
      final lineStr = rawText.substring(ls, le);
      final trimmed = lineStr.trimLeft();
      final circleMatch = RegExp(r'^([○●])(\s*)').firstMatch(trimmed);
      final checkMatch = RegExp(
        r'^((?:[-*•]\s*)?\[[ xX]\]\s*)',
      ).firstMatch(trimmed);
      if (circleMatch != null) {
        final indentLen = lineStr.length - trimmed.length;
        boundaries.add(ls + indentLen);
        boundaries.add(ls + indentLen + 1);
        final prefixLen = circleMatch.group(0)!.length;
        if (ls + indentLen + prefixLen <= rawText.length) {
          boundaries.add(ls + indentLen + prefixLen);
        }
      } else if (checkMatch != null) {
        final indentLen = lineStr.length - trimmed.length;
        final prefixEnd = ls + indentLen + checkMatch.group(0)!.length;
        if (prefixEnd <= rawText.length) {
          boundaries.add(prefixEnd);
        }
      }
    }

    // Add tag boundaries so #tag is isolated and styled as an Apple tag chip
    final tagRegex = RegExp(r'(?<=^|[\s\(\[\{])#(' + Note.tagNameChar + r'+)', unicode: true);
    for (final m in tagRegex.allMatches(rawText)) {
      boundaries.add(m.start);
      boundaries.add(m.end);
    }

    final sorted = boundaries.toList()..sort();

    final children = <TextSpan>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      final segStart = sorted[i];
      final segEnd = sorted[i + 1];
      if (segStart >= segEnd) continue;

      final segText = rawText.substring(segStart, segEnd);

      // Find line containing segStart
      int lineIdx = lineStarts.length - 1;
      while (lineIdx > 0 && lineStarts[lineIdx] > segStart) {
        lineIdx--;
      }
      final lineStart = lineStarts[lineIdx];
      final lineEnd = (lineIdx + 1 < lineStarts.length)
          ? lineStarts[lineIdx + 1] - 1
          : rawText.length;
      final lineStr = rawText.substring(lineStart, lineEnd);
      final trimmedLine = lineStr.trimLeft();

      TextStyle segStyle = effectiveBase;

      final bool isDark = Theme.of(context).brightness == Brightness.dark;

      final lineStyle = getLineStyle(lineIdx);
      final bool isTitle = lineStyle == BlockType.title;
      final bool isH1 = lineStyle == BlockType.h1 || lineStr.startsWith('# ');
      final bool isH2 = lineStyle == BlockType.h2 || lineStr.startsWith('## ');
      final bool isH3 = lineStyle == BlockType.h3 || lineStr.startsWith('### ');

      final bool isCircleUnchecked = trimmedLine.startsWith('○');
      final bool isCircleChecked = trimmedLine.startsWith('●');
      final bool isChecklistChecked =
          isCircleChecked ||
          RegExp(r'^([-*•]\s*)?\[[xX]\]\s*').hasMatch(trimmedLine);

      final checkMatch = RegExp(
        r'^((?:[-*•]\s*)?\[[ xX]\]\s*)',
      ).firstMatch(trimmedLine);
      final indentLen = lineStr.length - trimmedLine.length;
      final bool isLegacyPrefixSegment =
          checkMatch != null &&
          (segEnd <= lineStart + indentLen + checkMatch.group(0)!.length);
      final bool isQuote = trimmedLine.startsWith('> ');
      final bool isCode = trimmedLine.startsWith('```');

      // Authentic Apple circular checkbox rendering in continuous text stream
      if (isCircleChecked &&
          segStart == lineStart + indentLen &&
          segEnd == lineStart + indentLen + 1) {
        children.add(
          TextSpan(
            text: String.fromCharCode(
              CupertinoIcons.checkmark_circle_fill.codePoint,
            ),
            style: TextStyle(
              fontFamily: CupertinoIcons.checkmark_circle_fill.fontFamily,
              package: CupertinoIcons.checkmark_circle_fill.fontPackage,
              fontSize: 16.5,
              color: const Color(0xFFEBA625),
              height: 1.45,
            ),
          ),
        );
        continue;
      }
      if (isCircleUnchecked &&
          segStart == lineStart + indentLen &&
          segEnd == lineStart + indentLen + 1) {
        children.add(
          TextSpan(
            text: String.fromCharCode(CupertinoIcons.circle.codePoint),
            style: TextStyle(
              fontFamily: CupertinoIcons.circle.fontFamily,
              package: CupertinoIcons.circle.fontPackage,
              fontSize: 16.5,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFFA1A1A6),
              height: 1.45,
            ),
          ),
        );
        continue;
      }

      if (isTitle) {
        segStyle = segStyle.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.35,
        );
      } else if (isH1) {
        segStyle = segStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.35,
        );
      } else if (isH2) {
        segStyle = segStyle.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.35,
        );
      } else if (isH3) {
        segStyle = segStyle.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
        );
      } else if (isLegacyPrefixSegment) {
        if (isChecklistChecked) {
          segStyle = segStyle.copyWith(
            fontSize: 15,
            height: 1.45,
            color: const Color(0xFFEBA625),
            fontWeight: FontWeight.w700,
          );
        } else {
          segStyle = segStyle.copyWith(
            fontSize: 15,
            height: 1.45,
            color: const Color(0xFFA1A1A6),
            fontWeight: FontWeight.w700,
          );
        }
      } else if (isChecklistChecked &&
          (!isCircleChecked || segStart >= lineStart + indentLen + 2)) {
        segStyle = segStyle.copyWith(
          fontSize: 15,
          height: 1.45,
          color: effectiveBase.color?.withOpacity(0.55),
          decoration: TextDecoration.lineThrough,
        );
      } else if (isQuote) {
        segStyle = segStyle.copyWith(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: effectiveBase.color?.withOpacity(0.85),
          height: 1.45,
        );
      } else if (isCode) {
        segStyle = segStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 13.5,
          height: 1.4,
        );
      } else {
        segStyle = segStyle.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          height: 1.45,
        );
      }

      final bool isTag = RegExp(r'^#(' + Note.tagNameChar + r'+)$', unicode: true).hasMatch(segText);
      if (isTag && !isCode) {
        final tagColor = isDark
            ? const Color(0xFFEBA625)
            : const Color(0xFF965F00);
        segStyle = segStyle.copyWith(
          color: tagColor,
          fontWeight: FontWeight.w700,
          backgroundColor: tagColor.withOpacity(0.15),
        );
      }

      // Apply character-level StyleSpans on top
      bool isBold = false;
      bool isItalic = false;
      bool isUnderline = false;
      bool isStrikethrough = false;

      for (final s in spans) {
        if (s.start <= segStart && s.end >= segEnd) {
          if (s.isBold) isBold = true;
          if (s.isItalic) isItalic = true;
          if (s.isUnderline) isUnderline = true;
          if (s.isStrikethrough) isStrikethrough = true;
        }
      }

      if (isBold) {
        segStyle = segStyle.copyWith(fontWeight: FontWeight.w700);
      }
      if (isItalic) {
        segStyle = segStyle.copyWith(fontStyle: FontStyle.italic);
      }
      if (isUnderline && (isStrikethrough || isChecklistChecked)) {
        segStyle = segStyle.copyWith(
          decoration: TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ]),
        );
      } else if (isUnderline) {
        segStyle = segStyle.copyWith(decoration: TextDecoration.underline);
      } else if (isStrikethrough) {
        segStyle = segStyle.copyWith(decoration: TextDecoration.lineThrough);
      }

      children.add(TextSpan(text: segText, style: segStyle));
    }

    return TextSpan(children: children);
  }

  /// Converts text and spans to clean standard Markdown for file export
  String toMarkdown() {
    if (text.isEmpty) return '';
    final rawText = text;
    final boundaries = <int>{0, rawText.length};
    for (final s in spans) {
      if (s.start >= 0 && s.start <= rawText.length) boundaries.add(s.start);
      if (s.end >= 0 && s.end <= rawText.length) boundaries.add(s.end);
    }
    final sorted = boundaries.toList()..sort();
    final buffer = StringBuffer();

    for (int i = 0; i < sorted.length - 1; i++) {
      final segStart = sorted[i];
      final segEnd = sorted[i + 1];
      if (segStart >= segEnd) continue;

      final segText = rawText.substring(segStart, segEnd);

      bool isBold = false;
      bool isItalic = false;
      bool isStrikethrough = false;

      for (final s in spans) {
        if (s.start <= segStart && s.end >= segEnd) {
          if (s.isBold) isBold = true;
          if (s.isItalic) isItalic = true;
          if (s.isStrikethrough) isStrikethrough = true;
        }
      }

      String chunk = segText;
      if (isBold) chunk = '**$chunk**';
      if (isItalic) chunk = '*$chunk*';
      if (isStrikethrough) chunk = '~~$chunk~~';

      buffer.write(chunk);
    }

    String result = buffer.toString();
    final rawLines = result.split('\n');
    final formattedLines = <String>[];
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      final style = getLineStyle(i);
      if (style == BlockType.title && !line.startsWith('#')) {
        formattedLines.add(line.isEmpty ? '' : '# $line');
      } else if (style == BlockType.h1 && !line.startsWith('#')) {
        formattedLines.add('# $line');
      } else if (style == BlockType.h2 && !line.startsWith('#')) {
        formattedLines.add('## $line');
      } else if (style == BlockType.h3 && !line.startsWith('#')) {
        formattedLines.add('### $line');
      } else {
        formattedLines.add(line);
      }
    }
    result = formattedLines.join('\n');

    result = result.replaceAllMapped(
      RegExp(r'(^|\n)(\s*)○\s*'),
      (m) => '${m.group(1)}${m.group(2)}- [ ] ',
    );
    result = result.replaceAllMapped(
      RegExp(r'(^|\n)(\s*)●\s*'),
      (m) => '${m.group(1)}${m.group(2)}- [x] ',
    );
    return result;
  }

  @override
  void dispose() {
    removeListener(_handleTextChanges);
    super.dispose();
  }
}
