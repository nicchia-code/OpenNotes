import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/models/style_span.dart';
import 'package:open_notes/ui/editor/rich_text_editing_controller.dart';
import 'package:open_notes/ui/editor/text_part_split.dart';

List<(int, int)> _ranges(List<StyleSpan> spans) => [
  for (final span in spans) (span.start, span.end),
];

void main() {
  group('splitTextPartForImage', () {
    test('divides the text at a point inside a line keeping both parts', () {
      final split = splitTextPartForImage(
        text: 'hello world',
        spans: const [],
        lineStyles: const {},
        start: 5,
        end: 5,
      );
      expect(split.before, 'hello');
      expect(split.after, ' world');
    });

    test('removes the selected text between the two parts', () {
      final split = splitTextPartForImage(
        text: 'hello world',
        spans: const [],
        lineStyles: const {},
        start: 5,
        end: 6,
      );
      expect(split.before, 'hello');
      expect(split.after, 'world');
    });

    test('removes only the line break closing the text above', () {
      final split = splitTextPartForImage(
        text: 'abc\ndef',
        spans: const [],
        lineStyles: const {},
        start: 4,
        end: 4,
      );
      expect(split.before, 'abc');
      expect(split.after, 'def');
    });

    test('removes the line break opening the text below when at line end', () {
      final split = splitTextPartForImage(
        text: 'abc\ndef',
        spans: const [],
        lineStyles: const {},
        start: 3,
        end: 3,
      );
      expect(split.before, 'abc');
      expect(split.after, 'def');
    });

    test('re-indexes line styles of the text below the image', () {
      final split = splitTextPartForImage(
        text: 'one\ntwo\nthree',
        spans: const [],
        lineStyles: const {0: BlockType.h1, 2: BlockType.h2},
        start: 4,
        end: 4,
      );
      expect(split.before, 'one');
      expect(split.beforeLineStyles, {0: BlockType.h1});
      expect(split.after, 'two\nthree');
      expect(split.afterLineStyles, {1: BlockType.h2});
    });

    test('moves character spans to the part they belong to', () {
      final split = splitTextPartForImage(
        text: 'hello world',
        spans: [StyleSpan(start: 3, end: 8, isBold: true)],
        lineStyles: const {},
        start: 5,
        end: 5,
      );
      expect(_ranges(split.beforeSpans), [(3, 5)]);
      expect(_ranges(split.afterSpans), [(0, 3)]);
      expect(split.afterSpans.single.isBold, isTrue);
    });

    test('continues a checklist item in the middle of its text', () {
      final split = splitTextPartForImage(
        text: '○ buy milk',
        spans: const [],
        lineStyles: const {},
        start: 6,
        end: 6,
      );
      expect(split.before, '○ buy ');
      expect(split.after, '○ milk');
    });

    test('continues a bullet item in the middle of its text', () {
      final bullet = RichTextEditingController.getBulletForIndent(0);
      final split = splitTextPartForImage(
        text: '- one two',
        spans: const [],
        lineStyles: const {},
        start: 6,
        end: 6,
      );
      expect(split.before, '- one ');
      expect(split.after, '$bullet two');
    });

    test('numbers the next item in the middle of a numbered line', () {
      final split = splitTextPartForImage(
        text: '2. alpha beta',
        spans: const [],
        lineStyles: const {0: BlockType.numbered},
        start: 9,
        end: 9,
      );
      expect(split.before, '2. alpha ');
      expect(split.after, '3. beta');
      expect(split.afterLineStyles, {0: BlockType.numbered});
    });

    test('turns a heading split in its middle into body text', () {
      final split = splitTextPartForImage(
        text: 'Title here',
        spans: const [],
        lineStyles: const {0: BlockType.h1},
        start: 5,
        end: 5,
      );
      expect(split.before, 'Title');
      expect(split.beforeLineStyles, {0: BlockType.h1});
      expect(split.after, ' here');
      expect(split.afterLineStyles, isEmpty);
    });

    test('keeps a split point inside a list marker after the marker', () {
      final split = splitTextPartForImage(
        text: '○ buy milk',
        spans: const [],
        lineStyles: const {},
        start: 1,
        end: 1,
      );
      expect(split.before, '○ ');
      expect(split.after, '○ buy milk');
    });
  });

  group('mapOffsetThroughEdit', () {
    test('moves an offset after an edit made before it', () {
      expect(mapOffsetThroughEdit('ab cd', 'XX ab cd', 5), 8);
    });

    test('keeps an offset before an edit made after it', () {
      expect(mapOffsetThroughEdit('ab cd', 'ab cd XX', 2), 2);
    });

    test('puts an offset inside a removed region at its start', () {
      expect(mapOffsetThroughEdit('abcdef', 'abef', 3), 2);
    });

    test('keeps an offset unchanged when the text is the same', () {
      expect(mapOffsetThroughEdit('abc', 'abc', 2), 2);
    });
  });
}
