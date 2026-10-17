import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';

const _noteId = 'note-deleted-here';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late SyncService syncService;
  late Directory tempDir;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.init(inMemory: true);
    tempDir = await Directory.systemTemp.createTemp('sync_queued_note_tie_');
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    syncService = SyncService(dbService, vaultService);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // Note deleted offline: the delete is queued. Returns the time the delete entered the queue.
  Future<DateTime> queueNoteDelete() async {
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertNote(Note(id: _noteId, title: 'Eliminata', content: '', createdAt: now, updatedAt: now));
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: _noteId,
      action: 'delete',
      payload: jsonEncode({'id': _noteId}),
    );
    return (await dbService.pendingDeleteQueuedAt('note', _noteId))!;
  }

  Note cloudCopy(DateTime updatedAt) => Note(
        id: _noteId,
        title: 'Copia del cloud',
        content: '',
        createdAt: DateTime.utc(2026, 10, 1, 9),
        updatedAt: updatedAt,
        cloudRevision: 7,
      );

  test('a cloud note made at the same time as a queued note delete replaces the note', () async {
    final queuedAt = await queueNoteDelete();

    final applied = await syncService.applyRemoteNote(cloudCopy(queuedAt));

    expect(applied, isTrue, reason: 'a tie goes to the cloud');
    expect((await dbService.getNoteById(_noteId))?.title, 'Copia del cloud');
    expect(await dbService.hasPendingSyncAction(entityType: 'note', entityId: _noteId, action: 'delete'), isFalse,
        reason: 'the cloud copy drops the queued delete');
  });

  test('a cloud note older than a queued note delete leaves the note deleted', () async {
    final queuedAt = await queueNoteDelete();

    final applied = await syncService.applyRemoteNote(cloudCopy(queuedAt.subtract(const Duration(minutes: 1))));

    expect(applied, isFalse, reason: 'the queued delete is newer than the cloud copy');
    expect(await dbService.hasPendingSyncAction(entityType: 'note', entityId: _noteId, action: 'delete'), isTrue,
        reason: 'the queued delete is kept');
  });
}
