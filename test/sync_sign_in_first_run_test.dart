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

  test('a sign-in waits for the first run it starts, not for a run that run starts after it', () async {
    const userId = '99999999-9999-4999-8999-999999999999';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server)..signInUserId = userId;

    SharedPreferences.setMockInitialValues({SyncService.lastRevisionKey: 42});
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_sign_in_first_run_vault_');
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
    final syncService = SyncService(dbService, vaultService, triggers: triggers);
    addTearDown(syncService.dispose);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // The first run of the sign-in is held up at its cloud read, so a run requested meanwhile is remembered for it.
    cloud.delayNextNoteRead = const Duration(milliseconds: 400);
    syncService.setAwaitingLogin(true);
    await Supabase.instance.client.auth.signInWithPassword(email: 'test@example.com', password: 'test-password');
    await waitUntil(() => !syncService.isAwaitingLogin);
    expect(syncService.signInRunStarted, isTrue);
    await waitUntil(() => cloud.noteReads.isNotEmpty);

    // A request during the first run makes one more run after it (the app returns to the foreground twice: the
    // second change of visibility is the signal); that run is held up at its cloud read.
    visibility.add(false);
    visibility.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    cloud.delayNextNoteRead = const Duration(seconds: 2);

    await syncService.signInRun;
    expect(syncService.isSyncing, isTrue, reason: 'the window is released by the first run; the next run goes on');

    await waitUntil(() => !syncService.isSyncing);
    expect(cloud.noteReads, hasLength(2), reason: 'the run after the first one still ran');
  });
}
