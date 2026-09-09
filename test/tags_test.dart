import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/ui/notes_list/note_card.dart';

void main() {
  group('Tags extraction tests', () {
    test('extractTagsFromContent extracts simple, hyphenated, and underscored tags', () {
      const text = 'Testing #flutter, #open-notes, and #tag_3 in note body.';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, ['flutter', 'open-notes', 'tag_3']);
    });

    test('extractTagsFromContent ignores markdown headings with spaces', () {
      const text = '''
# Heading 1
## Heading 2
### Heading 3
Just some normal text here.
''';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, isEmpty);
    });

    test('extractTagsFromContent extracts tags mixed with markdown headings', () {
      const text = '''
# Project Overview
This project uses #dart and #flutter for cross-platform desktop.
## Next Steps
- Implement #sqlite sync
''';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, ['dart', 'flutter', 'sqlite']);
    });

    test('extractTagsFromContent parses JSON document blocks and tables', () {
      final blocks = [
        {
          'id': 'b1',
          'type': 'paragraph',
          'text': 'Meeting notes with #team and #design',
        },
        {
          'id': 'b2',
          'type': 'checklist',
          'text': 'Fix critical issue #urgent',
          'checked': false,
        },
        {
          'id': 'b3',
          'type': 'table',
          'text': '',
          'tableData': [
            ['Task', 'Tag'],
            ['Audit', '#security'],
            ['Release', '#deploy'],
          ],
        }
      ];

      final jsonContent = jsonEncode(blocks);
      final tags = Note.extractTagsFromContent(jsonContent);
      expect(tags, ['deploy', 'design', 'security', 'team', 'urgent']);
    });

    test('extractTagsFromContent deduplicates and lowercases tags', () {
      const text = 'Work on #Flutter and #FLUTTER and #flutter today.';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, ['flutter']);
    });
  });

  group('NoteCard tags display tests', () {
    testWidgets('renders tag chips on NoteCard', (WidgetTester tester) async {
      final note = Note(
        id: 'note-tags-1',
        title: 'Tagged Note',
        content: 'Content with #dev #mobile',
        tags: ['dev', 'mobile'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: NoteCard(
              note: note,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('#dev'), findsOneWidget);
      expect(find.text('#mobile'), findsOneWidget);
    });

    testWidgets('renders overflow badge when note has more than 3 tags', (WidgetTester tester) async {
      final note = Note(
        id: 'note-tags-2',
        title: 'Many Tags Note',
        content: 'Content with many tags',
        tags: ['one', 'two', 'three', 'four', 'five'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: NoteCard(
              note: note,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('#one'), findsOneWidget);
      expect(find.text('#two'), findsOneWidget);
      expect(find.text('#three'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('#four'), findsNothing);
      expect(find.text('#five'), findsNothing);
    });

    testWidgets('tapping tag chip triggers onTagTap callback with tag name', (WidgetTester tester) async {
      String? tappedTag;
      final note = Note(
        id: 'note-tags-3',
        title: 'Clickable Tag Note',
        content: 'Content with #flutter',
        tags: ['flutter'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: NoteCard(
              note: note,
              isSelected: false,
              onTap: () {},
              onTagTap: (tag) => tappedTag = tag,
            ),
          ),
        ),
      );

      await tester.tap(find.text('#flutter'));
      await tester.pump();
      expect(tappedTag, 'flutter');
    });
  });
}
