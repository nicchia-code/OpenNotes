import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton bound to the first test's server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a queued folder delete carries only its id and the placeholder keeps the cloud name', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    const userId = '77777777-7777-4777-8777-777777777777';
    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final cloud = FakeSyncCloud(server);
    cloud.putFolder({
      'id': 'folder-del',
      'user_id': userId,
      'name': 'Nome cloud',
      'parent_id': null,
      'icon': 'folder',
      'is_system': false,
      'created_at': DateTime.utc(2026, 10, 1, 8).toIso8601String(),
      'updated_at': DateTime.utc(2026, 10, 1, 7).toIso8601String(),
      'purged_at': null,
    });

    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_folder_delete_name_');
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

    final now = DateTime.utc(2026, 10, 1, 9);
    final folder = Folder(id: 'folder-del', name: 'Locale', createdAt: now, updatedAt: now);
    await dbService.upsertFolder(folder);
    await dbService.deleteFolder('folder-del');
    await syncService.notifyFolderChanged(folder, isDelete: true);

    final queued = await dbService.getPendingSyncActions();
    expect(queued, hasLength(1));
    expect(jsonDecode(queued.single['payload'] as String), {'id': 'folder-del'});

    await syncService.syncNow();

    final placeholder = cloud.folders['folder-del']!;
    expect(placeholder['name'], 'Nome cloud', reason: 'the name is read from the cloud copy when sent');
    expect(placeholder['purged_at'], isNotNull, reason: 'the cloud keeps a deletion placeholder');
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });
}
