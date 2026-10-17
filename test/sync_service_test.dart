import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/auth_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late VaultService vaultService;
  late SyncService syncService;
  late Directory tempDir;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.init(inMemory: true);

    tempDir = await Directory.systemTemp.createTemp('sync_test_vault_');
    vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    syncService = SyncService(dbService, vaultService);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('NotesProvider automatically refreshes when SyncService notifies updates', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    expect(provider.notes, isEmpty);

    // Simulate an external/remote note being saved into dbService & notifying syncService
    final newNote = Note(
      id: 'cloud-note-1',
      title: 'Nota da Cloud',
      content: 'Contenuto sincronizzato',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncedAt: DateTime.now(),
    );
    await dbService.upsertNote(newNote);

    // SyncService fires notifyListeners (e.g. from realtime update or sync completion); wait for
    // the provider's reload instead of sleeping, which flakes when the machine is loaded.
    final reloaded = Completer<void>();
    void onChange() {
      if (provider.notes.isNotEmpty && !reloaded.isCompleted) reloaded.complete();
    }
    provider.addListener(onChange);
    syncService.notifyListeners();
    await reloaded.future.timeout(const Duration(seconds: 5));
    provider.removeListener(onChange);

    expect(provider.notes.length, 1);
    expect(provider.notes.first.title, 'Nota da Cloud');
    expect(provider.selectedNoteId, 'cloud-note-1');

    provider.dispose();
  });

  test('Realtime note change reloads the lists at once', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    expect(provider.notes.any((n) => n.id == 'cloud-note-3'), isFalse);

    final cloudNote = Note(
      id: 'cloud-note-3',
      title: 'Nota realtime',
      content: 'Contenuto',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    await syncService.handleRemoteNoteChange(PostgresChangePayload(
      schema: 'public',
      table: 'notes',
      commitTimestamp: DateTime(2025),
      eventType: PostgresChangeEvent.insert,
      newRecord: cloudNote.toSupabaseJson('user-1'),
      oldRecord: const {},
      errors: null,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(provider.notes.map((n) => n.id), contains('cloud-note-3'));

    provider.dispose();
  });

  test('Remote delete removes the note and discards its queued saves', () async {
    final note = Note(
      id: 'deleted-in-cloud',
      title: 'Nota eliminata',
      content: 'Contenuto',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      syncedAt: DateTime(2025),
    );
    await dbService.upsertNote(note);
    await syncService.notifyNoteChanged(note);
    expect(await dbService.getPendingSyncActions(), hasLength(1));

    await syncService.handleRemoteNoteChange(PostgresChangePayload(
      schema: 'public',
      table: 'notes',
      commitTimestamp: DateTime(2025),
      eventType: PostgresChangeEvent.delete,
      newRecord: const {},
      oldRecord: {'id': 'deleted-in-cloud'},
      errors: null,
    ));

    expect(await dbService.getPendingSyncActions(), isEmpty);
    expect(await dbService.getNoteById('deleted-in-cloud'), isNull);
  });

  test('Remote delete emits CloudNoteRemoved for the removed note', () async {
    await dbService.upsertNote(Note(
      id: 'removed-in-cloud',
      title: 'Nota rimossa',
      content: '',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      syncedAt: DateTime(2025),
    ));
    final events = <RemoteChange>[];
    final subscription = syncService.remoteChanges.listen(events.add);

    await syncService.handleRemoteNoteChange(PostgresChangePayload(
      schema: 'public',
      table: 'notes',
      commitTimestamp: DateTime(2025),
      eventType: PostgresChangeEvent.delete,
      newRecord: const {},
      oldRecord: {'id': 'removed-in-cloud'},
      errors: null,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(events.single, isA<CloudNoteRemoved>().having((e) => e.noteId, 'noteId', 'removed-in-cloud'));

    await subscription.cancel();
  });

  test('SyncService queueing actions writes to SQLite sync_queue table', () async {
    final note = Note(
      id: 'local-note-1',
      title: 'Nota Locale',
      content: 'Test content',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await syncService.notifyNoteChanged(note);

    final pending = await dbService.getPendingSyncActions();
    expect(pending.length, 1);
    expect(pending.first['entity_type'], 'note');
    expect(pending.first['entity_id'], 'local-note-1');
    expect(pending.first['action'], 'upsert');
  });

  test('Never-synced welcome notes are not queued for the cloud', () async {
    final welcome = Note(
      id: 'welcome-1',
      title: 'Benvenuto in OpenNotes',
      content: 'Test content',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await syncService.notifyNoteChanged(welcome);

    final pending = await dbService.getPendingSyncActions();
    expect(pending.where((a) => a['entity_id'] == 'welcome-1'), isEmpty);
  });

  test('Permanently deleting a never-synced welcome note queues a delete', () async {
    final welcome = Note(
      id: 'welcome-2',
      title: 'Pianificazione & Attività',
      content: 'Test content',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await syncService.notifyNoteChanged(welcome, isDelete: true);

    final pending = await dbService.getPendingSyncActions();
    expect(pending, hasLength(1));
    expect(pending.first['entity_id'], 'welcome-2');
    expect(pending.first['action'], 'delete');
  });

  test('Creating and renaming a folder keeps one queued folder upsert', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    final folder = await provider.createFolder('Lavoro');
    await provider.renameFolder(folder.id, 'Lavori');

    final pending = (await dbService.getPendingSyncActions())
        .where((p) => p['entity_type'] == 'folder')
        .toList();
    expect(pending.length, 1, reason: 'the rename replaces the queued creation of the folder');
    expect(pending.every((p) => p['entity_id'] == folder.id), isTrue);
    expect(pending.every((p) => p['action'] == 'upsert'), isTrue);

    provider.dispose();
  });

  test('Deleting a folder queues a folder delete', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    final folder = await provider.createFolder('Temp');
    await provider.deleteFolder(folder.id);

    final pending = await dbService.getPendingSyncActions();
    expect(pending.last['entity_type'], 'folder');
    expect(pending.last['action'], 'delete');
    expect(pending.last['entity_id'], folder.id);

    provider.dispose();
  });

  test('Deleting a folder drops its queued create and rename', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    final folder = await provider.createFolder('Offline');
    await provider.renameFolder(folder.id, 'Offline renamed');
    await provider.deleteFolder(folder.id);

    final pending = (await dbService.getPendingSyncActions())
        .where((p) => p['entity_type'] == 'folder' && p['entity_id'] == folder.id)
        .toList();
    expect(pending.length, 1);
    expect(pending.single['action'], 'delete');

    provider.dispose();
  });

  test('Deleting a synced folder queues the delete on the cloud revision the device saw', () async {
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(
      Folder(id: 'synced-folder-delete', name: 'Sincronizzata', createdAt: now, updatedAt: now, cloudRevision: 7),
    );
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    await provider.deleteFolder('synced-folder-delete');

    final pending = (await dbService.getPendingSyncActions())
        .where((p) => p['entity_type'] == 'folder' && p['entity_id'] == 'synced-folder-delete')
        .toList();
    expect(pending.single['action'], 'delete');
    expect(pending.single['base_revision'], 7);

    provider.dispose();
  });

  test('Cloud version carries its lock state to the local copy, in both directions', () async {
    final local = Note(
      id: 'cloud-note-lock',
      title: 'Lucchetto',
      content: 'Versione locale',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    await dbService.upsertNote(local);

    final lockedRemote = local.copyWith(
      content: 'Versione protetta altrove',
      isLocked: true,
      updatedAt: DateTime(2025),
    );
    expect(await syncService.applyRemoteNote(lockedRemote), isTrue);
    expect((await dbService.getNoteById('cloud-note-lock'))!.isLocked, isTrue);

    final unlockedRemote = lockedRemote.copyWith(isLocked: false, updatedAt: DateTime(2026));
    expect(await syncService.applyRemoteNote(unlockedRemote), isTrue);
    expect((await dbService.getNoteById('cloud-note-lock'))!.isLocked, isFalse);
  });

  test('Cloud copy at or below the stored revision is ignored, whatever its update time', () async {
    await dbService.upsertNote(Note(
      id: 'cloud-note-revision',
      title: 'Revisione',
      content: 'Versione locale',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      cloudRevision: 5,
    ));

    final echo = Note(
      id: 'cloud-note-revision',
      title: 'Revisione',
      content: 'Eco',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2030),
      cloudRevision: 5,
    );
    expect(await syncService.applyRemoteNote(echo), isFalse);
    expect((await dbService.getNoteById('cloud-note-revision'))!.content, 'Versione locale');

    final newer = echo.copyWith(content: 'Modifica', cloudRevision: 6, updatedAt: DateTime(2025));
    expect(await syncService.applyRemoteNote(newer), isTrue);
    expect((await dbService.getNoteById('cloud-note-revision'))!.content, 'Modifica');
  });

  test('First cloud preparation that fails leaves the app not configured', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = await syncService.initializeSupabase('http://[invalid', 'key');
    expect(saved, isFalse);
    expect(syncService.isConfigured, isFalse);
    expect(syncService.isSyncing, isFalse);
    await expectLater(AuthService(syncService).signInWithGoogle(), throwsException);
  });

  test('Stored cloud address and key are ignored; without build variables the app stays not configured', () async {
    SharedPreferences.setMockInitialValues({
      'supabase_url': 'https://example.supabase.co',
      'supabase_anon_key': 'anon-key',
    });
    await syncService.init();
    expect(syncService.isConfigured, isFalse);
    expect(syncService.isSyncing, isFalse);
  });

  test('Without build variables the not-configured notice names both missing variables', () async {
    expect(syncService.missingBuildVariables, ['SUPABASE_URL', 'SUPABASE_ANON_KEY']);
    expect(syncService.notConfiguredMessage,
        'Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY.');
    await expectLater(
      AuthService(syncService).signInWithGoogle(),
      throwsA(predicate((e) => e.toString().contains('Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY.'))),
    );
  });

  test('Google sign-in that fails to start returns false and leaves the user signed out', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await syncService.initializeSupabase('https://example.supabase.co', 'anon-key'), isTrue);
    final auth = AuthService(syncService);
    expect(await auth.signInWithGoogle(), isFalse);
    expect(auth.isAuthenticated, isFalse);
    expect(syncService.isAwaitingLogin, isFalse);
  });

  test('Cloud preparation without a kept session never shows the busy signal', () async {
    SharedPreferences.setMockInitialValues({});
    final busy = <bool>[];
    syncService.addListener(() => busy.add(syncService.isSyncing));
    expect(await syncService.initializeSupabase('https://example.supabase.co', 'anon-key'), isTrue);
    expect(busy, isNotEmpty);
    expect(busy, everyElement(isFalse));
    expect(syncService.isSyncing, isFalse);
  });

  test('Downloaded cloud note with a new title writes a new vault file and keeps the old one', () async {
    final local = Note(
      id: 'cloud-note-2',
      title: 'Titolo vecchio',
      content: 'Versione locale',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    final oldPath = await vaultService.saveNote(local);
    await dbService.upsertNote(local.copyWith(filePath: oldPath));

    final remote = Note(
      id: 'cloud-note-2',
      title: 'Titolo nuovo',
      content: 'Versione cloud',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2025),
    );
    expect(await syncService.applyRemoteNote(remote), isTrue);

    final stored = await dbService.getNoteById('cloud-note-2');
    final newPath = '${vaultService.vaultDir.path}/Titolo nuovo.md';
    expect(stored!.filePath, newPath);
    expect(stored.title, 'Titolo nuovo');

    final markdownFiles = vaultService.vaultDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .map((f) => f.path)
        .toList();
    expect(markdownFiles.length, 2);
    expect(markdownFiles, containsAll([oldPath, newPath]));
    expect(File(oldPath).readAsStringSync(), contains('Versione locale'));
    expect(File(newPath).readAsStringSync(), contains('Versione cloud'));
  });

  test('A cloud note stored during a sync emits a remote change; a skipped one does not', () async {
    await dbService.upsertNote(Note(
      id: 'cloud-note-4',
      title: 'Locale recente',
      content: 'Versione locale',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026),
      cloudRevision: 5,
    ));
    final events = <RemoteChange>[];
    final subscription = syncService.remoteChanges.listen(events.add);

    final older = Note(
      id: 'cloud-note-4',
      title: 'Cloud vecchio',
      content: 'Versione cloud',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2025),
      cloudRevision: 4,
    );
    expect(await syncService.applyRemoteNote(older), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty);

    final newer = older.copyWith(title: 'Cloud nuovo', updatedAt: DateTime(2027), cloudRevision: 6);
    expect(await syncService.applyRemoteNote(newer), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(events.single, isA<CloudNoteApplied>().having((e) => e.noteId, 'noteId', 'cloud-note-4'));
    expect((await dbService.getNoteById('cloud-note-4'))!.title, 'Cloud nuovo');

    await subscription.cancel();
  });

  test('Attachment references are found in note content', () {
    const content = '[{"type":"image","text":"attachments/att_1.png"},'
        '{"type":"drawing","text":"attachments/att_2.png"},{"text":"no image"}]';
    expect(SyncService.attachmentRefs(content), {'attachments/att_1.png', 'attachments/att_2.png'});
    expect(SyncService.attachmentRefs(''), isEmpty);
  });

  test('Attachment references with an absolute path are not vault references', () {
    const content = '[{"type":"image","text":"/home/u/Pictures/attachments/att_1.png"},'
        '{"type":"image","text":"C:\\\\pics\\\\attachments\\\\att_2.png"},'
        '{"type":"image","text":"attachments/att_3.png"}]';
    expect(SyncService.attachmentRefs(content), {'attachments/att_3.png'});
  });

  test('Awaiting login flag is off by default and toggles only when set', () {
    expect(syncService.isAwaitingLogin, isFalse);
    syncService.setAwaitingLogin(true);
    expect(syncService.isAwaitingLogin, isTrue);
    syncService.setAwaitingLogin(false);
    expect(syncService.isAwaitingLogin, isFalse);
  });

  test('Ending Awaiting login notifies listeners, so a failed return wakes the settings window', () {
    syncService.setAwaitingLogin(true);
    var notified = 0;
    void onChange() => notified++;
    syncService.addListener(onChange);
    syncService.setAwaitingLogin(false);
    syncService.removeListener(onChange);
    expect(syncService.isAwaitingLogin, isFalse);
    expect(notified, 1);
  });

  test('Sign-in run is complete when no sign-in has started a run', () async {
    await expectLater(syncService.signInRun, completes);
  });

  test('Cloud read takes every page and stops at the first short one', () async {
    final requested = <(int, int)>[];
    final rows = List.generate(7, (i) => {'id': 'n$i'});
    final all = await SyncService.readAllPages((from, to) async {
      requested.add((from, to));
      return rows.sublist(from.clamp(0, rows.length), (to + 1).clamp(0, rows.length));
    }, pageSize: 3);
    expect(all.map((r) => r['id']), ['n0', 'n1', 'n2', 'n3', 'n4', 'n5', 'n6']);
    expect(requested, [(0, 2), (3, 5), (6, 8)]);
  });
}
