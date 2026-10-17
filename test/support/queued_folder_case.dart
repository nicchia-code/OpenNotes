import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_sync_cloud.dart';

const queuedFolderUserId = '66666666-6666-4666-8666-666666666666';

Map<String, dynamic> _cloudFolder(DateTime updatedAt) => {
      'id': 'folder-1',
      'user_id': queuedFolderUserId,
      'name': 'Nome cloud',
      'parent_id': null,
      'icon': 'folder',
      'is_system': false,
      'created_at': DateTime.utc(2026, 10, 1, 8).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'purged_at': null,
    };

/// A device that saw the folder in the cloud, then the cloud changes it at [cloudUpdatedAt] and the device renames it
/// offline at [renamedAt]: the rename stays queued. Runs one sync run afterwards with [sync].
Future<({FakeSyncCloud cloud, DatabaseService db, SyncService sync})> setUpQueuedFolderCase(
  HttpServer server, {
  required DateTime cloudUpdatedAt,
  required DateTime renamedAt,
}) async {
  SharedPreferences.setMockInitialValues(signedInPreferences(queuedFolderUserId));
  final cloud = FakeSyncCloud(server);
  cloud.putFolder(_cloudFolder(DateTime.utc(2026, 10, 1, 7)));
  final dbService = DatabaseService();
  await dbService.init(inMemory: true);
  final tempDir = await Directory.systemTemp.createTemp('sync_folder_queued_send_vault_');
  addTearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });
  final vaultService = VaultService();
  await vaultService.init(customPath: tempDir.path);
  final syncService = SyncService(dbService, vaultService);
  addTearDown(syncService.dispose);

  await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
  for (var i = 0; i < 300 && (cloud.folderReads == 0 || syncService.isSyncing); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(syncService.isAuthenticated, isTrue);

  cloud.putFolder(_cloudFolder(cloudUpdatedAt));
  final renamed = Folder(
    id: 'folder-1',
    name: 'Rinominata offline',
    createdAt: DateTime.utc(2026, 10, 1, 8),
    updatedAt: renamedAt,
  );
  await dbService.upsertFolder(renamed);
  await dbService.queueSyncAction(
    entityType: 'folder',
    entityId: renamed.id,
    action: 'upsert',
    payload: jsonEncode(renamed.toSupabaseJson(queuedFolderUserId)),
  );
  return (cloud: cloud, db: dbService, sync: syncService);
}
