import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requests that arrive during a run start one further run, a full check when one of them asked for it', () async {
    const userId = '77777777-7777-4777-8777-777777777777';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_run_remembered_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);

    // The next run reads slowly, so the requests below arrive while it is running.
    cloud.delayNextNoteRead = const Duration(milliseconds: 400);
    final foldersBefore = cloud.folderReads;
    final readsBefore = cloud.noteReads.length;
    final running = syncService.syncNow();
    await waitUntil(() => cloud.noteReads.length > readsBefore);

    final now = DateTime.now();
    final first = Note(id: 'during-1', title: 'Durante il giro', content: '', createdAt: now, updatedAt: now);
    final second = Note(id: 'during-2', title: 'Anche questa', content: '', createdAt: now, updatedAt: now);
    await dbService.upsertNote(first);
    await syncService.notifyNoteChanged(first);
    await dbService.upsertNote(second);
    await syncService.notifyNoteChanged(second);
    final remembered = syncService.syncNow();

    await running;
    await remembered;

    expect(cloud.folderReads - foldersBefore, 2, reason: 'the run in progress and exactly one further run');
    expect(cloud.noteReads.sublist(readsBefore), [null, null],
        reason: 'the further run is a full check, because a request asked for one');
    expect(cloud.notes.containsKey('during-1'), isTrue, reason: 'a save made during the run reaches the cloud');
    expect(cloud.notes.containsKey('during-2'), isTrue);

    // Nothing else starts after that one further run.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(cloud.folderReads - foldersBefore, 2);
    expect(syncService.isSyncing, isFalse);
  });
}
