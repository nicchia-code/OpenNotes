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

  test('a local copy queued by the first full check is sent by the run that follows, not at the next interval', () async {
    const userId = '66666666-6666-4666-8666-666666666666';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);
    final earlier = DateTime.utc(2026, 10, 1, 9);
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'a', 'Nel cloud', earlier));

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_full_check_queue_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    // The device has note a from before the revisions: synced, with no cloud revision, and edited after the cloud copy.
    await dbService.upsertNote(
      Note(
        id: 'a',
        title: 'Sul dispositivo',
        content: '',
        createdAt: earlier,
        updatedAt: DateTime.utc(2026, 10, 1, 12),
        syncedAt: earlier,
      ),
    );

    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);
    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');

    // The full check queues the newer local copy; the run it asks for sends it, well before the 60 s interval.
    await waitUntil(() => cloud.notes['a']?['title'] == 'Sul dispositivo' && !syncService.isSyncing);
    expect(cloud.notes['a']!['title'], 'Sul dispositivo');
  });
}
