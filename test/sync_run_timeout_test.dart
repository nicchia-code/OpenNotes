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

  test('a request that does not answer fails the run within its limit, and the next run starts by itself', () async {
    const userId = '88888888-8888-4888-8888-888888888888';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_run_timeout_vault_');
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
      checkConnectivity: () async => [ConnectivityResult.wifi],
      visibilityChanges: visibility.stream,
      initiallyVisible: true,
    );
    addTearDown(triggers.dispose);
    final syncService = SyncService(
      dbService,
      vaultService,
      triggers: triggers,
      requestTimeout: const Duration(milliseconds: 300),
    );
    addTearDown(syncService.dispose);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.lastFailure, isNull);

    // The cloud takes the next request and never answers it.
    cloud.hangNextNoteRead = true;
    final readsBefore = cloud.noteReads.length;
    final started = DateTime.now();
    await syncService.syncNow();
    final failedAfter = DateTime.now().difference(started);

    expect(syncService.lastFailure, SyncErrorCategory.timeout);
    expect(syncService.runState, SyncRunState.waitingToRetry);
    expect(failedAfter, lessThan(const Duration(seconds: 2)), reason: 'the request gave up at its limit, before the retry');

    // The retry starts by itself, after the first wait, and completes.
    await waitUntil(() => cloud.noteReads.length > readsBefore + 1 && !syncService.isSyncing);
    expect(syncService.lastFailure, isNull);
    expect(syncService.lastSyncedAt, isNotNull);
    expect(syncService.runState, SyncRunState.idle);
  });
}
