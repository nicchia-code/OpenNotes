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

  test('a never-synced note the cloud refuses is counted on its queued save and the run goes on', () async {
    const userId = '77777777-7777-4777-8777-777777777777';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);
    final earlier = DateTime.utc(2026, 10, 1, 9);
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'dal-cloud', 'Dal cloud', earlier));
    cloud.refusedNoteIds.add('rifiutata');

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_unsynced_refusal_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    final now = DateTime.utc(2026, 10, 1, 10);
    for (final id in ['accettata', 'rifiutata']) {
      await dbService.upsertNote(
        Note(id: id, title: 'Nota $id', content: '', createdAt: now, updatedAt: now),
      );
    }

    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);
    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);

    expect(syncService.lastFailure, isNull, reason: 'a refused note does not fail the run');
    expect(syncService.lastSyncedAt, isNotNull, reason: 'the run completed');
    expect(cloud.notes.containsKey('accettata'), isTrue, reason: 'the other unsynced note is sent');
    expect(cloud.notes.containsKey('rifiutata'), isFalse);
    expect((await dbService.getNoteById('accettata'))!.syncedAt, isNotNull);
    expect((await dbService.getNoteById('rifiutata'))!.syncedAt, isNull);
    expect(await dbService.getNoteById('dal-cloud'), isNotNull, reason: 'the run goes on to apply the cloud notes');

    final refused = (await dbService.getPendingSyncActions()).where((p) => p['entity_id'] == 'rifiutata').single;
    expect(refused['attempts'], 1, reason: 'the refusal is counted on the queued save');
    expect(refused['last_error'], isNotNull);
  });
}
