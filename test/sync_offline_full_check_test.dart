import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/sync_triggers.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a sign-in while offline remembers a full check, which runs when the network returns', () async {
    const userId = '99999999-9999-4999-8999-999999999999';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);

    // The device has a last revision, so without the remembered check the return would be an incremental run.
    SharedPreferences.setMockInitialValues(
      signedInPreferences(userId, extra: {SyncService.lastRevisionKey: 42}),
    );
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_offline_full_check_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    final connectivity = StreamController<List<ConnectivityResult>>();
    final visibility = StreamController<bool>();
    addTearDown(() async {
      await connectivity.close();
      await visibility.close();
    });
    final triggers = SyncTriggers(
      connectivityChanges: connectivity.stream,
      checkConnectivity: () async => [ConnectivityResult.none],
      visibilityChanges: visibility.stream,
      initiallyVisible: true,
    );
    addTearDown(triggers.dispose);
    final syncService = SyncService(dbService, vaultService, triggers: triggers);
    addTearDown(syncService.dispose);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(syncService.runState, SyncRunState.offline);
    expect(cloud.noteReads, isEmpty, reason: 'no run starts while the system reports no connection');

    // The network returns: the remembered full check runs, not an incremental one.
    connectivity.add([ConnectivityResult.wifi]);
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    expect(cloud.noteReads, [null], reason: 'the return of the network runs the full check the sign-in asked for');
    expect(syncService.runState, SyncRunState.idle);
  });
}
