import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '33333333-3333-4333-8333-333333333333';

// A cloud row as the realtime channel delivers it; a deleted row is a placeholder with `purged_at` set.
Map<String, dynamic> _cloudNote({
  required String id,
  required String title,
  required String updatedAt,
  String? purgedAt,
}) =>
    {
      'id': id,
      'user_id': _userId,
      'title': title,
      'content': '',
      'folder_id': 'notes',
      'tags': <String>[],
      'is_pinned': false,
      'is_locked': false,
      'is_deleted': false,
      'deleted_at': null,
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': updatedAt,
      'purged_at': purgedAt,
    };

PostgresChangePayload _update(String table, Map<String, dynamic> record) => PostgresChangePayload(
      schema: 'public',
      table: table,
      commitTimestamp: DateTime.utc(2999),
      eventType: PostgresChangeEvent.update,
      newRecord: record,
      oldRecord: const {},
      errors: null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late Directory tempDir;
  late SyncService syncService;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.init(inMemory: true);
    tempDir = await Directory.systemTemp.createTemp('sync_realtime_removal_vault_');
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    // No cloud is configured here: the realtime handlers only touch the local database and vault.
    syncService = SyncService(dbService, vaultService);
  });

  tearDown(() async {
    syncService.dispose();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('a note deleted in the cloud is removed with its queued changes, and the removal is announced', () async {
    final synced = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertNote(
      Note(id: 'gone-note', title: 'Eliminata altrove', content: '', createdAt: synced, updatedAt: synced)
          .copyWith(syncedAt: synced),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'gone-note',
      action: 'upsert',
      payload: jsonEncode({'id': 'gone-note'}),
    );
    final announced = <RemoteChange>[];
    final subscription = syncService.remoteChanges.listen(announced.add);
    addTearDown(subscription.cancel);

    await syncService.handleRemoteNoteChange(_update(
      'notes',
      _cloudNote(
        id: 'gone-note',
        title: 'Eliminata altrove',
        updatedAt: '2026-10-02T09:00:00.000Z',
        purgedAt: '2026-10-02T09:00:00.000Z',
      ),
    ));

    expect(await dbService.getNoteById('gone-note'), isNull);
    expect(await dbService.getPendingSyncActions(), isEmpty, reason: 'the queued changes of a removed note are discarded');
    await Future<void>.delayed(Duration.zero);
    expect(announced.single, isA<CloudNoteRemoved>());
  });

  test('a queued change made after the cloud delete keeps the note, and the change still waits to be sent', () async {
    final edited = DateTime.utc(2026, 10, 3, 9);
    await dbService.upsertNote(
      Note(id: 'edited-note', title: 'Modificata offline', content: '', createdAt: edited, updatedAt: edited),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'edited-note',
      action: 'upsert',
      payload: jsonEncode({'id': 'edited-note'}),
    );

    await syncService.handleRemoteNoteChange(_update(
      'notes',
      _cloudNote(
        id: 'edited-note',
        title: 'Eliminata altrove',
        updatedAt: '2026-10-02T09:00:00.000Z',
        purgedAt: '2026-10-02T09:00:00.000Z',
      ),
    ));

    expect(await dbService.getNoteById('edited-note'), isNotNull);
    expect(
      await dbService.hasPendingSyncAction(entityType: 'note', entityId: 'edited-note', action: 'upsert'),
      isTrue,
    );
  });

  test('a cloud copy newer than the local one replaces it and drops the older queued changes of the note', () async {
    final local = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertNote(
      Note(id: 'shared-note', title: 'Locale', content: '', createdAt: local, updatedAt: local)
          .copyWith(syncedAt: local),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'shared-note',
      action: 'upsert',
      payload: jsonEncode({'id': 'shared-note'}),
    );

    await syncService.handleRemoteNoteChange(_update(
      'notes',
      _cloudNote(id: 'shared-note', title: 'Dal cloud', updatedAt: '2026-10-02T09:00:00.000Z'),
    ));

    expect((await dbService.getNoteById('shared-note'))?.title, 'Dal cloud');
    expect(await dbService.getPendingSyncActions(), isEmpty,
        reason: 'sending the older local version would overwrite the cloud copy');
  });

  test('a folder deleted in the cloud arrives as a placeholder and is removed locally', () async {
    final created = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'gone-folder', name: 'Lavoro', createdAt: created, updatedAt: created));

    await syncService.handleRemoteFolderChange(_update('folders', {
      'id': 'gone-folder',
      'user_id': _userId,
      'name': 'Lavoro',
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2026-10-02T09:00:00.000Z',
      'purged_at': '2026-10-02T09:00:00.000Z',
    }));

    expect(await dbService.getFolderById('gone-folder'), isNull);
  });

  test('a queued edit newer than the cloud copy keeps the local copy, and the edit still waits to be sent', () async {
    final edited = DateTime.utc(2026, 10, 3, 9);
    await dbService.upsertNote(
      Note(id: 'newer-edit', title: 'Modifica locale', content: '', createdAt: edited, updatedAt: edited)
          .copyWith(syncedAt: edited, cloudRevision: 5),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'newer-edit',
      action: 'upsert',
      payload: jsonEncode({'id': 'newer-edit'}),
    );

    final stored = await syncService.applyRemoteNote(Note.fromSupabaseJson({
      ..._cloudNote(id: 'newer-edit', title: 'Dal cloud', updatedAt: '2026-10-02T09:00:00.000Z'),
      'revision': 6,
    }));

    expect(stored, isFalse);
    expect((await dbService.getNoteById('newer-edit'))?.title, 'Modifica locale');
    expect(await dbService.hasPendingSyncAction(entityType: 'note', entityId: 'newer-edit', action: 'upsert'), isTrue);
  });

  test('a trashed note deleted in the cloud is removed too', () async {
    final created = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertNote(
      Note(id: 'trashed-gone', title: 'Nel cestino', content: '', createdAt: created, updatedAt: created, isDeleted: true)
          .copyWith(syncedAt: created),
    );

    await syncService.handleRemoteNoteChange(_update(
      'notes',
      _cloudNote(
        id: 'trashed-gone',
        title: 'Nel cestino',
        updatedAt: '2026-10-02T09:00:00.000Z',
        purgedAt: '2026-10-02T09:00:00.000Z',
      ),
    ));

    expect(await dbService.getNoteById('trashed-gone'), isNull);
  });

  test('a cloud folder change stores the cloud revision on the device', () async {
    final created = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'renamed-folder', name: 'Vecchio', createdAt: created, updatedAt: created));

    await syncService.handleRemoteFolderChange(_update('folders', {
      'id': 'renamed-folder',
      'user_id': _userId,
      'name': 'Nuovo',
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2026-10-02T09:00:00.000Z',
      'revision': 9,
    }));

    final folder = await dbService.getFolderById('renamed-folder');
    expect(folder?.name, 'Nuovo');
    expect(folder?.cloudRevision, 9);
  });

  test('a delete placeholder on a revision the device already has does not remove the note', () async {
    final synced = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertNote(
      Note(id: 'known-revision', title: 'Versione nota', content: '', createdAt: synced, updatedAt: synced)
          .copyWith(syncedAt: synced, cloudRevision: 5),
    );

    await syncService.handleRemoteNoteChange(_update(
      'notes',
      {
        ..._cloudNote(
          id: 'known-revision',
          title: 'Versione nota',
          updatedAt: '2026-10-02T09:00:00.000Z',
          purgedAt: '2026-10-02T09:00:00.000Z',
        ),
        'revision': 3,
      },
    ));

    expect((await dbService.getNoteById('known-revision'))?.title, 'Versione nota');
  });

  test('a folder delete placeholder on a revision the device already has does not remove the folder', () async {
    final created = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(
      Folder(id: 'known-folder', name: 'Lavoro', createdAt: created, updatedAt: created).copyWith(cloudRevision: 5),
    );

    await syncService.handleRemoteFolderChange(_update('folders', {
      'id': 'known-folder',
      'user_id': _userId,
      'name': 'Lavoro',
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2026-10-02T09:00:00.000Z',
      'purged_at': '2026-10-02T09:00:00.000Z',
      'revision': 3,
    }));

    expect(await dbService.getFolderById('known-folder'), isNotNull);
  });
}
