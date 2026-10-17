import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/sync_triggers.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A full check owed by a retry is remembered when the network drops, and the return of the network runs it', () async {
    const userId = '88888888-8888-4888-8888-888888888888';
    HttpOverrides.global = null;

    // The cloud fails while [failing] is set. Each pull of notes is recorded: a full check has no revision filter,
    // an incremental run filters by revision.
    var failing = false;
    final notePulls = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final isPull = request.method == 'GET' && (request.uri.path == '/rest/v1/notes' || request.uri.path == '/rest/v1/folders');
      if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') {
        notePulls.add(request.uri.queryParameters.containsKey('revision') ? 'incremental' : 'full');
      }
      if (isPull && failing) {
        request.response.statusCode = 500;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"message":"unavailable"}');
      } else if (isPull) {
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('[]');
      } else if (request.uri.path == '/auth/v1/logout') {
        request.response.statusCode = 204;
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });

    final expiresAt = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    SharedPreferences.setMockInitialValues({
      'sb-127-auth-token': jsonEncode({
        'access_token': 'test-access',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': expiresAt,
        'refresh_token': 'test-refresh',
        'user': {
          'id': userId,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'test@example.com',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2024-01-01T00:00:00Z',
        },
      }),
    });

    Future<void> waitUntil(bool Function() condition) async {
      for (var i = 0; i < 300 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_network_full_check_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    final connectivity = StreamController<List<ConnectivityResult>>();
    addTearDown(() async {
      await connectivity.close();
    });
    final triggers = SyncTriggers(
      connectivityChanges: connectivity.stream,
      checkConnectivity: () async => [ConnectivityResult.wifi],
      visibilityChanges: const Stream<bool>.empty(),
      initiallyVisible: true,
    );
    final syncService = SyncService(dbService, vaultService, triggers: triggers);

    // A first run completes, so the device has a last revision and later runs may be incremental.
    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => syncService.lastSyncedAt != null && !syncService.isSyncing);
    expect(syncService.lastSyncedAt, isNotNull, reason: 'the startup run must complete');
    notePulls.clear();

    // A full check fails: the retry is scheduled and owes a full check.
    failing = true;
    await syncService.syncNow();
    expect(syncService.runState, SyncRunState.waitingToRetry);
    expect(notePulls, ['full'], reason: 'the manual request is a full check');

    // The network drops during the wait: the retry is cancelled and no run starts.
    connectivity.add([ConnectivityResult.none]);
    await waitUntil(() => syncService.runState == SyncRunState.offline);
    expect(syncService.retryDueAt, isNull);
    expect(syncService.runState, SyncRunState.offline);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(notePulls, ['full'], reason: 'the cancelled retry must not start a run while offline');

    // The return of the network runs at once, as the full check that was owed.
    failing = false;
    connectivity.add([ConnectivityResult.wifi]);
    await waitUntil(() => notePulls.length == 2 && !syncService.isSyncing);
    expect(notePulls, ['full', 'full'], reason: 'the return of the network must run the full check the retry owed');
    expect(syncService.runState, SyncRunState.idle);
  });
}
