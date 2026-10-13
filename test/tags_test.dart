import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/ui/notes_list/note_card.dart';
import 'package:open_notes/core/services/database_service.dart';

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

    test('extractTagsFromContent reads tags of plain text that looks like a JSON list of non-objects', () {
      const text = '["progetto #lavoro"]';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, ['lavoro']);
    });

    test('extractTagsFromContent deduplicates and lowercases tags', () {
      const text = 'Work on #Flutter and #FLUTTER and #flutter today.';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, ['flutter']);
    });

    test('extractTagsFromContent keeps accented letters in tags', () {
      const text = 'Una #perché e #città, poi #Ñandú.';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, ['città', 'perché', 'ñandú']);
      expect(Note.isOnlyTags('#perché #città'), isTrue);
    });

    test('extractTagsFromContent extracts tags written in non-Latin alphabets', () {
      const text = 'Ciao #привет, #γεια e #日本 ma #café sì.';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, ['café', 'γεια', 'привет', '日本']);
      expect(Note.isOnlyTags('#привет #γεια'), isTrue);
      expect(Note.isOnlyTags('#привет'), isTrue);
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

  group('Tag filter tests', () {
    Future<DatabaseService> openWith(List<Map<String, Object?>> rows) async {
      final service = DatabaseService();
      await service.init(inMemory: true);
      await service.db.delete('notes');
      for (final row in rows) {
        await service.db.insert('notes', {
          'folder_id': 'notes',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
          ...row,
        });
      }
      return service;
    }

    test('tag filter does not match a longer tag starting the same way', () async {
      final service = await openWith([
        {'id': 'short', 'title': 'Short', 'content': 'Riunione', 'tags': '["lavoro"]'},
        {'id': 'long', 'title': 'Long', 'content': 'Solo #lavorobis', 'tags': '["lavorobis"]'},
      ]);
      final notes = await service.getNotes(tag: 'lavoro');
      expect(notes.map((n) => n.id), ['short']);
    });

    test('tag filter ignores hashtags written only in content', () async {
      final service = await openWith([
        {'id': 'saved', 'title': 'Saved', 'content': '#lavoro', 'tags': '["lavoro"]'},
        {'id': 'stale', 'title': 'Stale', 'content': 'Ho scritto #lavoro', 'tags': '[]'},
      ]);
      final notes = await service.getNotes(tag: 'lavoro');
      expect(notes.map((n) => n.id), ['saved']);
    });

    test('tag list counts saved tags only, matching the filter', () async {
      final service = await openWith([
        {'id': 'saved', 'title': 'Saved', 'content': '#lavoro', 'tags': '["lavoro"]'},
        {'id': 'stale', 'title': 'Stale', 'content': 'Ho scritto #lavoro', 'tags': '[]'},
      ]);
      final tags = await service.getAllTags();
      expect(tags.map((t) => (t.name, t.count)), [('lavoro', 1)]);
      expect((await service.getNotes(tag: 'lavoro')).map((n) => n.id), ['saved']);
    });

    test('tag filter matches stored tags with accented capitals', () async {
      final service = await openWith([
        {'id': 'stored', 'title': 'Stored', 'content': '', 'tags': '["Città"]'},
        {'id': 'written', 'title': 'Written', 'content': 'Vado in #Città', 'tags': '[]'},
        {'id': 'other', 'title': 'Other', 'content': '', 'tags': '["città-bis"]'},
      ]);
      final tags = await service.getAllTags();
      expect(tags.map((t) => t.name), contains('città'));
      final notes = await service.getNotes(tag: 'città');
      expect(notes.map((n) => n.id), ['stored']);
    });

    test('tag filter treats underscore literally, not as a wildcard', () async {
      final service = await openWith([
        {'id': 'underscore', 'title': 'Underscore', 'content': '', 'tags': '["a_b"]'},
        {'id': 'other', 'title': 'Other', 'content': '', 'tags': '["axb"]'},
      ]);
      final notes = await service.getNotes(tag: 'a_b');
      expect(notes.map((n) => n.id), ['underscore']);
    });

    test('text search treats _ and % literally, not as wildcards', () async {
      final service = await openWith([
        {'id': 'literal', 'title': 'a_b', 'content': '', 'tags': '[]'},
        {'id': 'other', 'title': 'axb', 'content': '100% vero', 'tags': '[]'},
        {'id': 'percent', 'title': 'Note', 'content': '100% vero', 'tags': '[]'},
      ]);
      expect((await service.getNotes(searchQuery: 'a_b')).map((n) => n.id), ['literal']);
      expect((await service.getNotes(searchQuery: '100%')).map((n) => n.id), unorderedEquals(['other', 'percent']));
    });

    test('text search matches accented capitals with lowercase query', () async {
      final service = await openWith([
        {'id': 'cap', 'title': 'Titolo', 'content': 'Qui È il punto', 'tags': '[]'},
      ]);
      final notes = await service.getNotes(searchQuery: 'è');
      expect(notes.map((n) => n.id), ['cap']);
    });

    test('text search matches content of locked notes without unlocking', () async {
      final service = await openWith([
        {'id': 'secret', 'title': 'Diario', 'content': 'parola segreta', 'tags': '["privato"]', 'is_locked': 1},
        {'id': 'open', 'title': 'Aperta', 'content': 'parola segreta', 'tags': '[]'},
      ]);
      expect(
        (await service.getNotes(searchQuery: 'segreta')).map((n) => n.id),
        unorderedEquals(['secret', 'open']),
      );
      expect((await service.getNotes(searchQuery: 'diario')).map((n) => n.id), ['secret']);
      expect((await service.getNotes(searchQuery: 'privato')).map((n) => n.id), isEmpty);
    });

    test('list orders by instant when local and UTC modification dates are mixed', () async {
      final service = await openWith([
        {'id': 'cloud_older', 'title': 'A', 'content': '', 'tags': '[]', 'updated_at': '2026-03-01T10:00:00.000Z'},
        {'id': 'local_newer', 'title': 'B', 'content': '', 'tags': '[]', 'updated_at': DateTime.utc(2026, 3, 1, 11).toLocal().toIso8601String()},
        {'id': 'cloud_newest', 'title': 'C', 'content': '', 'tags': '[]', 'updated_at': '2026-03-01T12:00:00.000Z'},
        {'id': 'pinned_old', 'title': 'D', 'content': '', 'tags': '[]', 'is_pinned': 1, 'updated_at': '2026-01-01T00:00:00.000Z'},
      ]);
      final notes = await service.getNotes();
      expect(notes.map((n) => n.id), ['pinned_old', 'cloud_newest', 'local_newer', 'cloud_older']);
    });
  });
}
