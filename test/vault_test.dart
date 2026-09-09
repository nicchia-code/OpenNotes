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

    test('extractTagsFromContent finds hashtags properly', () {
      const text = 'Nota importante con #apple e #markdown e #todo2026.';
      final tags = Note.extractTagsFromContent(text);
      expect(tags, containsAll(['apple', 'markdown', 'todo2026']));
    });

    test('serializeNoteToMarkdown and parseMarkdownFile roundtrip works', () {
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

      final parsed = VaultService.parseMarkdownFile(markdown, '/dummy/path/note.md').note;
      expect(parsed.id, 'test-uuid-1234');
      expect(parsed.title, 'Apple Notes Clone');
      expect(parsed.isPinned, isTrue);
      expect(parsed.isLocked, isFalse);
      expect(parsed.tags, containsAll(['apple', 'test']));
    });
  });
}
