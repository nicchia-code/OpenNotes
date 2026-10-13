import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';

void main() {
  test('cloud payloads send dates as UTC instants with the zone suffix', () {
    final local = DateTime(2026, 10, 12, 10);
    final utc = local.toUtc().toIso8601String();
    expect(utc, endsWith('Z'));

    final note = Note(
      id: 'note-1',
      title: 'Nota',
      content: '',
      createdAt: local,
      updatedAt: local,
      deletedAt: local,
    ).toSupabaseJson('user-1');
    expect(note['created_at'], utc);
    expect(note['updated_at'], utc);
    expect(note['deleted_at'], utc);

    final folder = Folder(id: 'folder-1', name: 'Cartella', createdAt: local, updatedAt: local)
        .toSupabaseJson('user-1');
    expect(folder['created_at'], utc);
    expect(folder['updated_at'], utc);
  });

  test('notes read from cloud or database get updatedAt in local time', () {
    const stored = '2026-10-12T08:30:00Z';
    final instant = DateTime.parse(stored);

    final fromCloud = Note.fromSupabaseJson({
      'id': 'note-1',
      'content': '',
      'created_at': stored,
      'updated_at': stored,
    });
    expect(fromCloud.updatedAt.isUtc, isFalse);
    expect(fromCloud.updatedAt.isAtSameMomentAs(instant), isTrue);
    expect(fromCloud.updatedAt.hour, instant.toLocal().hour);

    final fromDb = Note.fromMap({
      'id': 'note-1',
      'content': '',
      'created_at': stored,
      'updated_at': stored,
    });
    expect(fromDb.updatedAt.isUtc, isFalse);
    expect(fromDb.updatedAt.isAtSameMomentAs(instant), isTrue);
    expect(fromDb.updatedAt.hour, instant.toLocal().hour);
  });
}
