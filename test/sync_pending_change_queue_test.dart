import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.init(inMemory: true);
  });

  Future<void> queueSave(String noteId, String title) {
    final note = Note(
      id: noteId,
      title: title,
      content: '',
      createdAt: DateTime.utc(2026, 10, 1, 9),
      updatedAt: DateTime.utc(2026, 10, 1, 10),
    );
    return dbService.queueSyncAction(
      entityType: 'note',
      entityId: noteId,
      action: 'upsert',
      payload: jsonEncode(note.toSupabaseJson('user-1')),
    );
  }

  test('ten saves of one note leave one queued item holding the last save', () async {
    for (var i = 1; i <= 10; i++) {
      await queueSave('same-note', 'Salvataggio $i');
    }

    final pending = await dbService.getPendingSyncActions();
    expect(pending, hasLength(1));
    expect(pending.single['entity_id'], 'same-note');
    expect((jsonDecode(pending.single['payload'] as String) as Map)['title'], 'Salvataggio 10');
  });

  test('a new save keeps the position of the queued item of its note', () async {
    await queueSave('first-note', 'Prima');
    await queueSave('second-note', 'Seconda');
    await queueSave('first-note', 'Prima aggiornata');

    final pending = await dbService.getPendingSyncActions();
    expect(pending.map((p) => p['entity_id']), ['first-note', 'second-note']);
    expect((jsonDecode(pending.first['payload'] as String) as Map)['title'], 'Prima aggiornata');
  });

  test('a delete takes the place of the queued save of its note', () async {
    await queueSave('first-note', 'Prima');
    await queueSave('second-note', 'Seconda');
    await dbService.queueSyncAction(
      entityType: 'note',
      entityId: 'first-note',
      action: 'delete',
      payload: jsonEncode({'id': 'first-note'}),
    );

    final pending = await dbService.getPendingSyncActions();
    expect(pending, hasLength(2));
    expect(pending.first['entity_id'], 'first-note');
    expect(pending.first['action'], 'delete');
    expect(pending.last['action'], 'upsert');
  });

  test('a queued item removed with the snapshot of an older save stays for a newer save', () async {
    await queueSave('busy-note', 'Inviata');
    final sent = (await dbService.getPendingSyncActions()).single;
    // Saved again while the upload of the first version was in flight.
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await queueSave('busy-note', 'Modificata durante l\'invio');

    await dbService.removeSyncActionIfUnchanged(sent);

    final pending = await dbService.getPendingSyncActions();
    expect(pending, hasLength(1));
    expect((jsonDecode(pending.single['payload'] as String) as Map)['title'], 'Modificata durante l\'invio');

    await dbService.removeSyncActionIfUnchanged(pending.single);
    expect(await dbService.getPendingSyncActions(), isEmpty);
  });

  test('a new save keeps the base revision and clears the rejections of the queued item', () async {
    await dbService.upsertNote(Note(
      id: 'rev-note',
      title: 'Revisione',
      content: '',
      createdAt: DateTime.utc(2026, 10, 1, 9),
      updatedAt: DateTime.utc(2026, 10, 1, 10),
    ).copyWith(cloudRevision: 7));
    await queueSave('rev-note', 'Prima');
    final queued = (await dbService.getPendingSyncActions()).single;
    expect(queued['base_revision'], 7);

    for (var i = 0; i < DatabaseService.rejectionsBeforeSetAside; i++) {
      await dbService.recordRejectedSyncAction(queued, 'permission denied');
    }
    final setAside = (await dbService.getPendingSyncActions()).single;
    expect(setAside['attempts'], 3);
    expect(setAside['set_aside'], 1);
    expect(setAside['last_error'], 'permission denied');

    await queueSave('rev-note', 'Dopo il rifiuto');
    final saved = (await dbService.getPendingSyncActions()).single;
    expect(saved['base_revision'], 7, reason: 'the base revision of the queued item is kept');
    expect(saved['attempts'], 0);
    expect(saved['set_aside'], 0, reason: 'a new save is queued again, not set aside');
    expect(saved['last_error'], isNull);
    expect((jsonDecode(saved['payload'] as String) as Map)['title'], 'Dopo il rifiuto');
  });

  test('two refusals in a row leave the change queued, the third sets it aside', () async {
    await queueSave('busy-note', 'Rifiutata');
    final queued = (await dbService.getPendingSyncActions()).single;
    await dbService.recordRejectedSyncAction(queued, 'refused');
    await dbService.recordRejectedSyncAction(queued, 'refused');
    expect((await dbService.getPendingSyncActions()).single['set_aside'], 0);
    await dbService.recordRejectedSyncAction(queued, 'refused');
    expect((await dbService.getPendingSyncActions()).single['set_aside'], 1);
  });

  test('retry puts a set-aside change back at its place with its rejections cleared', () async {
    await queueSave('first-note', 'Prima');
    await queueSave('second-note', 'Seconda');
    final first = (await dbService.getPendingSyncActions()).first;
    for (var i = 0; i < DatabaseService.rejectionsBeforeSetAside; i++) {
      await dbService.recordRejectedSyncAction(first, 'refused');
    }

    expect(await dbService.retrySetAsideSyncAction('note', 'first-note'), isTrue);
    final pending = await dbService.getPendingSyncActions();
    expect(pending.map((p) => p['entity_id']), ['first-note', 'second-note']);
    expect(pending.first['attempts'], 0);
    expect(pending.first['set_aside'], 0);
    expect(pending.first['last_error'], isNull);
    expect(await dbService.retrySetAsideSyncAction('note', 'first-note'), isFalse,
        reason: 'a change that is not set aside is not retried');
  });

  test('a refused change is set aside after three refusals, and the cloud copy or a retry settles it', () async {
    const userId = '11111111-1111-4111-8111-111111111111';
    // flutter_test replaces HttpClient with an offline stub; the fake cloud needs real sockets.
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeCloud(server);

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
    final tempDir = await Directory.systemTemp.createTemp('pending_change_queue_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    // Wait for the automatic sync started on sign-in, so that it does not overlap the runs below.
    await waitUntil(() => cloud.notesGets > 0 && !syncService.isSyncing);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);

    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    Map<String, dynamic> cloudNote(String id, String title,
            {DateTime? updatedAt, int revision = 1, DateTime? purgedAt}) =>
        {
          ...Note(id: id, title: title, content: '', createdAt: hourAgo, updatedAt: updatedAt ?? hourAgo)
              .toSupabaseJson(userId),
          'revision': revision,
          'purged_at': purgedAt?.toIso8601String(),
        };
    // A note this device saved and queued, as the notes screen does.
    Future<void> queueLocal(String id, String title, {int revision = 1}) async {
      final note = Note(id: id, title: title, content: '', createdAt: hourAgo, updatedAt: DateTime.now());
      await dbService.upsertNote(note.copyWith(syncedAt: DateTime.now(), cloudRevision: revision));
      await dbService.queueSyncAction(
        entityType: 'note',
        entityId: id,
        action: 'upsert',
        payload: jsonEncode(note.toSupabaseJson(userId)),
      );
    }

    // The cloud refuses the first note; the second is sent past it; a copy only in the cloud is pulled.
    cloud.notes['refused-1'] = cloudNote('refused-1', 'Nel cloud');
    cloud.notes['good-1'] = cloudNote('good-1', 'Buona nel cloud');
    cloud.notes['cloud-only-1'] = cloudNote('cloud-only-1', 'Solo nel cloud', revision: 2);
    cloud.refusedIds.add('refused-1');
    await queueLocal('refused-1', 'Rifiutata');
    await queueLocal('good-1', 'Buona');

    for (var run = 1; run <= DatabaseService.rejectionsBeforeSetAside; run++) {
      await syncService.syncNow();
      final pending = (await dbService.getPendingSyncActions()).single;
      expect(pending['entity_id'], 'refused-1');
      expect(pending['attempts'], run);
      expect(pending['set_aside'], run == DatabaseService.rejectionsBeforeSetAside ? 1 : 0);
      expect(pending['last_error'], 'permission denied for note refused-1');
    }
    expect(cloud.notes['good-1']!['title'], 'Buona', reason: 'the queued change after a refused one is sent');
    expect(await dbService.getNoteById('cloud-only-1'), isNotNull, reason: 'the pull still runs');

    // Set aside: the change is not sent by itself, and it does not stop the pull.
    final attemptsBefore = cloud.attempts.where((id) => id == 'refused-1').length;
    cloud.notes['cloud-only-2'] = cloudNote('cloud-only-2', 'Anche questa');
    await syncService.syncNow();
    expect(cloud.attempts.where((id) => id == 'refused-1').length, attemptsBefore,
        reason: 'a set-aside change is not sent again by itself');
    expect(await dbService.getNoteById('cloud-only-2'), isNotNull,
        reason: 'a set-aside change does not block the pull');
    expect(syncService.pendingChangeCount, 0, reason: 'a set-aside change is not counted as waiting');
    final setAside = await syncService.setAsideChanges();
    expect(setAside.single.entityId, 'refused-1');
    expect(setAside.single.title, 'Rifiutata');
    expect(setAside.single.cloudHasCopy, isTrue);

    // Retry: back in the queue, sent once the cloud accepts it.
    cloud.refusedIds.remove('refused-1');
    expect(await syncService.retrySetAsideChange('note', 'refused-1'), isTrue);
    expect(await dbService.getPendingSyncActions(), isEmpty);
    expect(cloud.notes['refused-1']!['title'], 'Rifiutata');
    expect(await syncService.retrySetAsideChange('note', 'refused-1'), isFalse);

    // The cloud copy is a revision this device has already seen: only the user's choice brings it down.
    cloud.notes['conflict-1'] = cloudNote('conflict-1', 'Titolo del cloud',
        revision: 7, updatedAt: hourAgo.subtract(const Duration(minutes: 5)));
    cloud.refusedIds.add('conflict-1');
    await queueLocal('conflict-1', 'Modifica locale', revision: 7);
    for (var run = 1; run <= DatabaseService.rejectionsBeforeSetAside; run++) {
      await syncService.syncNow();
    }
    expect((await dbService.getPendingSyncActions()).single['set_aside'], 1);
    expect((await syncService.setAsideChanges()).single.cloudHasCopy, isTrue, reason: 'the cloud copy is offered');
    expect(await syncService.useCloudVersion('note', 'conflict-1'), isTrue);
    expect(await dbService.getPendingSyncActions(), isEmpty);
    expect((await dbService.getNoteById('conflict-1'))!.title, 'Titolo del cloud',
        reason: 'the cloud copy replaces the local change');

    // A cloud copy deleted there has no copy to use: the set-aside change stays.
    cloud.notes['placeholder-1'] =
        cloudNote('placeholder-1', '', revision: 9, purgedAt: hourAgo);
    cloud.refusedIds.add('placeholder-1');
    await queueLocal('placeholder-1', 'Modificata', revision: 9);
    for (var run = 1; run <= DatabaseService.rejectionsBeforeSetAside; run++) {
      await syncService.syncNow();
    }
    expect(await syncService.useCloudVersion('note', 'placeholder-1'), isFalse,
        reason: 'a deleted cloud copy is not offered');
    expect((await dbService.getPendingSyncActions()).single['set_aside'], 1);
    final placeholderSetAside = (await syncService.setAsideChanges()).single;
    expect(placeholderSetAside.title, 'Modificata');
    expect(placeholderSetAside.cloudHasCopy, isFalse, reason: 'a deleted cloud copy is not offered');
  });
}

/// Fake cloud for the notes table, served on loopback: the sync run talks to it as to PostgREST.
class FakeCloud {
  FakeCloud(this._server) {
    _server.listen(_handle);
  }

  final HttpServer _server;
  final Map<String, Map<String, dynamic>> notes = {};
  /// Notes whose upload the cloud refuses with a permission error.
  final Set<String> refusedIds = {};
  /// Ids of every note upload attempt, refused or not.
  final List<String> attempts = [];
  int notesGets = 0;
  int _revision = 100;

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final idParam = request.uri.queryParameters['id'];
    // `eq.<id>` for one row; `in.("<id>","…")` for the chosen versions read by id, as the client quotes them.
    final ids = idParam == null
        ? null
        : idParam.startsWith('in.(')
            ? idParam.substring(4, idParam.length - 1).split(',').map((id) => id.replaceAll('"', '')).toList()
            : [idParam.replaceFirst('eq.', '')];
    final response = request.response;
    if (request.uri.path == '/rest/v1/folders') {
      // The scenarios of this file queue no folder change: the folders are only read.
      response.headers.contentType = ContentType.json;
      response.write(request.method == 'GET' ? '[]' : jsonEncode({'revision': ++_revision}));
    } else if (request.uri.path == '/rest/v1/rpc/push_note' && request.method == 'POST') {
      final call = jsonDecode(body) as Map<String, dynamic>;
      final row = Map<String, dynamic>.from(call['p_note'] as Map<String, dynamic>);
      final id = row['id'] as String;
      attempts.add(id);
      final current = notes[id];
      response.headers.contentType = ContentType.json;
      if (refusedIds.contains(id)) {
        response.statusCode = 403;
        response.write(jsonEncode({
          'code': '42501',
          'message': 'permission denied for note $id',
          'details': null,
          'hint': null,
        }));
      } else if (call['p_base_revision'] != current?['revision']) {
        response.write(jsonEncode({'status': 'conflict', 'row': current}));
      } else {
        final revision = ++_revision;
        notes[id] = {...row, 'revision': revision};
        response.write(jsonEncode({'status': 'accepted', 'revision': revision}));
      }
    } else if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') {
      notesGets++;
      final rows = notes.values.where((row) => ids == null || ids.contains(row['id'])).toList();
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(rows));
    } else {
      response.statusCode = 404;
    }
    await response.close();
  }
}
