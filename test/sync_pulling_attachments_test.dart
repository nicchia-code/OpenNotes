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

  test('attachments of a cloud note are downloaded only when the cloud version replaces the local copy',
      () async {
    const userId = '44444444-4444-4444-8444-444444444444';
    const noteId = 'pull-attachment-note';

    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final storageGets = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      if (request.uri.path.startsWith('/storage/')) {
        storageGets.add(request.uri.path);
        request.response.statusCode = 404;
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

    // The note was deleted offline; the delete is queued now.
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

    // Cloud copy last edited before the delete was queued: the delete stays valid, the note is not replaced,
    // and no attachment is downloaded.
    final olderCloudCopy = Note(
      id: noteId,
      title: 'Cloud precedente',
      content: '[{"type":"image","text":"attachments/disegno.png"}]',
      createdAt: now,
      updatedAt: DateTime.utc(2026, 10, 1, 8),
    );
    expect(await syncService.applyRemoteNote(olderCloudCopy), isFalse);
    expect(storageGets, isEmpty, reason: 'a note whose queued delete stays valid downloads no attachment');
    expect(await dbService.getNoteById(noteId), isNull);
    expect(await dbService.hasPendingSyncAction(entityType: 'note', entityId: noteId, action: 'delete'), isTrue);

    // Cloud copy newer than the queued delete: it replaces the note, so its attachment is downloaded.
    final newerCloudCopy = olderCloudCopy.copyWith(updatedAt: DateTime.utc(2999));
    expect(await syncService.applyRemoteNote(newerCloudCopy), isTrue);
    expect(storageGets, hasLength(1), reason: 'the replacing cloud version downloads its attachment');
    expect(storageGets.single, endsWith('/$userId/disegno.png'));
    expect(await dbService.getNoteById(noteId), isNotNull);
  });
}
