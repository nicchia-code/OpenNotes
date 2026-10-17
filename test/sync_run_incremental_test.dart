import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a run after the first reads only the rows above the last revision, and a save carries its base revision',
      () async {
    const userId = '55555555-5555-4555-8555-555555555555';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);
    final earlier = DateTime.utc(2026, 10, 1, 9);
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'a', 'Prima', earlier));
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'b', 'Seconda', earlier));

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_run_incremental_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);

    final applied = <String>[];
    final subscription = syncService.remoteChanges.listen((change) {
      if (change is CloudNoteApplied) applied.add(change.noteId);
    });
    addTearDown(subscription.cancel);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    // Signing in starts a full check: it reads every row and keeps the highest revision it read.
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    expect(cloud.noteReads, [null]);
    expect(applied, unorderedEquals(['a', 'b']));
    final prefs = await SharedPreferences.getInstance();
    final lastRevision = cloud.revisionOf('b');
    expect(prefs.getInt(SyncService.lastRevisionKey), lastRevision);
    expect(prefs.getString(SyncService.lastCompletedAtKey), isNotNull);

    // Another device adds note c. This device edits note a, which it has at the revision the cloud gave it.
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'c', 'Altrove', DateTime.utc(2026, 10, 1, 10)));
    final baseOfA = cloud.revisionOf('a');
    final edited = (await dbService.getNoteById('a'))!
        .copyWith(title: 'Prima modificata', updatedAt: DateTime.now().toUtc());
    applied.clear();
    cloud.noteWrites.clear();
    cloud.noteReads.clear();
    await dbService.upsertNote(edited);
    await syncService.notifyNoteChanged(edited);

    await waitUntil(() => !syncService.isSyncing);
    expect(cloud.noteWrites, [('a', baseOfA)], reason: 'the save names the revision it is based on');
    expect(cloud.noteReads, ['gt.$lastRevision'], reason: 'the run reads only the rows above the last revision');
    expect(applied, ['c'], reason: 'the cloud copy of a is the echo of the save, which is not applied again');
    expect((await dbService.getNoteById('c'))!.title, 'Altrove');
    expect((await dbService.getNoteById('a'))!.title, 'Prima modificata');
    expect(prefs.getInt(SyncService.lastRevisionKey), cloud.revision);
  });
}
