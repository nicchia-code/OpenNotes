import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Own file: the Supabase client is a process-wide singleton bound to the first test's server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a folder deleted in the cloud keeps its queued rename: the next sync sends it and recreates the folder', () async {
    const userId = '11111111-1111-4111-8111-111111111111';

    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final folderUpserts = <dynamic>[];
    var foldersGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      if (request.uri.path == '/rest/v1/rpc/push_folder' && request.method == 'POST') {
        folderUpserts.add((jsonDecode(body) as Map<String, dynamic>)['p_folder']);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'accepted', 'revision': folderUpserts.length}));
      } else if (request.uri.path == '/rest/v1/folders' && request.method == 'GET') {
        // The cloud no longer has folder-1.
        foldersGets++;
        request.response.headers.contentType = ContentType.json;
        request.response.write('[]');
      } else if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        request.response.write('[]');
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });

    final expiresAt = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    SharedPreferences.setMockInitialValues({
      'sb-127-auth-token': jsonEncode({
        'access_token': 'test-access',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': expiresAt,
        'refresh_token': 'test-refresh',
        'user': {
          'id': userId,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'test@example.com',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2024-01-01T00:00:00Z',
        },
      }),
    });

    Future<void> waitUntil(bool Function() condition) async {
      for (var i = 0; i < 300 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_queued_folder_drop_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    // Realtime path: the delete arrives while a rename is still queued for the folder.
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'folder-2', name: 'Vecchio', createdAt: now, updatedAt: now));
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: 'folder-2',
      action: 'upsert',
      payload: jsonEncode(Folder(id: 'folder-2', name: 'Nuovo', createdAt: now, updatedAt: now)
          .toSupabaseJson(userId)),
    );
    await syncService.handleRemoteFolderChange(PostgresChangePayload(
      schema: 'public',
      table: 'folders',
      commitTimestamp: DateTime.utc(2026, 10, 2),
      eventType: PostgresChangeEvent.delete,
      newRecord: const {},
      oldRecord: const {'id': 'folder-2'},
      errors: null,
    ));
    expect((await dbService.getFolders()).where((f) => f.id == 'folder-2'), isEmpty);
    expect(await dbService.getPendingSyncActions(), hasLength(1),
        reason: 'the queued rename of a folder deleted in the cloud is kept, to be sent at the next sync');

    // Sync path: the folder is gone here, but a rename queued before the delete reached this device.
    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => foldersGets > 0 && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: 'folder-1',
      action: 'upsert',
      payload: jsonEncode(Folder(id: 'folder-1', name: 'Rinominata', createdAt: now, updatedAt: now)
          .toSupabaseJson(userId)),
    );
    await syncService.syncNow();

    expect(folderUpserts.map((u) => u['name']), containsAll(['Nuovo', 'Rinominata']),
        reason: 'queued folder renames are always sent, overwriting the cloud copies');
    expect(folderUpserts.map((u) => u['id']), contains('folder-2'));
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });
}
