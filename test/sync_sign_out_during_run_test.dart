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

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signing out during a run stops it before the next cloud request, without a retry', () async {
    const userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);
    // The first read of the notes answers late, so the sign-out happens while the run is in progress.
    cloud.delayNextNoteRead = const Duration(milliseconds: 400);

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_sign_out_during_run_vault_');
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

    await syncService.initializeSupabase('http://127.0.0.1:${cloud.port}', 'test-anon-key');
    await waitUntil(() => cloud.noteReads.isNotEmpty && syncService.isSyncing);

    await Supabase.instance.client.auth.signOut();
    await waitUntil(() => !syncService.isSyncing);
    // Long enough for the delayed read to answer and for any further request to be sent.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(cloud.noteReads, hasLength(1), reason: 'the run must not read again after sign-out');
    expect(cloud.folderReads, 0, reason: 'no request may go to the cloud without a session');
    expect(syncService.retryDueAt, isNull, reason: 'a run stopped by sign-out schedules no retry');
    expect(syncService.runState, SyncRunState.idle);
  });
}
