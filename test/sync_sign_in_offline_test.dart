import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/sync_triggers.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton, bound to the first cloud address it is given.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a sign-in while offline starts no run, announces no outcome, and remembers the full check', () async {
    const userId = '88888888-8888-4888-8888-888888888888';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server)..signInUserId = userId;

    // Signed out until the sign-in; the device has a last revision, so only a remembered full check reads every row.
    SharedPreferences.setMockInitialValues({SyncService.lastRevisionKey: 42});
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_sign_in_offline_vault_');
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

    // The window waits for the return from the browser; the password sign-in stands in for it.
    syncService.setAwaitingLogin(true);
    await Supabase.instance.client.auth.signInWithPassword(email: 'test@example.com', password: 'test-password');
    await waitUntil(() => !syncService.isAwaitingLogin);

    expect(syncService.signInRunStarted, isFalse, reason: 'no sync run starts while the system reports no connection');
    expect(syncService.isSyncing, isFalse);
    expect(cloud.noteReads, isEmpty);

    // The network returns: the full check the sign-in asked for runs, not an incremental one.
    connectivity.add([ConnectivityResult.wifi]);
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    expect(cloud.noteReads, [null], reason: 'the return of the network runs the full check the sign-in asked for');
  });
}
