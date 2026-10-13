import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kept apart from sync_service_test.dart: the Supabase client is a process-wide
// singleton, and another test there initializes it with an invalid URL.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('syncNow marks a queued note as synced once the cloud accepts it', () async {
    const userId = '11111111-1111-4111-8111-111111111111';
    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final upserts = <dynamic>[];
    final cloudRows = <String, Map<String, dynamic>>{};
    final cloudDeletes = <String>[];
    // Test hook: runs once inside the next note upload, as if the user deleted the note meanwhile.
    Future<void> Function()? onNoteUpsert;
    var notesGets = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final path = request.uri.path;
      final idFilter = request.uri.queryParameters['id']?.replaceFirst('eq.', '');
      final isTable = path == '/rest/v1/notes' || path == '/rest/v1/folders';
      if (isTable && request.method == 'POST') {
        if (path == '/rest/v1/notes') {
          final row = jsonDecode(body) as Map<String, dynamic>;
          final hook = onNoteUpsert;
          onNoteUpsert = null;
          await hook?.call();
          upserts.add(row);
          // Like the server trigger: updating a cloud note that exists bumps its updated_at.
          if (cloudRows.containsKey(row['id'])) {
            cloudRows[row['id'] as String] = {
              ...row,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            };
          }
        }
        request.response.statusCode = 201;
      } else if (isTable && request.method == 'GET') {
        if (path == '/rest/v1/notes') notesGets++;
        final rows = path == '/rest/v1/notes'
            ? cloudRows.values.where((row) => idFilter == null || row['id'] == idFilter).toList()
            : <Map<String, dynamic>>[];
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(rows));
      } else if (isTable && request.method == 'DELETE') {
        if (path == '/rest/v1/notes' && idFilter != null) {
          cloudDeletes.add(idFilter);
          cloudRows.remove(idFilter);
        }
        request.response.statusCode = 204;
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
    final tempDir = await Directory.systemTemp.createTemp('sync_queued_note_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    // Wait for the automatic sync started on sign-in, then let any follow-up finish,
    // so that the queued change below is not picked up by a sync already in flight.
    await waitUntil(() => notesGets > 0 && !syncService.isSyncing);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);

    final note = Note(
      id: 'queued-note-1',
      title: 'Nota in coda',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await dbService.upsertNote(note);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: note.id,
      action: 'upsert',
      payload: jsonEncode(note.toSupabaseJson(userId)),
    );

    await syncService.syncNow();

    final stored = await dbService.getNoteById('queued-note-1');
    expect(stored!.syncedAt, isNotNull);
    expect(upserts.length, 1, reason: 'queued note must be sent once, not again as unsynced');

    await syncService.syncNow();
    expect(upserts.length, 1);

    // Deleted in the cloud from another device: this device had synced it, and the cloud no longer has it.
    // The queued edit must not bring it back, and the note stays removed here.
    final deletedFilePath = '${tempDir.path}/Eliminata altrove.md';
    await File(deletedFilePath).writeAsString('---\nid: deleted-in-cloud-1\n---\n');
    final deletedNote = Note(
      id: 'deleted-in-cloud-1',
      title: 'Eliminata altrove',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      filePath: deletedFilePath,
    ).copyWith(syncedAt: DateTime.now());
    await dbService.upsertNote(deletedNote);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: deletedNote.id,
      action: 'upsert',
      payload: jsonEncode(deletedNote.toSupabaseJson(userId)),
    );

    await syncService.syncNow();

    expect(upserts.length, 1, reason: 'edit of a note deleted in the cloud must not be sent');
    expect(await dbService.getNoteById('deleted-in-cloud-1'), isNull);
    expect(await File(deletedFilePath).exists(), isFalse, reason: 'vault file of the removed note must be deleted');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // A never-synced note saved under a normal title, then renamed to a welcome title before any sync.
    // Its queued save must not be sent: the cloud is empty, so the note goes up with its current version.
    await dbService.upsertNote(Note(
      id: 'renamed-welcome-1',
      title: 'Benvenuto in OpenNotes',
      content: 'Testo attuale',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'renamed-welcome-1',
      action: 'upsert',
      payload: jsonEncode(Note(
        id: 'renamed-welcome-1',
        title: 'Nota in coda',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toSupabaseJson(userId)),
    );

    await syncService.syncNow();

    expect(upserts.any((u) => u['id'] == 'renamed-welcome-1' && u['title'] == 'Nota in coda'), isFalse,
        reason: 'queued save of a renamed welcome note must not be sent');
    expect(upserts.last['id'], 'renamed-welcome-1');
    expect(upserts.last['title'], 'Benvenuto in OpenNotes');
    expect(upserts.last['content'], 'Testo attuale');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // A never-synced note saved while offline, then deleted here before any sync: its row is purged and the delete
    // is queued. The queued save is sent, so the note and its text reach the cloud, then the queued delete removes it.
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'deleted-unsynced-1',
      action: 'upsert',
      payload: jsonEncode({
        ...Note(
          id: 'deleted-unsynced-1',
          title: 'Mai sincronizzata',
          content: 'Testo non ancora inviato',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toSupabaseJson(userId),
      }),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'deleted-unsynced-1',
      action: 'delete',
      payload: jsonEncode({'id': 'deleted-unsynced-1'}),
    );

    await syncService.syncNow();

    expect(upserts.any((u) => u['id'] == 'deleted-unsynced-1' && u['content'] == 'Testo non ancora inviato'), isTrue,
        reason: 'save of a note never synced here must reach the cloud even when it was deleted here');
    expect(cloudDeletes, contains('deleted-unsynced-1'), reason: 'the queued delete then removes it from the cloud');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // Synced here and now gone from the cloud: the queued save is discarded with the note, because this device
    // had synced it. Nothing reaches the cloud.
    final gone = Note(
      id: 'purged-synced-1',
      title: 'Sincronizzata e poi eliminata',
      content: 'Testo locale',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await dbService.upsertNote(gone.copyWith(syncedAt: DateTime.now()));
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: gone.id,
      action: 'upsert',
      payload: jsonEncode(gone.toSupabaseJson(userId)),
    );
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'purged-synced-1',
      action: 'delete',
      payload: jsonEncode({'id': 'purged-synced-1'}),
    );

    await syncService.syncNow();

    expect(upserts.any((u) => u['id'] == 'purged-synced-1'), isFalse,
        reason: 'save of a note this device had synced, now gone from the cloud, must be discarded');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // Note already in the cloud, edited, then deleted while that save is being sent. The delete reaches the
    // cloud in the same run, and the note does not come back on the next sync.
    final inFlightNote = Note(
      id: 'deleted-during-send-1',
      title: 'Eliminata durante l\'invio',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    cloudRows[inFlightNote.id] = inFlightNote
        .copyWith(updatedAt: DateTime.now().subtract(const Duration(hours: 1)))
        .toSupabaseJson(userId);
    await dbService.upsertNote(inFlightNote.copyWith(syncedAt: DateTime.now()));
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: inFlightNote.id,
      action: 'upsert',
      payload: jsonEncode(inFlightNote.toSupabaseJson(userId)),
    );
    onNoteUpsert = () async {
      await dbService.permanentlyDeleteNote(inFlightNote.id);
      await dbService.queueSyncAction(
        entityType: 'note',
        entityId: inFlightNote.id,
        action: 'delete',
        payload: jsonEncode({'id': inFlightNote.id}),
      );
    };

    await syncService.syncNow();

    expect(cloudDeletes, contains(inFlightNote.id),
        reason: 'delete made while the save was in flight must reach the cloud in the same run');
    expect(cloudRows.containsKey(inFlightNote.id), isFalse);
    expect(await dbService.getNoteById(inFlightNote.id), isNull);

    await syncService.syncNow();

    expect(await dbService.getNoteById(inFlightNote.id), isNull,
        reason: 'note deleted while its save was in flight must not come back');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // Never-synced note edited while its upload is in flight. The edit is queued as the notes screen does. The note
    // must reach the cloud with the edit in the same run, and the device must keep the edit.
    final editedNote = Note(
      id: 'edited-during-send-1',
      title: 'Modificata durante l\'invio',
      content: 'Versione iniziale',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    cloudRows[editedNote.id] = editedNote.toSupabaseJson(userId);
    await dbService.upsertNote(editedNote);
    expect((await dbService.getNotes(isDeleted: null)).where((n) => n.syncedAt == null).map((n) => n.id),
        [editedNote.id], reason: 'the edited note must be the only unsynced note of this run');
    final edit = editedNote.copyWith(content: 'Versione modificata', updatedAt: DateTime.now());
    onNoteUpsert = () async {
      await dbService.upsertNote(edit);
      await syncService.notifyNoteChanged(edit);
    };

    await syncService.syncNow();

    expect(upserts.where((u) => u['id'] == editedNote.id).map((u) => u['content']),
        ['Versione iniziale', 'Versione modificata'],
        reason: 'the edit made during the upload must be sent again in the same run');
    final afterRun = await dbService.getNoteById(editedNote.id);
    expect(afterRun!.content, 'Versione modificata', reason: 'the device must keep the edit');
    expect(afterRun.syncedAt, isNotNull);

    await syncService.syncNow();

    expect((await dbService.getNoteById(editedNote.id))!.content, 'Versione modificata',
        reason: 'the next run must not discard the edit');
    expect(cloudRows[editedNote.id]!['content'], 'Versione modificata');
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });
}
