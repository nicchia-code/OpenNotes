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

  test('a queued folder delete is dropped when the cloud changed the folder later', () async {
    const userId = '22222222-2222-4222-8222-222222222222';
    const folderId = 'folder-changed-in-cloud';
    // Far in the future, so it is always later than the delete queued below.
    final cloudFolder = {
      'id': folderId,
      'user_id': userId,
      'name': 'Modificata nel cloud',
      'parent_id': null,
      'icon': 'folder',
      'is_system': false,
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2999-01-01T00:00:00.000Z',
    };

    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final folderDeletes = <String>[];
    var foldersGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final isFolders = request.uri.path == '/rest/v1/folders';
      final wantsObject =
          (request.headers.value('accept') ?? '').contains('vnd.pgrst.object');
      if (isFolders && request.method == 'DELETE') {
        folderDeletes.add(request.uri.toString());
        request.response.statusCode = 204;
      } else if (isFolders && request.method == 'GET') {
        foldersGets++;
        request.response.headers.contentType = ContentType.json;
        if (wantsObject) {
          request.response.write(jsonEncode(cloudFolder));
        } else {
          request.response.write(jsonEncode([cloudFolder]));
        }
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
    final tempDir = await Directory.systemTemp.createTemp('sync_folder_delete_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => foldersGets > 0 && !syncService.isSyncing);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);

    // The folder was deleted offline: the delete sits in the queue, the folder is gone locally.
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: folderId, name: 'Vecchia', createdAt: now, updatedAt: now));
    await dbService.deleteFolder(folderId);
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: folderId,
      action: 'delete',
      payload: jsonEncode({'id': folderId}),
    );

    await syncService.syncNow();

    expect(folderDeletes, isEmpty, reason: 'the cloud changed the folder after the delete');
    final restored = (await dbService.getFolders()).where((f) => f.id == folderId);
    expect(restored, hasLength(1), reason: 'the pull brings the cloud folder back');
    expect(restored.single.name, 'Modificata nel cloud');
  });
}
