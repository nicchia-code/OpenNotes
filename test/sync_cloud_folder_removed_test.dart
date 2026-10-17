import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Own file: the Supabase client is a process-wide singleton bound to the first test's server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a full sync removes a synced folder the cloud lacks; its notes move to Notes unqueued', () async {
    const userId = '44444444-4444-4444-8444-444444444444';
    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    // The cloud keeps 'cloud-folder' and whatever is pushed to it; 'gone-folder' is local only now.
    final cloudFolders = <String, Map<String, dynamic>>{
      'cloud-folder': {
        'id': 'cloud-folder',
        'user_id': userId,
        'name': 'Nel cloud',
        'parent_id': null,
        'icon': 'folder',
        'is_system': false,
        'created_at': '2026-10-01T09:00:00.000Z',
        'updated_at': '2026-10-01T09:00:00.000Z',
      },
    };
    var foldersGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final isFolders = request.uri.path == '/rest/v1/folders';
      if (request.uri.path == '/rest/v1/rpc/push_folder' && request.method == 'POST') {
        final row = (jsonDecode(body) as Map<String, dynamic>)['p_folder'] as Map<String, dynamic>;
        cloudFolders[row['id'] as String] = row;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'accepted', 'revision': 1}));
      } else if (isFolders && request.method == 'GET') {
        foldersGets++;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(cloudFolders.values.toList()));
      } else if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        // The note of the removed folder is still in the cloud, with its folder id: the full note check keeps it.
        request.response.write(jsonEncode([
          {
            'id': 'gone-note',
            'user_id': userId,
            'title': 'Nota nella cartella eliminata',
            'content': '',
            'folder_id': 'gone-folder',
            'tags': <String>[],
            'is_pinned': false,
            'is_locked': false,
            'is_deleted': false,
            'deleted_at': null,
            'created_at': '2026-10-01T09:00:00.000Z',
            'updated_at': '2026-10-01T09:00:00.000Z',
            'purged_at': null,
          },
        ]));
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
    final tempDir = await Directory.systemTemp.createTemp('sync_cloud_folder_removed_vault_');
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

    // Local state: 'gone-folder' is no longer in the cloud (deleted elsewhere while offline), and holds a
    // synced note. 'renamed-folder' was created offline, so its creation is still queued.
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'gone-folder', name: 'Eliminata altrove', createdAt: now, updatedAt: now));
    await dbService.upsertNote(Note(
      id: 'gone-note',
      title: 'Nota nella cartella eliminata',
      content: '',
      folderId: 'gone-folder',
      createdAt: now,
      updatedAt: now,
    ).copyWith(syncedAt: now));
    final renamed = Folder(id: 'renamed-folder', name: 'Creata offline', createdAt: now, updatedAt: now);
    await dbService.upsertFolder(renamed);
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: renamed.id,
      action: 'upsert',
      payload: jsonEncode(renamed.toSupabaseJson(userId)),
    );

    await waitUntil(() => !syncService.isSyncing);
    await syncService.syncNow();

    final folderIds = (await dbService.getFolders()).map((f) => f.id).toList();
    expect(folderIds, containsAll(['notes', 'cloud-folder', 'renamed-folder']));
    expect(folderIds, isNot(contains('gone-folder')), reason: 'a synced folder the cloud no longer has is removed');
    expect((await dbService.getNoteById('gone-note'))!.folderId, Folder.defaultNotesId);
    expect(await dbService.hasPendingSyncAction(entityType: 'note', entityId: 'gone-note'), isFalse,
        reason: 'the move to Notes is not queued');
    expect(cloudFolders.containsKey('renamed-folder'), isTrue, reason: 'a queued creation is sent, not dropped');
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });
}
