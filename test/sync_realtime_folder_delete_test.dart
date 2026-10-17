import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _folderId = 'folder-deleted-here';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late SyncService syncService;
  late Directory tempDir;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.init(inMemory: true);
    tempDir = await Directory.systemTemp.createTemp('sync_realtime_folder_delete_');
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    syncService = SyncService(dbService, vaultService);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // Deleted offline: the delete is queued. Returns the time the delete entered the queue.
  Future<DateTime> queueFolderDelete() async {
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: _folderId, name: 'Vecchia', createdAt: now, updatedAt: now));
    await dbService.deleteFolder(_folderId);
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: _folderId,
      action: 'delete',
      payload: jsonEncode({'id': _folderId}),
    );
    return (await dbService.pendingDeleteQueuedAt('folder', _folderId))!;
  }

  // A cloud copy of the folder arriving over the realtime channel, last modified at [updatedAt].
  Future<void> receiveCloudFolder(DateTime updatedAt) => syncService.handleRemoteFolderChange(PostgresChangePayload(
        schema: 'public',
        table: 'folders',
        commitTimestamp: DateTime.utc(2999, 1, 1),
        eventType: PostgresChangeEvent.update,
        newRecord: {
          'id': _folderId,
          'user_id': '22222222-2222-4222-8222-222222222222',
          'name': 'Modificata nel cloud',
          'parent_id': null,
          'icon': 'folder',
          'is_system': false,
          'created_at': '2026-10-01T09:00:00.000Z',
          'updated_at': updatedAt.toUtc().toIso8601String(),
          'revision': 99,
        },
        oldRecord: const {},
        errors: null,
      ));

  test('a realtime cloud copy made at the same time as a queued folder delete brings the folder back', () async {
    final queuedAt = await queueFolderDelete();

    await receiveCloudFolder(queuedAt);

    final restored = await dbService.getFolderById(_folderId);
    expect(restored?.name, 'Modificata nel cloud', reason: 'a tie goes to the cloud');
    expect(await dbService.getPendingSyncDeleteTime('folder', _folderId), isNull,
        reason: 'the cloud copy replaces the queued delete');
  });

  test('a realtime cloud copy older than a queued folder delete leaves the folder deleted', () async {
    final queuedAt = await queueFolderDelete();

    await receiveCloudFolder(queuedAt.subtract(const Duration(minutes: 1)));

    expect(await dbService.getFolderById(_folderId), isNull, reason: 'the queued delete is newer than the cloud copy');
    expect(await dbService.getPendingSyncDeleteTime('folder', _folderId), isNotNull, reason: 'the queued delete is kept');
  });

  test('a realtime cloud copy newer than a queued folder delete brings the folder back', () async {
    await queueFolderDelete();

    await receiveCloudFolder(DateTime.utc(2999, 1, 1));

    expect((await dbService.getFolderById(_folderId))?.name, 'Modificata nel cloud');
    expect(await dbService.getPendingSyncDeleteTime('folder', _folderId), isNull);
  });
}
