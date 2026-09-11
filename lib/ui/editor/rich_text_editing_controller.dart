import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/note_model.dart';
import '../../core/models/style_span.dart';

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

  RichTextEditingController({
    super.text,
    required this.baseStyle,
    List<StyleSpan>? spans,
    Map<int, BlockType>? lineStyles,
  })  : spans = spans ?? [],
        lineStyles = lineStyles != null ? Map.from(lineStyles) : {} {
    _previousText = text;
    _cleanInitialMarkdownHeadings();
    addListener(_handleTextChanges);
  }

  void _cleanInitialMarkdownHeadings() {
    final rawLines = text.split('\n');
    bool hasMarkdownHeading = false;
    final cleanedLines = <String>[];

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('### ')) {
        hasMarkdownHeading = true;
        lineStyles[i] = BlockType.h3;
        cleanedLines.add(line.replaceFirst('### ', ''));
      } else if (trimmed.startsWith('## ')) {
        hasMarkdownHeading = true;
        lineStyles[i] = BlockType.h2;
        cleanedLines.add(line.replaceFirst('## ', ''));
      } else if (trimmed.startsWith('# ')) {
        hasMarkdownHeading = true;
        lineStyles[i] = BlockType.h1;
        cleanedLines.add(line.replaceFirst('# ', ''));
      } else {
        cleanedLines.add(line);
      }
    }

    if (hasMarkdownHeading) {
      final newText = cleanedLines.join('\n');
      text = newText;
      _previousText = newText;
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

  void _reconcileLineStyles(String oldText, String newText) {
    if (oldText == newText) return;

    // 1. Find common prefix
    int commonPrefix = 0;
    final minLen = math.min(oldText.length, newText.length);
    while (commonPrefix < minLen && oldText[commonPrefix] == newText[commonPrefix]) {
      commonPrefix++;
    }

    // 2. Find common suffix
    int commonSuffix = 0;
    while (commonSuffix < (oldText.length - commonPrefix) &&
        commonSuffix < (newText.length - commonPrefix) &&
        oldText[oldText.length - 1 - commonSuffix] == newText[newText.length - 1 - commonSuffix]) {
      commonSuffix++;
    }

    // 3. Line boundaries in oldText
    final oldDeletedStart = commonPrefix;
    final oldDeletedEnd = oldText.length - commonSuffix;
    final startLineOld = getLineIndexInString(oldText, oldDeletedStart);
    final endLineOld = getLineIndexInString(oldText, oldDeletedEnd);
    final oldLineSpan = endLineOld - startLineOld;

    // 4. Line boundaries in newText
    final newInsertedStart = commonPrefix;
    final newInsertedEnd = newText.length - commonSuffix;
    final startLineNew = getLineIndexInString(newText, newInsertedStart);
    final endLineNew = getLineIndexInString(newText, newInsertedEnd);
    final newLineSpan = endLineNew - startLineNew;

    final linesDelta = newLineSpan - oldLineSpan;
    if (linesDelta == 0 && oldLineSpan == 0 && newLineSpan == 0) {
      return;
    }

    final updated = <int, BlockType>{};

    // Lines strictly before the edit keep their exact style
    for (int k = 0; k < startLineOld; k++) {
      if (lineStyles.containsKey(k)) {
        updated[k] = lineStyles[k]!;
      }
    }

    // Determine what style the surviving line at startLineOld should take.
    // If the content before the deletion on startLineOld is non-empty,
    // the line began with startLineOld, so it keeps startLineOld's style.
    // If startLineOld was empty/deleted, the line that shifts into startLineOld
    // was originally endLineOld, so it should retain endLineOld's style.
    final startLineOldStart = oldText.lastIndexOf('\n', math.max(0, oldDeletedStart - 1)) + 1;
    final prefixSurviving = oldText.substring(startLineOldStart, oldDeletedStart);

    if (prefixSurviving.isNotEmpty) {
      if (lineStyles.containsKey(startLineOld)) {
        updated[startLineOld] = lineStyles[startLineOld]!;
      }
    } else {
      // startLineOld had no surviving text (empty or completely deleted).
      // Line endLineOld shifted up to startLineOld.
      if (lineStyles.containsKey(endLineOld)) {
        updated[startLineOld] = lineStyles[endLineOld]!;
      }
    }

    // Any new lines inserted in the middle get BlockType.paragraph
    for (int i = 1; i <= newLineSpan; i++) {
      updated[startLineOld + i] = BlockType.paragraph;
    }

    // Lines after the edit region are shifted by linesDelta
    for (final entry in lineStyles.entries) {
      if (entry.key > endLineOld) {
        final newIndex = entry.key + linesDelta;
        if (newIndex >= 0) {
          updated[newIndex] = entry.value;
        }
      }
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
    final prefixRegex = RegExp(r'^(#+\s*|[•○●◦▪]\s*|[-*]\s*|\[[ xX]\]\s*|\d+\.\s*|>\s*|```\s*)');

    String newText = fullText;
    int shift = 0;

    for (int i = startLine; i <= actualEndLine; i++) {
      final ls = lineStarts[i] + shift;
      final le = (i + 1 < lineStarts.length) ? lineStarts[i + 1] - 1 + shift : newText.length;
      if (ls > newText.length) break;
      final lineStr = newText.substring(ls, math.min(le, newText.length));
      final match = prefixRegex.firstMatch(lineStr);
      if (match != null) {
        final matchLen = match.group(0)!.length;
        newText = newText.replaceRange(ls, ls + matchLen, '');
        shift -= matchLen;

        for (final s in spans) {
          if (s.start >= ls + matchLen) {
            s.start -= matchLen;
            s.end -= matchLen;
          } else if (s.end >= ls) {
            s.end -= matchLen;
          }
        }
      }
    }

    if (newText != fullText) {
      final sel = selection;
      final newCaret = math.max(0, math.min(newText.length, sel.isValid ? sel.start + shift : newText.length));
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCaret),
      );
      _normalizeSpans();
    }
  }

  void _handleTextChanges() {
    final currentText = text;
    if (currentText == _previousText) return;

    final diff = currentText.length - _previousText.length;
    final sel = selection;

    // Auto-convert typed markdown shortcuts to live symbols or styles:
    // Headings: '# ', '## ', '### ' -> live styles without visible #
    // Checklists: '[] ', '[ ] ', '- [ ] ', '* [ ] ' -> '○ ' (unchecked)
    // Checklists: '[x] ', '[X] ', '- [x] ', '- [X] ', '* [x] ', '* [X] ' -> '● ' (checked)
    // Bullet list: '- ', '* ' -> '• '
    if (diff > 0) {
      String replaced = currentText;
      if (RegExp(r'(^|\n)###\s').hasMatch(replaced)) {
        final m = RegExp(r'(^|\n)###\s').firstMatch(replaced)!;
        final matchPos = m.start + (m.group(1)?.length ?? 0);
        final lineIdx = getLineIndexAtOffset(matchPos);
        lineStyles[lineIdx] = BlockType.h3;
        replaced = replaced.replaceRange(matchPos, matchPos + 4, '');
      } else if (RegExp(r'(^|\n)##\s').hasMatch(replaced)) {
        final m = RegExp(r'(^|\n)##\s').firstMatch(replaced)!;
        final matchPos = m.start + (m.group(1)?.length ?? 0);
        final lineIdx = getLineIndexAtOffset(matchPos);
        lineStyles[lineIdx] = BlockType.h2;
        replaced = replaced.replaceRange(matchPos, matchPos + 3, '');
      } else if (RegExp(r'(^|\n)#\s').hasMatch(replaced)) {
        final m = RegExp(r'(^|\n)#\s').firstMatch(replaced)!;
        final matchPos = m.start + (m.group(1)?.length ?? 0);
        final lineIdx = getLineIndexAtOffset(matchPos);
        lineStyles[lineIdx] = BlockType.h1;
        replaced = replaced.replaceRange(matchPos, matchPos + 2, '');
      }

      if (RegExp(r'(^|\n)(?:[-*•]\s*)?\[\s*\]\s').hasMatch(replaced)) {
        replaced = replaced.replaceAllMapped(
          RegExp(r'(^|\n)(?:[-*•]\s*)?\[\s*\]\s'),
          (m) => '${m.group(1)}○ ',
        );
      }
      if (RegExp(r'(^|\n)(?:[-*•]\s*)?\[[xX]\]\s').hasMatch(replaced)) {
        replaced = replaced.replaceAllMapped(
          RegExp(r'(^|\n)(?:[-*•]\s*)?\[[xX]\]\s'),
          (m) => '${m.group(1)}● ',
        );
      }
      if (RegExp(r'(^|\n)(\s*)[-*]\s(?![\[○●])').hasMatch(replaced)) {
        replaced = replaced.replaceAllMapped(
          RegExp(r'(^|\n)(\s*)([-*]\s)(?![\[○●])'),
          (m) {
            final indent = m.group(2) ?? '';
            final glyph = getBulletForIndent(indent.length);
            return '${m.group(1)}$indent$glyph ';
          },
        );
      }
      if (replaced != currentText) {
        _previousText = replaced;
        final newOffset = math.min(
          replaced.length,
          math.max(0, sel.isValid ? sel.start + (replaced.length - currentText.length) : replaced.length),
        );
        value = TextEditingValue(
          text: replaced,
          selection: sel.isValid
              ? TextSelection.collapsed(offset: newOffset)
              : const TextSelection.collapsed(offset: -1),
        );
        _normalizeSpans();
        return;
      }
    }

    _reconcileLineStyles(_previousText, currentText);

    if (diff > 0) {
      // Text was inserted
      final insertPos = math.max(0, (sel.isValid ? sel.start : currentText.length) - diff);
      final insertEnd = insertPos + diff;

      // Adjust existing spans
      for (final span in spans) {
        if (span.start >= insertPos) {
          span.start += diff;
          span.end += diff;
        } else if (span.end >= insertPos) {
          span.end += diff;
        }
      }

      // If active styling is enabled at caret, apply it to the newly typed text
      if (activeBold || activeItalic || activeUnderline || activeStrikethrough) {
        spans.add(
          StyleSpan(
            start: insertPos,
            end: insertEnd,
            isBold: activeBold,
            isItalic: activeItalic,
            isUnderline: activeUnderline,
            isStrikethrough: activeStrikethrough,
          ),
        );
      }
    } else if (diff < 0) {
      // Text was deleted
      final delStart = sel.isValid ? sel.start : currentText.length;
      final delLength = diff.abs();
      final delEnd = delStart + delLength;

      final updatedSpans = <StyleSpan>[];
      for (final span in spans) {
        if (span.end <= delStart) {
          updatedSpans.add(span);
        } else if (span.start >= delEnd) {
          span.start -= delLength;
          span.end -= delLength;
          updatedSpans.add(span);
        } else {
          // Span intersects deleted region
          final newStart = span.start > delStart ? delStart : span.start;
          final newEnd = span.end > delEnd ? span.end - delLength : delStart;
          if (newEnd > newStart) {
            span.start = newStart;
            span.end = newEnd;
            updatedSpans.add(span);
          }
        }
      }
      spans = updatedSpans;
    }

    _previousText = currentText;
    _normalizeSpans();
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

    final checkMatch = RegExp(r'^(\s*)([○●]|(?:[-*•]\s*)?\[[ xX]\])\s*').firstMatch(currentLine);
    final bulletMatch = RegExp(r'^(\s*)([•◦▪]\s*|-\s*|\*\s*)').firstMatch(currentLine);
    final numMatch = RegExp(r'^(\s*)(\d+)\.\s*').firstMatch(currentLine);

    if (checkMatch != null) {
      final prefix = checkMatch.group(0)!;
      final rest = currentLine.substring(prefix.length).trim();
      final indent = checkMatch.group(1) ?? '';
      if (rest.isEmpty) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final replacement = '${newIndent}○ ';
          final newText = fullText.replaceRange(lineStart, lineStart + prefix.length, replacement);
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart + replacement.length),
          );
          return true;
        } else {
          final newText = fullText.replaceRange(lineStart, lineStart + prefix.length, '');
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      } else {
        final nextCheck = '\n${indent}○ ';
        final newText = fullText.replaceRange(pos, sel.end, nextCheck);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: pos + nextCheck.length),
        );
        return true;
      }
    } else if (bulletMatch != null) {
      final prefix = bulletMatch.group(0)!;
      final rest = currentLine.substring(prefix.length).trim();
      final indent = bulletMatch.group(1) ?? '';
      if (rest.isEmpty) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final newBullet = getBulletForIndent(newIndent.length);
          final replacement = '$newIndent$newBullet ';
          final newText = fullText.replaceRange(lineStart, lineStart + prefix.length, replacement);
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart + replacement.length),
          );
          return true;
        } else {
          final newText = fullText.replaceRange(lineStart, lineStart + prefix.length, '');
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      } else {
        final bulletChar = getBulletForIndent(indent.length);
        final nextBullet = '\n$indent$bulletChar ';
        final newText = fullText.replaceRange(pos, sel.end, nextBullet);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: pos + nextBullet.length),
        );
        return true;
      }
    } else if (numMatch != null) {
      final prefix = numMatch.group(0)!;
      final numVal = int.tryParse(numMatch.group(2) ?? '1') ?? 1;
      final rest = currentLine.substring(prefix.length).trim();
      final indent = numMatch.group(1) ?? '';
      if (rest.isEmpty) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final replacement = '$newIndent${numVal}. ';
          final newText = fullText.replaceRange(lineStart, lineStart + prefix.length, replacement);
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart + replacement.length),
          );
          return true;
        } else {
          final newText = fullText.replaceRange(lineStart, lineStart + prefix.length, '');
          value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
          return true;
        }
      } else {
        final nextNum = '\n$indent${numVal + 1}. ';
        final newText = fullText.replaceRange(pos, sel.end, nextNum);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: pos + nextNum.length),
        );
        return true;
      }
    } else if (lineStyle == BlockType.title ||
        lineStyle == BlockType.h1 ||
        lineStyle == BlockType.h2 ||
        lineStyle == BlockType.h3) {
      // Pressing enter on title or heading creates a new paragraph below
      final newText = fullText.replaceRange(pos, sel.end, '\n');
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + 1),
      );
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
    final transformedLines = <String>[];
    int deltaTotal = 0;
    int firstLineDelta = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final bulletMatch = RegExp(r'^(\s*)([•◦▪]|\*|-)\s*').firstMatch(line);
      final checkMatch = RegExp(r'^(\s*)([○●]|(?:[-*•]\s*)?\[[ xX]\])\s*').firstMatch(line);
      final numMatch = RegExp(r'^(\s*)(\d+)\.\s*').firstMatch(line);

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

      final lineDelta = newLine.length - line.length;
      if (i == 0) firstLineDelta = lineDelta;
      deltaTotal += lineDelta;
      transformedLines.add(newLine);
    }

    final newSelectedRegion = transformedLines.join('\n');
    final newText = fullText.replaceRange(lineStart, lineEnd, newSelectedRegion);

    // Update selection
    final TextSelection newSelection;
    if (sel.isCollapsed) {
      final newCaret = math.max(lineStart, math.min(newText.length, sel.start + firstLineDelta));
      newSelection = TextSelection.collapsed(offset: newCaret);
    } else {
      final newStart = math.max(0, math.min(newText.length, startPos + firstLineDelta));
      final newEnd = math.max(newStart, math.min(newText.length, endPos + deltaTotal));
      newSelection = TextSelection(baseOffset: newStart, extentOffset: newEnd);
    }

    // Adjust spans overlapping or following the transformed region
    if (deltaTotal != 0) {
      for (final span in spans) {
        if (span.start >= lineEnd) {
          span.start += deltaTotal;
          span.end += deltaTotal;
        } else if (span.end > lineStart) {
          span.end = math.max(span.start, span.end + deltaTotal);
        }
      }
    }

    value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );
    _normalizeSpans();
    notifyListeners();
    return true;
  }

  /// Handles Backspace key on bullet / list items:
  /// - If cursor is right after prefix on empty sub-bullet ('  ◦ '): outdents to '• '
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

    final checkMatch = RegExp(r'^(\s*)([○●]|(?:[-*•]\s*)?\[[ xX]\])\s*').firstMatch(currentLine);
    if (checkMatch != null) {
      final prefix = checkMatch.group(0)!;
      final prefixEnd = lineStart + prefix.length;
      final indent = checkMatch.group(1) ?? '';
      final rest = currentLine.substring(prefix.length);

      if (pos == prefixEnd) {
        if (indent.length >= 2) {
          final newIndent = indent.substring(2);
          final replacement = '$newIndent○ $rest';
          final newText = fullText.replaceRange(lineStart, nextNewline, replacement);
          final newCaret = lineStart + newIndent.length + 2;
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

    final bulletMatch = RegExp(r'^(\s*)([•◦▪]|\*|-)\s*').firstMatch(currentLine);
    if (bulletMatch != null) {
      final prefix = bulletMatch.group(0)!;
      final prefixEnd = lineStart + prefix.length;
      final indent = bulletMatch.group(1) ?? '';
      final rest = currentLine.substring(prefix.length);

      // Only intercept if cursor is at the prefix boundary (after the bullet + space)
      if (pos == prefixEnd) {
        if (indent.length >= 2) {
          // Outdent 1 level
          final newIndent = indent.substring(2);
          final newBullet = getBulletForIndent(newIndent.length);
          final replacement = '$newIndent$newBullet $rest';
          final newText = fullText.replaceRange(lineStart, nextNewline, replacement);
          final newCaret = lineStart + newIndent.length + 2;
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

  /// Applies a line prefix (e.g., '• ', '○ ', '> ') across current selection or line
  void applyLinePrefix(String prefix) {
    final sel = selection;
    final fullText = text;
    final startPos = sel.isValid ? math.min(sel.start, sel.end) : fullText.length;
    final endPos = sel.isValid ? math.max(sel.start, sel.end) : fullText.length;

    final lineStart = fullText.lastIndexOf('\n', math.max(0, startPos - 1)) + 1;
    int lineEnd = fullText.indexOf('\n', endPos);
    if (lineEnd == -1) lineEnd = fullText.length;

    final selectedRegion = fullText.substring(lineStart, lineEnd);
    final lines = selectedRegion.split('\n');

    final prefixRegex = RegExp(r'^(#+\s*|[•○●◦▪]\s*|[-*]\s*|\[[ xX]\]\s*|\d+\.\s*|>\s*)');
    final transformedLines = <String>[];

    for (final line in lines) {
      final withoutPrefix = line.replaceFirst(prefixRegex, '');
      if (prefix.isEmpty) {
        transformedLines.add(withoutPrefix);
      } else {
        if (line.startsWith(prefix)) {
          transformedLines.add(withoutPrefix);
        } else {
          transformedLines.add('$prefix$withoutPrefix');
        }
      }
    }

    final newRegion = transformedLines.join('\n');
    final diff = newRegion.length - selectedRegion.length;
    final newText = fullText.replaceRange(lineStart, lineEnd, newRegion);

    for (final s in spans) {
      if (s.start >= lineEnd) {
        s.start += diff;
        s.end += diff;
      }
    }

    value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + newRegion.length,
      ),
    );
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
    final matchUnchecked = RegExp(r'^(\s*)(?:○|\[ \])\s*').firstMatch(line);
    final matchChecked = RegExp(r'^(\s*)(?:●|\[[xX]\])\s*').firstMatch(line);

    if (matchUnchecked != null) {
      final indent = matchUnchecked.group(1) ?? '';
      final rest = line.substring(matchUnchecked.group(0)!.length);
      final newLine = '$indent● $rest';
      final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: math.min(newText.length, pos)),
      );
      notifyListeners();
    } else if (matchChecked != null) {
      final indent = matchChecked.group(1) ?? '';
      final rest = line.substring(matchChecked.group(0)!.length);
      final newLine = '$indent○ $rest';
      final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: math.min(newText.length, pos)),
      );
      notifyListeners();
    } else {
      applyLinePrefix('○ ');
    }
  }

  /// Toggles checklist ○ <-> ● if click occurred within checkbox prefix
  bool toggleChecklistAtOffset(int charOffset) {
    if (charOffset < 0 || charOffset > text.length) return false;
    final now = DateTime.now();
    if (_lastToggleTime != null && now.difference(_lastToggleTime!).inMilliseconds < 250) {
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
    final matchUnchecked = RegExp(r'^(\s*)(?:○|\[ \])\s*').firstMatch(line);
    final matchChecked = RegExp(r'^(\s*)(?:●|\[[xX]\])\s*').firstMatch(line);

    if (matchUnchecked != null) {
      final prefixLen = matchUnchecked.group(0)!.length;
      if (charOffset <= lineStart + prefixLen + 1) {
        _lastToggleTime = now;
        final indent = matchUnchecked.group(1) ?? '';
        final rest = line.substring(prefixLen);
        final newLine = '$indent● $rest';
        final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: math.min(newText.length, lineStart + prefixLen)),
        );
        notifyListeners();
        return true;
      }
    } else if (matchChecked != null) {
      final prefixLen = matchChecked.group(0)!.length;
      if (charOffset <= lineStart + prefixLen + 1) {
        _lastToggleTime = now;
        final indent = matchChecked.group(1) ?? '';
        final rest = line.substring(prefixLen);
        final newLine = '$indent○ $rest';
        final newText = fullText.replaceRange(lineStart, lineEnd, newLine);
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: math.min(newText.length, lineStart + prefixLen)),
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
      final le = (i + 1 < lineStarts.length) ? lineStarts[i + 1] - 1 : rawText.length;
      final lineStr = rawText.substring(ls, le);
      final trimmed = lineStr.trimLeft();
      final circleMatch = RegExp(r'^([○●])(\s*)').firstMatch(trimmed);
      final checkMatch = RegExp(r'^((?:[-*•]\s*)?\[[ xX]\]\s*)').firstMatch(trimmed);
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
    final tagRegex = RegExp(r'(?<=^|[\s\(\[\{])#([a-zA-Z0-9_\-]+)');
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
      final lineEnd = (lineIdx + 1 < lineStarts.length) ? lineStarts[lineIdx + 1] - 1 : rawText.length;
      final lineStr = rawText.substring(lineStart, lineEnd);
      final trimmedLine = lineStr.trimLeft();

      TextStyle segStyle = effectiveBase;

      final bool isDark = Theme.of(context).brightness == Brightness.dark;

      final lineStyle = getLineStyle(lineIdx);
      final bool isTitle = lineStyle == BlockType.title;
      final bool isH1 = lineStyle == BlockType.h1 || trimmedLine.startsWith('# ');
      final bool isH2 = lineStyle == BlockType.h2 || trimmedLine.startsWith('## ');
      final bool isH3 = lineStyle == BlockType.h3 || trimmedLine.startsWith('### ');

      final bool isCircleUnchecked = trimmedLine.startsWith('○');
      final bool isCircleChecked = trimmedLine.startsWith('●');
      final bool isChecklistChecked = isCircleChecked || RegExp(r'^([-*•]\s*)?\[[xX]\]\s*').hasMatch(trimmedLine);

      final checkMatch = RegExp(r'^((?:[-*•]\s*)?\[[ xX]\]\s*)').firstMatch(trimmedLine);
      final indentLen = lineStr.length - trimmedLine.length;
      final bool isLegacyPrefixSegment = checkMatch != null && (segEnd <= lineStart + indentLen + checkMatch.group(0)!.length);
      final bool isQuote = trimmedLine.startsWith('> ');
      final bool isCode = trimmedLine.startsWith('```');

      // Authentic Apple circular checkbox rendering in continuous text stream
      if (isCircleChecked && segStart == lineStart + indentLen && segEnd == lineStart + indentLen + 1) {
        children.add(
          TextSpan(
            text: String.fromCharCode(CupertinoIcons.checkmark_circle_fill.codePoint),
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
      if (isCircleUnchecked && segStart == lineStart + indentLen && segEnd == lineStart + indentLen + 1) {
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
      } else if (isChecklistChecked && (!isCircleChecked || segStart >= lineStart + indentLen + 2)) {
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

      final bool isTag = RegExp(r'^#([a-zA-Z0-9_\-]+)$').hasMatch(segText);
      if (isTag && !isCode) {
        final tagColor = isDark ? const Color(0xFFEBA625) : const Color(0xFF965F00);
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
          decoration: TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]),
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

