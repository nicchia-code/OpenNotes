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

  test('a save the cloud refuses for a folder it no longer has drops the folder with every newer queued change',
      () async {
    const userId = '55555555-5555-4555-8555-555555555555';
    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final cloudFolders = <String, Map<String, dynamic>>{};
    var vanishedPushes = 0;
    // Runs while the cloud is answering the push of 'vanished-folder': a newer change of that folder is queued meanwhile.
    Future<void> Function()? changeWhileRefused;
    var foldersGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      if (request.uri.path == '/rest/v1/rpc/push_folder' && body.contains('"id":"vanished-folder"')) {
        // The cloud has no row for the folder: the answer carries no row, as for a folder deleted there.
        vanishedPushes++;
        await changeWhileRefused?.call();
        changeWhileRefused = null;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'conflict', 'row': null}));
      } else if (request.uri.path == '/rest/v1/rpc/push_folder' && request.method == 'POST') {
        final row = (jsonDecode(body) as Map<String, dynamic>)['p_folder'] as Map<String, dynamic>;
        cloudFolders[row['id'] as String] = row;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'accepted', 'revision': 1}));
      } else if (request.uri.path == '/rest/v1/folders' && request.method == 'GET') {
        foldersGets++;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(cloudFolders.values.toList()));
      } else if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(<Map<String, dynamic>>[]));
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
    final tempDir = await Directory.systemTemp.createTemp('sync_refused_folder_gone_vault_');
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

    // Local state: 'vanished-folder' was synced (it has a cloud revision) and then renamed, and the rename is queued.
    // While the cloud answers that rename, a newer rename is queued too.
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(
      id: 'vanished-folder',
      name: 'Sparita',
      createdAt: now,
      updatedAt: now,
      cloudRevision: 2,
    ));
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: 'vanished-folder',
      action: 'upsert',
      payload: jsonEncode(Folder(id: 'vanished-folder', name: 'Rinominata', createdAt: now, updatedAt: now)
          .toSupabaseJson(userId)),
    );
    final newer = now.add(const Duration(minutes: 1));
    changeWhileRefused = () => dbService.queueSyncAction(
          entityType: 'folder',
          entityId: 'vanished-folder',
          action: 'upsert',
          payload: jsonEncode(Folder(id: 'vanished-folder', name: 'Più recente', createdAt: now, updatedAt: newer)
              .toSupabaseJson(userId)),
        );

    await syncService.syncNow();

    expect(vanishedPushes, 1, reason: 'the refused save is not sent again, nor the newer change');
    expect((await dbService.getFolders()).map((f) => f.id), isNot(contains('vanished-folder')),
        reason: 'the folder leaves the device');
    expect(await dbService.getPendingSyncActions(), isEmpty,
        reason: 'the newer queued change of the folder is dropped with it');
    expect(cloudFolders.containsKey('vanished-folder'), isFalse);

    await syncService.syncNow();

    expect(vanishedPushes, 1);
    expect((await dbService.getFolders()).map((f) => f.id), isNot(contains('vanished-folder')),
        reason: 'the next sync does not recreate the folder');
    expect(cloudFolders.containsKey('vanished-folder'), isFalse);
  });
}
