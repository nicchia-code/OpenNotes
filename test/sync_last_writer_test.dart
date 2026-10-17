import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Own file: the Supabase client is a process-wide singleton bound to the first test's server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a queued save older than the cloud copy is dropped and the cloud version kept', () async {
    const userId = '11111111-1111-4111-8111-111111111111';
    final cloudNote = {
      'id': 'queued-note-2',
      'user_id': userId,
      'title': 'Versione cloud',
      'content': '',
      'folder_id': 'notes',
      'tags': <String>[],
      'is_pinned': false,
      'is_locked': false,
      'is_deleted': false,
      'deleted_at': null,
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2026-10-01T11:00:00.000Z',
      'revision': 5,
      'purged_at': null,
    };
    final cloudFolder = {
      'id': 'folder-1',
      'user_id': userId,
      'name': 'Nome cloud',
      'parent_id': null,
      'icon': 'folder',
      'is_system': false,
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2026-10-01T11:00:00.000Z',
      'revision': 5,
      'purged_at': null,
    };

    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final noteAttempts = <dynamic>[];
    final folderUpserts = <dynamic>[];
    var notesGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final isTable = request.uri.path == '/rest/v1/notes' ||
          request.uri.path == '/rest/v1/folders';
      if (request.uri.path == '/rest/v1/rpc/push_note' && request.method == 'POST') {
        // The cloud copy is newer than the queued save: the write conflicts and the cloud row comes back.
        noteAttempts.add(jsonDecode(body));
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'conflict', 'row': cloudNote}));
      } else if (request.uri.path == '/rest/v1/rpc/push_folder' && request.method == 'POST') {
        folderUpserts.add(jsonDecode(body));
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'status': 'conflict', 'row': cloudFolder}));
      } else if (isTable && request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/rest/v1/notes') {
          notesGets++;
          request.response.write(jsonEncode([cloudNote]));
        } else {
          request.response.write(jsonEncode([cloudFolder]));
        }
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
    final tempDir = await Directory.systemTemp.createTemp('sync_last_writer_vault_');
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

    // A note already synced once, then edited offline: its save sits in the queue.
    final localNote = Note(
      id: 'queued-note-2',
      title: 'Modifica locale vecchia',
      content: '',
      createdAt: DateTime.utc(2026, 10, 1, 9),
      updatedAt: DateTime.utc(2026, 10, 1, 10),
      syncedAt: DateTime.utc(2026, 10, 1, 9, 30),
    );
    await dbService.upsertNote(localNote);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: localNote.id,
      action: 'upsert',
      payload: jsonEncode(localNote.toSupabaseJson(userId)),
    );

    await syncService.syncNow();

    expect(noteAttempts, hasLength(1), reason: 'the save is sent once and the cloud answers with its newer copy');
    expect(await dbService.getPendingSyncActions(), isEmpty,
        reason: 'the discarded save leaves the queue, not sent');
    final stored = await dbService.getNoteById('queued-note-2');
    expect(stored!.title, 'Versione cloud');

    // A folder renamed offline while the cloud already has a newer version: the queued rename loses (last writer wins).
    final folderJson = {
      'id': 'folder-1',
      'name': 'Nome locale',
      'parent_id': null,
      'icon': 'folder',
      'is_system': 0,
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2026-10-01T10:00:00.000Z',
    };
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: 'folder-1',
      action: 'upsert',
      payload: jsonEncode(folderJson),
    );
    await syncService.syncNow();

    expect(folderUpserts, hasLength(1), reason: 'the queued rename is sent once, and the cloud copy is newer');
    expect((await dbService.getFolderById('folder-1'))!.name, 'Nome cloud',
        reason: 'the cloud copy wins: the older rename is discarded');
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });
}
