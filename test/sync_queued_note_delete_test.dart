import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Own file: the Supabase client is a process-wide singleton bound to the first test's server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a cloud copy edited after a queued note delete replaces the note and drops the delete',
      () async {
    const userId = '33333333-3333-4333-8333-333333333333';
    const noteId = 'deleted-offline-note';
    // Cloud copy, edited after the delete was queued (the delete is queued with "now").
    Map<String, dynamic>? cloudNote = {
      'id': noteId,
      'user_id': userId,
      'title': 'Modificata nel cloud',
      'content': '',
      'folder_id': 'notes',
      'tags': <String>[],
      'is_pinned': false,
      'is_locked': false,
      'is_deleted': false,
      'deleted_at': null,
      'created_at': '2026-10-01T09:00:00.000Z',
      'updated_at': '2999-01-01T00:00:00.000Z',
    };

    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final noteDeletes = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final isNotes = request.uri.path == '/rest/v1/notes';
      final wantsObject =
          (request.headers.value('accept') ?? '').contains('vnd.pgrst.object');
      if (isNotes && request.method == 'DELETE') {
        noteDeletes.add(request.uri.toString());
        cloudNote = null;
        request.response.statusCode = 204;
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
    final tempDir = await Directory.systemTemp.createTemp('sync_queued_note_delete_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);
    List<File> vaultFiles() =>
        vaultService.vaultDir.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList();

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => !syncService.isSyncing);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);

    // The note was deleted offline: the delete sits in the queue, the note is gone locally.
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertNote(Note(
      id: noteId,
      title: 'Eliminata offline',
      content: '',
      createdAt: now,
      updatedAt: now,
    ).copyWith(syncedAt: now));
    await dbService.permanentlyDeleteNote(noteId);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: noteId,
      action: 'delete',
      payload: jsonEncode({'id': noteId}),
    );

    // The cloud copy, edited after the delete was queued, arrives in real time: it replaces the note and the delete is dropped.
    for (final file in vaultFiles()) {
      file.deleteSync();
    }
    await syncService.handleRemoteNoteChange(PostgresChangePayload(
      schema: 'public',
      table: 'notes',
      commitTimestamp: DateTime.utc(2999),
      eventType: PostgresChangeEvent.update,
      newRecord: cloudNote!,
      oldRecord: const {},
      errors: null,
    ));
    expect(await dbService.getNoteById(noteId), isNotNull, reason: 'the cloud copy replaces the queued delete');
    expect(vaultFiles(), hasLength(1), reason: 'the note gets its Markdown file back');
    expect(await dbService.hasPendingSyncAction(entityType: 'note', entityId: noteId, action: 'delete'), isFalse);

    // The next sync sends nothing for the note: the cloud copy stays.
    await syncService.syncNow();

    expect(noteDeletes, isEmpty, reason: 'the dropped delete is not sent');
    expect(cloudNote, isNotNull);
    expect(await dbService.getNoteById(noteId), isNotNull);
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });
}
