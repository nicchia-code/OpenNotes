import 'dart:math' as math;

import '../../core/models/note_model.dart';
import '../../core/models/style_span.dart';
import 'rich_text_editing_controller.dart';

/// A text part divided where a pasted image goes.
///
/// [before] keeps the text above the image, [after] the text below it. Both
/// keep their character spans and line styles, already re-based on their own
/// text.
class TextPartSplit {
  const TextPartSplit({
    required this.before,
    required this.beforeSpans,
    required this.beforeLineStyles,
    required this.after,
    required this.afterSpans,
    required this.afterLineStyles,
  });

  final String before;
  final List<StyleSpan> beforeSpans;
  final Map<int, BlockType> beforeLineStyles;
  final String after;
  final List<StyleSpan> afterSpans;
  final Map<int, BlockType> afterLineStyles;
}

/// Follows an offset of [oldText] into [newText] after an edit.
///
/// Edits before the offset move it, edits after it leave it alone, and an
/// offset inside the edited region goes to the start of that region.
int mapOffsetThroughEdit(String oldText, String newText, int offset) {
  if (oldText == newText) {
    return math.min(math.max(offset, 0), newText.length);
  }
  final limit = math.min(oldText.length, newText.length);
  var prefix = 0;
  while (prefix < limit &&
      oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < limit - prefix &&
      oldText.codeUnitAt(oldText.length - 1 - suffix) ==
          newText.codeUnitAt(newText.length - 1 - suffix)) {
    suffix++;
  }
  final oldEnd = oldText.length - suffix;
  final mapped = offset <= prefix
      ? offset
      : offset >= oldEnd
      ? offset + newText.length - oldText.length
      : prefix;
  return math.min(math.max(mapped, 0), newText.length);
}

/// Divides [text] where an image is pasted over the selection [start]..[end].
///
/// The selected text is removed. When the point is in the middle of a line,
/// the line is split: the part below the image starts a new line whose
/// marker follows the Enter rules (checklist, bullet and numbered items
/// continue, while headings, quotes, code and body lines become body text).
/// Otherwise at most one line break is removed at the division: the one that
/// closes the text above, or else the one that opens the text below.
TextPartSplit splitTextPartForImage({
  required String text,
  required List<StyleSpan> spans,
  required Map<int, BlockType> lineStyles,
  required int start,
  required int end,
}) {
  var from = math.min(math.max(start, 0), text.length);
  var to = math.min(math.max(end, from), text.length);

  final lineStart = _lineStartOf(text, from);
  final lineEnd = _lineEndOf(text, to);
  final lineText = text.substring(lineStart, lineEnd);
  final lineIndex = _lineIndexOf(text, from);
  final marker = _markerOf(
    lineText,
    plainLine: _isPlainLine(lineStyles[lineIndex]),
  );
  final sameLine = !text.substring(from, to).contains('\n');

  var midLine = sameLine && from > lineStart && to < lineEnd;
  if (midLine &&
      marker.prefixLength > 0 &&
      from < lineStart + marker.prefixLength) {
    // A point inside the marker of a list item goes right after the marker.
    from = lineStart + marker.prefixLength;
    to = math.max(to, from);
    midLine = to < lineEnd;
  }

  var before = text.substring(0, from);
  var after = text.substring(to);
  var afterStart = to;
  var firstLine = _lineIndexOf(text, to);
  var insertedMarker = '';
  BlockType? firstLineStyle;

  if (midLine) {
    insertedMarker = marker.nextMarker;
    firstLineStyle = marker.nextStyle;
  } else if (before.endsWith('\n')) {
    before = before.substring(0, before.length - 1);
  } else if (after.startsWith('\n')) {
    after = after.substring(1);
    afterStart = to + 1;
    firstLine = firstLine + 1;
  }

  final beforeLastLine = '\n'.allMatches(before).length;
  final beforeLineStyles = <int, BlockType>{
    for (final entry in lineStyles.entries)
      if (entry.key <= beforeLastLine) entry.key: entry.value,
  };
  final afterLineStyles = <int, BlockType>{
    for (final entry in lineStyles.entries)
      if (entry.key >= firstLine) entry.key - firstLine: entry.value,
  };
  if (midLine) {
    afterLineStyles.remove(0);
    if (firstLineStyle != null) {
      afterLineStyles[0] = firstLineStyle;
    }
  }

  final beforeSpans = <StyleSpan>[
    for (final span in spans)
      if (span.start < before.length && span.end > span.start)
        span.copyWith(end: math.min(span.end, before.length)),
  ];
  final shift = insertedMarker.length - afterStart;
  final afterSpans = <StyleSpan>[
    for (final span in spans)
      if (span.end > afterStart && span.start < text.length)
        span.copyWith(
          start: math.max(span.start, afterStart) + shift,
          end: math.min(span.end, text.length) + shift,
        ),
  ];

  return TextPartSplit(
    before: before,
    beforeSpans: beforeSpans,
    beforeLineStyles: beforeLineStyles,
    after: insertedMarker + after,
    afterSpans: afterSpans,
    afterLineStyles: afterLineStyles,
  );
}

bool _isPlainLine(BlockType? style) {
  return style == BlockType.title ||
      style == BlockType.h1 ||
      style == BlockType.h2 ||
      style == BlockType.h3 ||
      style == BlockType.quote ||
      style == BlockType.code;
}

int _lineStartOf(String text, int offset) {
  if (offset == 0) return 0;
  return text.lastIndexOf('\n', offset - 1) + 1;
}

int _lineEndOf(String text, int offset) {
  final newline = text.indexOf('\n', offset);
  return newline == -1 ? text.length : newline;
}

int _lineIndexOf(String text, int offset) {
  return '\n'.allMatches(text.substring(0, offset)).length;
}

/// Marker of a line split in its middle, following the Enter rules.
class _LineMarker {
  const _LineMarker({
    required this.prefixLength,
    required this.nextMarker,
    this.nextStyle,
  });

  /// Length of the marker already on the line, which a split keeps above.
  final int prefixLength;

  /// Marker that the part below the image starts with.
  final String nextMarker;

  /// Line style of the part below the image, when it is not body text.
  final BlockType? nextStyle;
}

_LineMarker _markerOf(String line, {required bool plainLine}) {
  const none = _LineMarker(prefixLength: 0, nextMarker: '');
  if (plainLine) {
    return none;
  }
  final checkMatch = RegExp(
    r'^(\s*)([○●]|(?:[-*•]\s*)?\[[ xX]\](?=\s))\s*',
  ).firstMatch(line);
  final bulletMatch = RegExp(r'^(\s*)([•◦▪]|-|\*)\s+').firstMatch(line);
  final numMatch = RegExp(r'^(\s*)(\d+)\.\s+').firstMatch(line);

  if (checkMatch != null) {
    final indent = checkMatch.group(1) ?? '';
    return _LineMarker(
      prefixLength: checkMatch.group(0)!.length,
      nextMarker: '$indent○ ',
    );
  }
  if (bulletMatch != null) {
    final indent = bulletMatch.group(1) ?? '';
    return _LineMarker(
      prefixLength: bulletMatch.group(0)!.length,
      nextMarker:
          '$indent${RichTextEditingController.getBulletForIndent(indent.length)} ',
    );
  }
  if (numMatch != null) {
    final indent = numMatch.group(1) ?? '';
    final number = int.tryParse(numMatch.group(2) ?? '1') ?? 1;
    return _LineMarker(
      prefixLength: numMatch.group(0)!.length,
      nextMarker: '$indent${number + 1}. ',
      nextStyle: BlockType.numbered,
    );
  }
  return none;
}
