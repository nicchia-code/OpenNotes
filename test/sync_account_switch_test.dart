import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Own file: the Supabase client is a process-wide singleton, so each scenario that
// points it at a fake cloud needs its own test process.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Account switch drops synced notes and discards their unsent changes, keeps folders', () async {
    const userId = '22222222-2222-4222-8222-222222222222';
    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    HttpOverrides.global = null;

    final upserts = <Map<String, dynamic>>[];
    final folderUpserts = <Map<String, dynamic>>[];
    var notesGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final isNotes = request.uri.path == '/rest/v1/notes';
      final isFolders = request.uri.path == '/rest/v1/folders';
      if (request.uri.path == '/rest/v1/rpc/push_note' && request.method == 'POST') {
        upserts.add((jsonDecode(body) as Map<String, dynamic>)['p_note'] as Map<String, dynamic>);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'accepted', 'revision': upserts.length}));
      } else if (request.uri.path == '/rest/v1/rpc/push_folder' && request.method == 'POST') {
        folderUpserts.add((jsonDecode(body) as Map<String, dynamic>)['p_folder'] as Map<String, dynamic>);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'accepted', 'revision': folderUpserts.length}));
      } else if ((isNotes || isFolders) && request.method == 'GET') {
        if (isNotes) notesGets++;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(isFolders ? folderUpserts : <Object>[]));
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
    final tempDir = await Directory.systemTemp.createTemp('sync_account_switch_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => notesGets > 0 && !syncService.isSyncing);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);

    // The device last synced with another account, which uploaded the note below.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_owner_id', '33333333-3333-4333-8333-333333333333');

    final oldSynced = Note(
      id: 'old-synced-1',
      title: 'Nota del precedente',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).copyWith(syncedAt: DateTime.now());
    await dbService.upsertNote(oldSynced);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: oldSynced.id,
      action: 'upsert',
      payload: jsonEncode(oldSynced.toSupabaseJson(userId)),
    );
    final newLocal = Note(
      id: 'new-local-1',
      title: 'Nota nuova',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await dbService.upsertNote(newLocal);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: newLocal.id,
      action: 'upsert',
      payload: jsonEncode(newLocal.toSupabaseJson(userId)),
    );
    final offlineFolder = Folder(
      id: 'offline-folder-1',
      name: 'Cartella offline',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await dbService.upsertFolder(offlineFolder);
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: offlineFolder.id,
      action: 'upsert',
      payload: jsonEncode(offlineFolder.toSupabaseJson(userId)),
    );
    // A note the device synced and then deleted for good before the switch: only its queued delete is left.
    final purgedSynced = Note(
      id: 'purged-synced-1',
      title: 'Nota eliminata',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      cloudRevision: 7,
    ).copyWith(syncedAt: DateTime.now());
    await dbService.upsertNote(purgedSynced);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: purgedSynced.id,
      action: 'delete',
      payload: jsonEncode({'id': purgedSynced.id}),
    );
    await dbService.deleteNoteRow(purgedSynced.id);
    // A note never synced and deleted for good before the switch: its delete is still sent.
    final purgedUnsynced = Note(
      id: 'purged-unsynced-1',
      title: 'Nota mai sincronizzata',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await dbService.upsertNote(purgedUnsynced);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: purgedUnsynced.id,
      action: 'delete',
      payload: jsonEncode({'id': purgedUnsynced.id}),
    );
    await dbService.deleteNoteRow(purgedUnsynced.id);

    await waitUntil(() => !syncService.isSyncing);
    await syncService.syncNow();

    expect(await dbService.getNoteById('old-synced-1'), isNull);
    expect(upserts.map((u) => u['id']), unorderedEquals(['new-local-1', 'purged-unsynced-1']));
    final pending = await dbService.getPendingSyncActions();
    expect(pending.where((a) => a['entity_id'] == 'old-synced-1'), isEmpty);
    expect(pending.where((a) => a['entity_id'] == 'purged-synced-1'), isEmpty);
    expect((await dbService.getFolders()).map((f) => f.id), contains('offline-folder-1'));
    expect(folderUpserts.map((f) => f['id']), ['offline-folder-1']);
    expect(pending.where((a) => a['entity_type'] == 'folder'), isEmpty);
  });
}
