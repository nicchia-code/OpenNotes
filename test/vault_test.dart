import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/vault_service.dart';

void main() {
  group('VaultService & Note Model Tests', () {
    test('extractTitle gets clean title and ignores hashes', () {
      const content = '### Titolo di Prova\nQuesto è il corpo della nota.';
      final title = Note.extractTitle(content);
      expect(title, 'Titolo di Prova');
    });

    test('extractTitle gives a title block precedence over earlier text', () {
      const content =
          '[{"type":"paragraph","text":"Riga normale"},'
          '{"type":"title","text":"Titolo vero"}]';
      expect(Note.extractTitle(content), 'Titolo vero');
    });

    test('extractTitle falls back to first text block without a title', () {
      const content =
          '[{"type":"image","text":"img"},'
          '{"type":"paragraph","text":"#tag"},'
          '{"type":"paragraph","text":"Prima riga"}]';
      expect(Note.extractTitle(content), 'Prima riga');
    });

    test('extractTitle uses the first line of plain text starting with [', () {
      const content = '[Spesa] latte\nAltra riga';
      expect(Note.extractTitle(content), '[Spesa] latte');
      expect(Note.extractSnippet(content), 'Altra riga');
    });

    test('extractTitle uses the first line of plain text that parses as a JSON list', () {
      expect(Note.extractTitle('[]\nAltra riga'), '[]');
      expect(Note.extractTitle('[1]'), '[1]');
      expect(Note.extractSnippet('[1]\nAltra riga'), 'Altra riga');
    });

    test('extractSnippet reads a mixed list as plain text, not as blocks', () {
      const content = '[{"type":"paragraph","text":"Spesa"},1]\nlatte';
      expect(Note.extractSnippet(content), 'latte');
      expect(Note.extractSnippet('[{"text":"Spesa"},1]'), 'Nessun testo aggiuntivo');
    });

    test('extractTitle treats an empty block list as an untitled block document', () {
      expect(Note.extractTitle('[]'), 'Nuova nota');
      expect(Note.extractTitle('  []  '), 'Nuova nota');
      expect(Note.extractSnippet('[]'), 'Nessun testo aggiuntivo');
    });

    test('extractTitle clips to 60 characters, not code units', () {
      final emojis = '😀' * 61;
      expect(Note.extractTitle(emojis), '😀' * 60);
      expect(Note.extractTitle('😀' * 60), '😀' * 60);
    });

    test('extractTitle skips a block whose only text is hashes', () {
      const content =
          '[{"type":"paragraph","text":"#"},'
          '{"type":"paragraph","text":"Prima riga"}]';
      expect(Note.extractTitle(content), 'Prima riga');
      expect(Note.extractTitle('[{"type":"paragraph","text":"##"}]'), 'Nuova nota');
    });

    test('extractSnippet skips the first text block used as title', () {
      const content =
          '[{"type":"paragraph","text":"Spesa"},'
          '{"type":"paragraph","text":"latte"}]';
      expect(Note.extractTitle(content), 'Spesa');
      expect(Note.extractSnippet(content), 'latte');
    });

    test('toMarkdownBody omits the title line even when clipped or styled', () {
      final longTitle = 'A' * 70;
      final plain = Note(id: 'p', title: 'x', content: '## $longTitle\nCorpo', createdAt: DateTime(2026), updatedAt: DateTime(2026));
      expect(plain.toMarkdownBody(), 'Corpo');

      final blocks = Note(
        id: 'b',
        title: 'x', createdAt: DateTime(2026), updatedAt: DateTime(2026),
        content:
            '[{"type":"paragraph","text":"Titolo grassetto","spans":[{"start":0,"end":16,"bold":true}]},'
            '{"type":"paragraph","text":"Corpo"}]',
      );
      expect(blocks.toMarkdownBody(), 'Corpo');
    });

    test('toMarkdownBody keeps the other lines of a block whose first line is the title', () {
      final note = Note(
        id: 'm',
        title: 'x', createdAt: DateTime(2026), updatedAt: DateTime(2026),
        content:
            '[{"type":"paragraph","text":"Titolo\\nRiga due\\nTerza","spans":[{"start":12,"end":15,"bold":true}],"lineStyles":{"0":"title","1":"h2"}}]',
      );
      expect(note.toMarkdownBody(), '## Riga **due**\nTerza');
    });

    test('extractSnippet keeps a later h1 when the title is earlier text', () {
      const content =
          '[{"type":"paragraph","text":"Spesa"},'
          '{"type":"h1","text":"Sezione"},'
          '{"type":"paragraph","text":"latte"}]';
      expect(Note.extractSnippet(content), 'Sezione latte');
    });

    test('extractSnippet skips the title block when present', () {
      const content =
          '[{"type":"paragraph","text":"Riga normale"},'
          '{"type":"title","text":"Titolo vero"}]';
      expect(Note.extractSnippet(content), 'Riga normale');
    });

    test('extractSnippet of plain text starts after the title line', () {
      const content = 'Spesa\nlatte\n';
      expect(Note.extractSnippet(content), 'latte');
    });

    test('extractSnippet skips image blocks and shows the no-text message', () {
      const content =
          '[{"type":"paragraph","text":"Spesa"},'
          '{"type":"image","text":"attachments/att_1.png"},'
          '{"type":"paragraph","text":"latte"}]';
      expect(Note.extractSnippet(content), 'latte');
      const onlyImage =
          '[{"type":"paragraph","text":"Spesa"},'
          '{"type":"image","text":"attachments/att_1.png"}]';
      expect(Note.extractSnippet(onlyImage), 'Nessun testo aggiuntivo');
    });

    test('extractSnippet counts characters, so an emoji is one', () {
      final content = 'Titolo\n${'😀' * 90}\nxyz';
      expect(Note.extractSnippet(content), '${'😀' * 90} xyz');
    });

    test('extractTagsFromContent finds hashtags properly', () {
      const text = 'Nota importante con #apple e #markdown e #todo2026.';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, containsAll(['apple', 'markdown', 'todo2026']));
    });

    test('serializeNoteToMarkdown writes the metadata header and body', () {
      final now = DateTime.utc(2026, 9, 8, 12, 0, 0);
      final note = Note(
        id: 'test-uuid-1234',
        title: 'Apple Notes Clone',
        content: '# Apple Notes Clone\n\n- [x] Checklist item\n\nTesto di prova.',
        folderId: 'notes',
        tags: ['apple', 'test'],
        isPinned: true,
        isLocked: false,
        createdAt: now,
        updatedAt: now,
      );

      final markdown = VaultService.serializeNoteToMarkdown(note);
      expect(markdown, contains('---'));
      expect(markdown, contains('pinned: true'));
      expect(markdown, contains('test-uuid-1234'));
    });

    test('a renamed note writes a new file and leaves the old one in the vault', () async {
      final dir = Directory.systemTemp.createTempSync('vault_rename_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final now = DateTime.utc(2026, 10, 1, 9, 0, 0);
      var note = Note(
        id: 'rename-uuid-1234',
        title: 'Vecchio',
        content: 'versione uno',
        folderId: 'notes',
        tags: const [],
        isPinned: false,
        isLocked: false,
        createdAt: now,
        updatedAt: now,
      );
      final service = VaultService();

      note = note.copyWith(filePath: await service.saveNote(note, folderPath: dir.path));
      note = note.copyWith(title: 'Nuovo', content: 'versione due');
      note = note.copyWith(filePath: await service.saveNote(note, folderPath: dir.path));

      expect(File('${dir.path}/Vecchio.md').readAsStringSync(), contains('versione uno'));
      expect(File('${dir.path}/Nuovo.md').readAsStringSync(), contains('versione due'));
      expect(dir.listSync().length, 2);
    });

    test('a long title with emoji is cut to 50 characters, never splitting one', () async {
      final dir = await Directory.systemTemp.createTemp('vault_emoji_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final now = DateTime.utc(2026, 10, 1, 9, 0, 0);
      final note = Note(
        id: 'emoji-uuid-1234',
        title: '${'😀' * 49}😀x',
        content: 'corpo',
        folderId: 'notes',
        tags: const [],
        isPinned: false,
        isLocked: false,
        createdAt: now,
        updatedAt: now,
      );

      await VaultService().saveNote(note, folderPath: dir.path);

      final files = dir.listSync().whereType<File>().toList();
      expect(files.length, 1);
      expect(files.single.path.endsWith('${'😀' * 50}.md'), isTrue);
    });

    test('deleting a note removes the file it was written to', () async {
      final dir = await Directory.systemTemp.createTemp('vault_delete_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final now = DateTime.utc(2026, 10, 1, 9, 0, 0);
      var note = Note(
        id: 'delete-uuid-1234',
        title: 'Da cancellare',
        content: 'corpo',
        folderId: 'notes',
        tags: const [],
        isPinned: false,
        isLocked: false,
        createdAt: now,
        updatedAt: now,
      );
      final service = VaultService();
      note = note.copyWith(filePath: await service.saveNote(note, folderPath: dir.path));

      await service.deleteNoteFile(note.filePath);
      await service.deleteNoteFile(null);

      expect(File(note.filePath!).existsSync(), isFalse);
    });
  });
}
