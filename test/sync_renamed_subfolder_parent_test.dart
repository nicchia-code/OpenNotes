import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Own file: the Supabase client is a process-wide singleton bound to the first test's server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a queued rename of a subfolder whose parent was deleted is sent top-level and the sync completes', () async {
    const userId = '11111111-1111-4111-8111-111111111111';

    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    // Cloud rows as the server keeps them: the child lost its parent when the parent was deleted (foreign key set null).
    final cloudFolders = <String, Map<String, dynamic>>{
      'child': {
        'id': 'child',
        'user_id': userId,
        'name': 'Figlia',
        'parent_id': null,
        'icon': 'folder',
        'is_system': false,
        'created_at': '2026-10-01T09:00:00.000Z',
        'updated_at': '2026-10-01T09:00:00.000Z',
      },
    };
    final folderUpserts = <Map<String, dynamic>>[];
    var foldersGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      if (request.uri.path == '/rest/v1/rpc/push_folder' && request.method == 'POST') {
        final row = Map<String, dynamic>.from((jsonDecode(body) as Map)['p_folder'] as Map);
        final parentId = row['parent_id'] as String?;
        if (parentId != null && !cloudFolders.containsKey(parentId)) {
          // Foreign key violation: the parent does not exist in the cloud.
          request.response.statusCode = 409;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'code': '23503',
            'message': 'insert or update violates foreign key constraint "folders_parent_id_fkey"',
            'details': null,
            'hint': null,
          }));
        } else {
          folderUpserts.add(row);
          cloudFolders[row['id'] as String] = row;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'status': 'accepted', 'revision': folderUpserts.length}));
        }
      } else if (request.uri.path == '/rest/v1/folders' && request.method == 'GET') {
        foldersGets++;
        final idFilter = request.uri.queryParameters['id'];
        final rows = idFilter == null
            ? cloudFolders.values.toList()
            : cloudFolders.values.where((r) => 'eq.${r['id']}' == idFilter).toList();
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(rows));
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
    final tempDir = await Directory.systemTemp.createTemp('sync_renamed_subfolder_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    final now = DateTime.utc(2026, 10, 1, 9);
    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => foldersGets > 0 && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);

    // Local: the parent was deleted here; the subfolder keeps its parent until the next sync.
    await dbService.upsertFolder(Folder(id: 'child', name: 'Rinominata', parentId: 'gone', createdAt: now, updatedAt: now));
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: 'child',
      action: 'upsert',
      payload: jsonEncode(Folder(id: 'child', name: 'Rinominata', parentId: 'gone', createdAt: now, updatedAt: now)
          .toSupabaseJson(userId)),
    );
    folderUpserts.clear();
    expect((await dbService.getFolders()).singleWhere((f) => f.id == 'child').parentId, 'gone',
        reason: 'the device keeps the parent until the sync');

    await syncService.syncNow();

    expect(folderUpserts.map((u) => u['name']), contains('Rinominata'),
        reason: 'the queued rename is sent, not refused by the foreign key on the deleted parent');
    expect(folderUpserts.single['parent_id'], isNull, reason: 'the cloud subfolder is top-level');
    expect(await dbService.getPendingSyncActions(), isEmpty, reason: 'the queue is drained, the sync completes');
    final local = (await dbService.getFolders()).singleWhere((f) => f.id == 'child');
    expect(local.parentId, isNull, reason: 'the next sync makes the subfolder top-level on the device too');
  });
}
