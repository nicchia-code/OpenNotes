import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late SyncService syncService;
  late Directory tempDir;
  const userId = '55555555-5555-4555-8555-555555555555';
  final cloudAt = DateTime.utc(2026, 10, 1, 9);
  final localAt = DateTime.utc(2026, 10, 1, 10);

  setUp(() async {
    dbService = DatabaseService();
    await dbService.init(inMemory: true);
    tempDir = await Directory.systemTemp.createTemp('sync_folder_newer_local_vault_');
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    syncService = SyncService(dbService, vaultService);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  PostgresChangePayload folderChange(PostgresChangeEvent event, Map<String, dynamic> record) => PostgresChangePayload(
        schema: 'public',
        table: 'folders',
        commitTimestamp: DateTime.utc(2026, 10, 2),
        eventType: event,
        newRecord: event == PostgresChangeEvent.delete ? const {} : record,
        oldRecord: event == PostgresChangeEvent.delete ? record : const {},
        errors: null,
      );

  Map<String, dynamic> cloudFolder({required String id, required String name, required DateTime updatedAt}) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'parent_id': null,
        'icon': 'folder',
        'is_system': false,
        'created_at': cloudAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Future<void> queueRename(Folder folder) => dbService.queueSyncAction(
        entityType: 'folder',
        entityId: folder.id,
        action: 'upsert',
        payload: jsonEncode(folder.toSupabaseJson(userId)),
      );

  test('a cloud version older than a queued rename does not overwrite it, and the rename stays queued', () async {
    final renamed = Folder(id: 'folder-1', name: 'Rinominata', createdAt: cloudAt, updatedAt: localAt);
    await dbService.upsertFolder(renamed);
    await queueRename(renamed);

    await syncService.handleRemoteFolderChange(folderChange(
      PostgresChangeEvent.update,
      cloudFolder(id: 'folder-1', name: 'Nel cloud', updatedAt: cloudAt),
    ));

    expect((await dbService.getFolderById('folder-1'))!.name, 'Rinominata');
    expect(await dbService.hasPendingSyncAction(entityType: 'folder', entityId: 'folder-1', action: 'upsert'), isTrue);
  });

  test('a newer cloud version replaces the folder and drops the older queued rename', () async {
    final renamed = Folder(id: 'folder-1', name: 'Rinominata', createdAt: cloudAt, updatedAt: cloudAt);
    await dbService.upsertFolder(renamed);
    await queueRename(renamed);

    await syncService.handleRemoteFolderChange(folderChange(
      PostgresChangeEvent.update,
      cloudFolder(id: 'folder-1', name: 'Nel cloud', updatedAt: localAt.add(const Duration(hours: 1))),
    ));

    expect((await dbService.getFolderById('folder-1'))!.name, 'Nel cloud');
    expect(await dbService.getPendingSyncActions(), isEmpty,
        reason: 'the queued rename is older than the cloud version and must not overwrite it');
  });

  test('a cloud deletion keeps the folder when a queued rename is newer than the cloud version', () async {
    final renamed = Folder(id: 'folder-1', name: 'Rinominata', createdAt: cloudAt, updatedAt: localAt);
    await dbService.upsertFolder(renamed);
    await queueRename(renamed);

    await syncService.handleRemoteFolderChange(folderChange(
      PostgresChangeEvent.delete,
      cloudFolder(id: 'folder-1', name: 'Nel cloud', updatedAt: cloudAt),
    ));

    expect((await dbService.getFolderById('folder-1'))!.name, 'Rinominata');
    expect(await dbService.hasPendingSyncAction(entityType: 'folder', entityId: 'folder-1', action: 'upsert'), isTrue);
  });

  test('a cloud deletion removes the folder and moves its notes to Notes without queuing them', () async {
    final folder = Folder(id: 'folder-1', name: 'Eliminata altrove', createdAt: cloudAt, updatedAt: cloudAt);
    await dbService.upsertFolder(folder);
    await dbService.upsertNote(Note(
      id: 'note-1',
      title: 'Nota',
      content: '',
      folderId: 'folder-1',
      createdAt: cloudAt,
      updatedAt: cloudAt,
    ).copyWith(syncedAt: cloudAt));

    await syncService.handleRemoteFolderChange(folderChange(
      PostgresChangeEvent.delete,
      cloudFolder(id: 'folder-1', name: 'Eliminata altrove', updatedAt: cloudAt),
    ));

    expect(await dbService.getFolderById('folder-1'), isNull);
    expect((await dbService.getNoteById('note-1'))!.folderId, Folder.defaultNotesId);
    expect(await dbService.getPendingSyncActions(), isEmpty, reason: 'the move to Notes is not queued');
  });

  test('a cloud folder at or below the stored revision is ignored, whatever its update time', () async {
    await dbService.upsertFolder(Folder(
      id: 'folder-rev',
      name: 'Locale',
      createdAt: cloudAt,
      updatedAt: localAt,
      cloudRevision: 5,
    ));

    await syncService.handleRemoteFolderChange(folderChange(
      PostgresChangeEvent.update,
      {...cloudFolder(id: 'folder-rev', name: 'Eco', updatedAt: localAt.add(const Duration(hours: 1))), 'revision': 5},
    ));
    expect((await dbService.getFolderById('folder-rev'))!.name, 'Locale');

    await syncService.handleRemoteFolderChange(folderChange(
      PostgresChangeEvent.update,
      {...cloudFolder(id: 'folder-rev', name: 'Nel cloud', updatedAt: localAt), 'revision': 6},
    ));
    final stored = await dbService.getFolderById('folder-rev');
    expect(stored!.name, 'Nel cloud');
    expect(stored.cloudRevision, 6);
  });
}
