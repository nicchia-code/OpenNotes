import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a realtime note change downloads its missing attachments at once; a pulled copy downloads none and a sync run downloads each once',
      () async {
    const userId = '44444444-4444-4444-8444-444444444444';
    const noteId = 'attachment-note';
    final now = DateTime.utc(2026, 10, 1, 9);

    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final cloudNotes = <Map<String, dynamic>>[];
    final storageGets = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final path = request.uri.path;
      if (path.startsWith('/storage/')) {
        storageGets.add(path);
        request.response.headers.contentType = ContentType.binary;
        request.response.add(const [1, 2, 3]);
      } else if (path == '/rest/v1/notes') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(cloudNotes));
      } else if (path == '/rest/v1/folders') {
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
    final tempDir = await Directory.systemTemp.createTemp('sync_pulling_attachments_vault_');
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

    // A note the device and the cloud both have at revision 3; its drawing is not in the vault yet.
    const content = '[{"type":"image","text":"attachments/disegno.png"}]';
    Map<String, dynamic> cloudRow(int revision, DateTime updatedAt, String title) => {
          'id': noteId,
          'user_id': userId,
          'title': title,
          'content': content,
          'folder_id': 'notes',
          'tags': <String>[],
          'is_pinned': false,
          'is_locked': false,
          'is_deleted': false,
          'deleted_at': null,
          'created_at': now.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
          'revision': revision,
          'purged_at': null,
        };
    cloudNotes.add(cloudRow(3, now, 'Con allegato'));
    await dbService.upsertNote(Note(
      id: noteId,
      title: 'Con allegato',
      content: content,
      createdAt: now,
      updatedAt: now,
    ).copyWith(syncedAt: now, cloudRevision: 3));

    // A newer cloud copy arrives on the realtime channel: it replaces the local copy and its missing attachment is
    // downloaded at once, without waiting for a sync run.
    await syncService.handleRemoteNoteChange(PostgresChangePayload(
      schema: 'public',
      table: 'notes',
      commitTimestamp: DateTime.utc(2026, 10, 1, 10),
      eventType: PostgresChangeEvent.update,
      newRecord: cloudRow(4, DateTime.utc(2026, 10, 1, 10), 'Con allegato nuovo'),
      oldRecord: const {},
      errors: null,
    ));
    expect(storageGets, hasLength(1));
    expect(storageGets.single, endsWith('/$userId/disegno.png'));
    expect(vaultService.resolveAttachment('attachments/disegno.png').existsSync(), isTrue);
    expect(await dbService.getCloudAttachmentPaths(), contains('attachments/disegno.png'));

    // A copy applied without the realtime channel (the pull) downloads nothing by itself: the sync run does it.
    final pulled = Note.fromSupabaseJson(cloudRow(5, DateTime.utc(2026, 10, 1, 11), 'Con allegato tirato'));
    expect(await syncService.applyRemoteNote(pulled), isTrue);
    expect(storageGets, hasLength(1), reason: 'attachments are downloaded by the sync run, not by applying a note');

    // The sync run downloads nothing more: the attachment is in the vault already.
    cloudNotes
      ..clear()
      ..add(cloudRow(5, DateTime.utc(2026, 10, 1, 11), 'Con allegato tirato'));
    await syncService.syncNow();
    expect(storageGets, hasLength(1));

    // The file is in the vault now: the next run does not download it again.
    await syncService.syncNow();
    expect(storageGets, hasLength(1));
  });
}
