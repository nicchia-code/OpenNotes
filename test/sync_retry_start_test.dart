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

  test('A start during the retry wait cancels the wait and restarts the series from 2 s', () async {
    const userId = '66666666-6666-4666-8666-666666666666';
    HttpOverrides.global = null;

    // The cloud fails while [failing] is set; each pull of notes is counted.
    var failing = true;
    var notesPulls = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final isPull = request.method == 'GET' && (request.uri.path == '/rest/v1/notes' || request.uri.path == '/rest/v1/folders');
      if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') notesPulls++;
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
    final tempDir = await Directory.systemTemp.createTemp('sync_retry_start_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    final connectivity = StreamController<List<ConnectivityResult>>();
    final triggers = SyncTriggers(
      connectivityChanges: connectivity.stream,
      checkConnectivity: () async => [ConnectivityResult.wifi],
      visibilityChanges: const Stream<bool>.empty(),
      initiallyVisible: true,
    );
    addTearDown(() async {
      await connectivity.close();
    });
    final syncService = SyncService(dbService, vaultService, triggers: triggers);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => syncService.retryDueAt != null && !syncService.isSyncing);
    expect(syncService.runState, SyncRunState.waitingToRetry);
    expect(notesPulls, 1);

    // A start during the 2 s wait runs at once; it fails again, so the next wait is the first one (2 s), not 5 s.
    await syncService.syncNow();
    expect(notesPulls, 2, reason: 'the start must run at once, not wait for the old timer');
    expect(syncService.runState, SyncRunState.waitingToRetry);
    final remaining = syncService.retryDueAt!.difference(DateTime.now());
    expect(remaining, lessThanOrEqualTo(const Duration(seconds: 2)));
    expect(remaining, greaterThan(const Duration(milliseconds: 1500)));

    // A start during this wait succeeds: the state goes back to idle and the old timer starts no run.
    failing = false;
    await syncService.syncNow();
    expect(syncService.retryDueAt, isNull, reason: 'a successful start must cancel the retry');
    expect(syncService.runState, SyncRunState.idle);
    expect(notesPulls, 3);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(notesPulls, 3, reason: 'the cancelled retry must not start another run');
    expect(syncService.runState, SyncRunState.idle);
  });
}
