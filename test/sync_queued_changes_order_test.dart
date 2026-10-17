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

  test('queued edits of a note already in the cloud reach it, and a later delete stays a delete', () async {
    const userId = '44444444-4444-4444-8444-444444444444';
    const editedId = 'queued-edits-note';
    const deletedId = 'queued-edit-then-delete-note';
    Map<String, dynamic> cloudRow(String id, String title) => {
          'id': id,
          'user_id': userId,
          'title': title,
          'content': '',
          'folder_id': 'notes',
          'tags': <String>[],
          'is_pinned': false,
          'is_locked': false,
          'is_deleted': false,
          'deleted_at': null,
          'created_at': '2000-01-01T00:00:00.000Z',
          // Copy written long ago by another device.
          'updated_at': '2000-01-01T00:00:00.000Z',
          'revision': 1,
        };
    Map<String, dynamic>? cloudNote = cloudRow(editedId, 'Versione vecchia');
    var revisionCounter = 1;

    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final isNotes = request.uri.path == '/rest/v1/notes';
      final wantsObject =
          (request.headers.value('accept') ?? '').contains('vnd.pgrst.object');
      if (request.uri.path == '/rest/v1/rpc/push_note' && request.method == 'POST') {
        final call = jsonDecode(body) as Map<String, dynamic>;
        final current = cloudNote;
        request.response.headers.contentType = ContentType.json;
        if (call['p_base_revision'] != current?['revision']) {
          request.response.write(jsonEncode({'status': 'conflict', 'row': current}));
        } else {
          final row = Map<String, dynamic>.from(call['p_note'] as Map<String, dynamic>);
          row['revision'] = ++revisionCounter;
          cloudNote = row;
          request.response.write(jsonEncode({'status': 'accepted', 'revision': revisionCounter}));
        }
      } else if (isNotes && request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        if (wantsObject) {
          request.response.write(jsonEncode(cloudNote ?? []));
        } else {
          request.response.write(jsonEncode(cloudNote == null ? [] : [cloudNote]));
        }
      } else if (request.uri.path == '/rest/v1/folders' && request.method == 'GET') {
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
    final tempDir = await Directory.systemTemp.createTemp('sync_queued_changes_order_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => !syncService.isSyncing);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);

    // Two offline edits of a note the cloud already has: they are one queued item, holding the later edit.
    final created = DateTime.utc(2026, 10, 1, 9);
    final first = Note(
      id: editedId,
      title: 'Prima modifica',
      content: '',
      createdAt: created,
      updatedAt: DateTime.utc(2026, 10, 1, 10),
    ).copyWith(syncedAt: created);
    final second = first.copyWith(title: 'Seconda modifica', updatedAt: DateTime.utc(2026, 10, 1, 10, 5));
    await dbService.upsertNote(second);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: editedId,
      action: 'upsert',
      payload: jsonEncode(first.toSupabaseJson(userId)),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: editedId,
      action: 'upsert',
      payload: jsonEncode(second.toSupabaseJson(userId)),
    );

    await syncService.syncNow();

    expect(cloudNote?['title'], 'Seconda modifica', reason: 'the later queued edit must not be dropped');
    expect((await dbService.getNoteById(editedId))!.title, 'Seconda modifica');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // An edit and then a delete of another cloud note, both queued offline: the delete stays a delete.
    cloudNote = cloudRow(deletedId, 'Da eliminare');
    final edited = Note(
      id: deletedId,
      title: 'Modificata prima di eliminare',
      content: '',
      createdAt: created,
      updatedAt: DateTime.utc(2026, 10, 1, 11),
    ).copyWith(syncedAt: created);
    await dbService.deleteNoteRow(deletedId);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: deletedId,
      action: 'upsert',
      payload: jsonEncode(edited.toSupabaseJson(userId)),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: deletedId,
      action: 'delete',
      payload: jsonEncode({'id': deletedId}),
    );

    await syncService.syncNow();

    expect(cloudNote!['purged_at'], isNotNull, reason: 'the queued delete is newer than the cloud copy: it leaves a placeholder');
    expect(await dbService.getNoteById(deletedId), isNull);
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });
}
