import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '44444444-4444-4444-8444-444444444444';

// The Supabase client is a process-wide singleton, so one SyncService talks to one loopback cloud for all the
// scenarios of this file, run in order. Each scenario states the cloud and the local copies it starts from.
DateTime _at(int hour) => DateTime.utc(2026, 10, 1, hour);

Map<String, dynamic> _cloudNote(String id, String title, DateTime updatedAt, {DateTime? purgedAt}) => {
      'id': id,
      'user_id': _userId,
      'title': title,
      'content': '',
      'folder_id': 'notes',
      'tags': <String>[],
      'is_pinned': false,
      'is_locked': false,
      'is_deleted': false,
      'deleted_at': null,
      'created_at': _at(8).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'purged_at': purgedAt?.toIso8601String(),
    };

PostgresChangePayload _realtime(PostgresChangeEvent event, String table,
        {Map<String, dynamic> newRecord = const {}, Map<String, dynamic> oldRecord = const {}}) =>
    PostgresChangePayload(
      schema: 'public',
      table: table,
      commitTimestamp: DateTime.utc(2999),
      eventType: event,
      newRecord: newRecord,
      oldRecord: oldRecord,
      errors: null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('note transitions of a sync run and of realtime changes, against a simulated cloud', () async {
    // flutter_test replaces HttpClient with an offline stub; the simulated cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    // The simulated cloud: rows are stored as written, a placeholder is a row with `purged_at` set.
    final cloudRows = <String, Map<String, dynamic>>{};
    final cloudFolders = <String, Map<String, dynamic>>{};
    final noteUpserts = <String>[];
    var notesGets = 0;
    var revisionCounter = 1000;
    // The cloud gives every row a revision, as its trigger does; rows seeded without one get theirs on first use.
    void stampRevision(Map<String, dynamic> row) => row['revision'] ??= ++revisionCounter;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final path = request.uri.path;
      final idFilter = request.uri.queryParameters['id']?.replaceFirst('eq.', '');
      final liveOnly = request.uri.queryParameters['purged_at'] == 'is.null';
      final isNotes = path == '/rest/v1/notes';
      final isFolders = path == '/rest/v1/folders';
      if ((path == '/rest/v1/rpc/push_note' || path == '/rest/v1/rpc/push_folder') && request.method == 'POST') {
        final isNotePush = path == '/rest/v1/rpc/push_note';
        final call = jsonDecode(body) as Map<String, dynamic>;
        final row = Map<String, dynamic>.from(call[isNotePush ? 'p_note' : 'p_folder'] as Map);
        final table = isNotePush ? cloudRows : cloudFolders;
        final id = row['id'] as String;
        final current = table[id];
        if (current != null) stampRevision(current);
        request.response.headers.contentType = ContentType.json;
        if (call['p_base_revision'] != current?['revision']) {
          request.response.write(jsonEncode({'status': 'conflict', 'row': current}));
        } else {
          row['revision'] = ++revisionCounter;
          table[id] = row;
          if (isNotePush) noteUpserts.add(id);
          request.response.write(jsonEncode({'status': 'accepted', 'revision': revisionCounter}));
        }
      } else if ((isNotes || isFolders) && request.method == 'GET') {
        if (isNotes) notesGets++;
        final source = isNotes ? cloudRows.values : cloudFolders.values;
        final rows = source
            .where((row) => (idFilter == null || row['id'] == idFilter) && (!liveOnly || row['purged_at'] == null))
            .toList();
        rows.forEach(stampRevision);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(rows));
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
          'id': _userId,
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
    final tempDir = await Directory.systemTemp.createTemp('sync_note_transitions_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);

    final events = <RemoteChange>[];
    final subscription = syncService.remoteChanges.listen(events.add);
    addTearDown(subscription.cancel);
    List<String> removedIds() => events.whereType<CloudNoteRemoved>().map((e) => e.noteId).toList();
    List<String> appliedIds() => events.whereType<CloudNoteApplied>().map((e) => e.noteId).toList();

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    // The automatic sync started on sign-in must finish before the scenarios start.
    await waitUntil(() => notesGets > 0 && !syncService.isSyncing);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);

    Future<void> runSync() async {
      await waitUntil(() => !syncService.isSyncing);
      events.clear();
      await syncService.syncNow();
      // Events reach the subscription asynchronously; let them arrive before the scenario checks them.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    // Scenario 1: welcome notes. Discarded by a sync run when the cloud has a note that is not deleted.
    cloudRows
      ..clear()
      ..['cloud-live'] = _cloudNote('cloud-live', 'Nota nel cloud', _at(9));
    await dbService.upsertNote(Note(
      id: 'welcome-1',
      title: 'Benvenuto in OpenNotes',
      content: '',
      createdAt: _at(9),
      updatedAt: _at(9),
    ));
    await runSync();
    expect(await dbService.getNoteById('welcome-1'), isNull, reason: 'welcome note discarded when the cloud has notes');
    expect(noteUpserts, isNot(contains('welcome-1')));
    expect(cloudRows.containsKey('welcome-1'), isFalse);
    expect(removedIds(), contains('welcome-1'));

    // Scenario 2: the cloud has only deleted notes: the welcome note stays and is sent.
    // The synced note the cloud no longer lists is removed by the same run (CLOUD_NOTE_REMOVED, checked again below).
    cloudRows
      ..clear()
      ..['cloud-gone'] = _cloudNote('cloud-gone', 'Eliminata', _at(10), purgedAt: _at(10));
    await dbService.upsertNote(Note(
      id: 'welcome-2',
      title: 'Pianificazione & Attività',
      content: '',
      createdAt: _at(9),
      updatedAt: _at(9),
    ));
    await runSync();
    final welcomeTwo = await dbService.getNoteById('welcome-2');
    expect(welcomeTwo!.syncedAt, isNotNull, reason: 'welcome note kept and sent when the cloud has no live note');
    expect(cloudRows.containsKey('welcome-2'), isTrue);
    expect(removedIds(), contains('cloud-live'), reason: 'the full check removes the synced note the cloud lost');
    expect(await dbService.getNoteById('cloud-gone'), isNull, reason: 'a placeholder is never stored as a note');
    expect(await dbService.getNoteById('cloud-live'), isNull, reason: 'synced note the cloud no longer lists is removed');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // Scenario 3: cloud version replaces the local copy only when it is new for the device and no queued change
    // of the note is newer than it.
    cloudRows
      ..clear()
      ..['rep-newer'] = _cloudNote('rep-newer', 'Cloud nuova', _at(11))
      ..['rep-equal'] = _cloudNote('rep-equal', 'Cloud uguale', _at(9))
      ..['rep-pending'] = _cloudNote('rep-pending', 'Cloud vecchia', _at(10));
    await dbService.upsertNote(
        Note(id: 'rep-newer', title: 'Locale', content: '', createdAt: _at(9), updatedAt: _at(9)).copyWith(syncedAt: _at(9)));
    await dbService.upsertNote(Note(
      id: 'rep-equal',
      title: 'Locale uguale',
      content: '',
      createdAt: _at(9),
      updatedAt: _at(9),
    ).copyWith(syncedAt: _at(9)));
    final pendingLocal = Note(
      id: 'rep-pending',
      title: 'Modifica in coda',
      content: '',
      createdAt: _at(9),
      updatedAt: _at(12),
    ).copyWith(syncedAt: _at(9));
    await dbService.upsertNote(pendingLocal);
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'rep-pending',
      action: 'upsert',
      payload: jsonEncode(pendingLocal.toSupabaseJson(_userId)),
    );
    await runSync();
    expect((await dbService.getNoteById('rep-newer'))!.title, 'Cloud nuova');
    expect(appliedIds(), contains('rep-newer'));
    expect(appliedIds(), contains('rep-equal'));
    expect((await dbService.getNoteById('rep-equal'))!.title, 'Cloud uguale',
        reason: 'a copy with no revision here is new for the device, and a tie goes to the cloud');
    expect((await dbService.getNoteById('rep-pending'))!.title, 'Modifica in coda',
        reason: 'the queued change is newer than the cloud copy and replaces it in the cloud');
    expect(cloudRows['rep-pending']!['title'], 'Modifica in coda');
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // Scenario 4: CLOUD_NOTE_REMOVED from a sync run: a note the cloud lacks, and a note with a placeholder.
    final goneFile = await vaultService.saveNote(
        Note(id: 'gone-absent', title: 'Sparita', content: '', createdAt: _at(9), updatedAt: _at(9)));
    await dbService.upsertNote(Note(
      id: 'gone-absent',
      title: 'Sparita',
      content: '',
      createdAt: _at(9),
      updatedAt: _at(9),
      filePath: goneFile,
    ).copyWith(syncedAt: _at(9)));
    final placeholderFile = await vaultService.saveNote(
        Note(id: 'gone-placeholder', title: 'Segnaposto', content: '', createdAt: _at(9), updatedAt: _at(9)));
    await dbService.upsertNote(Note(
      id: 'gone-placeholder',
      title: 'Segnaposto',
      content: '',
      createdAt: _at(9),
      updatedAt: _at(9),
      filePath: placeholderFile,
    ).copyWith(syncedAt: _at(9)));
    cloudRows['gone-placeholder'] = _cloudNote('gone-placeholder', 'Segnaposto', _at(11), purgedAt: _at(11));
    await runSync();
    expect(await dbService.getNoteById('gone-absent'), isNull);
    expect(await dbService.getNoteById('gone-placeholder'), isNull);
    expect(File(goneFile).existsSync(), isFalse, reason: 'the vault file of the removed note is removed');
    expect(File(placeholderFile).existsSync(), isFalse);
    expect(await dbService.getPendingSyncActions(), isEmpty, reason: 'CLOUD_NOTE_REMOVED queues nothing');

    // Scenario 5: CLOUD_NOTE_REMOVED from realtime: a delete removes the note and queues nothing.
    await dbService.upsertNote(Note(
      id: 'rt-gone',
      title: 'Eliminata in tempo reale',
      content: '',
      createdAt: _at(9),
      updatedAt: _at(9),
    ).copyWith(syncedAt: _at(9)));
    events.clear();
    await syncService.handleRemoteNoteChange(_realtime(
      PostgresChangeEvent.delete,
      'notes',
      oldRecord: {'id': 'rt-gone', 'updated_at': _at(11).toIso8601String()},
    ));
    expect(await dbService.getNoteById('rt-gone'), isNull);
    expect(removedIds(), ['rt-gone']);
    expect(await dbService.getPendingSyncActions(), isEmpty);

    // Scenario 6: a folder deleted in the cloud moves its notes to Notes without changing their date, and queues nothing.
    final folderTime = _at(9);
    await dbService.upsertFolder(Folder(id: 'cf-1', name: 'Lavoro', createdAt: folderTime, updatedAt: folderTime));
    await dbService.upsertNote(Note(
      id: 'fo-1',
      title: 'Nel lavoro',
      content: '',
      createdAt: folderTime,
      updatedAt: folderTime,
      folderId: 'cf-1',
    ).copyWith(syncedAt: folderTime));
    await syncService.handleRemoteFolderChange(_realtime(
      PostgresChangeEvent.update,
      'folders',
      newRecord: {
        'id': 'cf-1',
        'user_id': _userId,
        'name': 'Lavoro',
        'parent_id': null,
        'icon': null,
        'is_system': false,
        'created_at': folderTime.toIso8601String(),
        'updated_at': _at(11).toIso8601String(),
        'purged_at': _at(11).toIso8601String(),
      },
    ));
    final moved = await dbService.getNoteById('fo-1');
    expect(moved!.folderId, Folder.defaultNotesId);
    expect(moved.updatedAt.isAtSameMomentAs(folderTime), isTrue, reason: 'the move keeps the modification date');
    expect(await dbService.getPendingSyncActions(), isEmpty, reason: 'a cloud folder delete is not queued');
  });
}
