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

  test('a run in which nothing changed in the cloud rewrites no note and sends nothing', () async {
    const userId = '66666666-6666-4666-8666-666666666666';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);
    final earlier = DateTime.utc(2026, 10, 1, 9);
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'a', 'Invariata', earlier));
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'b', 'Anche questa', earlier));

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_run_unchanged_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);

    final changes = <RemoteChange>[];
    final subscription = syncService.remoteChanges.listen(changes.add);
    addTearDown(subscription.cancel);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);
    final stored = {for (final id in ['a', 'b']) id: (await dbService.getNoteById(id))!};

    // Nothing changed in the cloud: the next run reads the rows, applies none and writes none.
    changes.clear();
    cloud.noteWrites.clear();
    await syncService.syncNow();

    expect(cloud.noteWrites, isEmpty, reason: 'no save is sent by a run without local changes');
    expect(changes.whereType<CloudNoteApplied>(), isEmpty, reason: 'no cloud copy is applied again');
    for (final id in ['a', 'b']) {
      final note = await dbService.getNoteById(id);
      expect(note!.updatedAt, stored[id]!.updatedAt, reason: 'the note $id is not rewritten');
      expect(note.cloudRevision, stored[id]!.cloudRevision, reason: 'the note $id keeps its revision');
    }
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(SyncService.lastRevisionKey), cloud.revision);
  });
}
