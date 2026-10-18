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

  test('a run started while the interval is armed cancels that interval; the count restarts after the run', () async {
    const userId = '66666666-6666-4666-8666-666666666666';
    HttpOverrides.global = null;

    // Each pull of notes is counted; the second run's pull is held for 1.5 s, longer than the 1 s interval.
    var notesPulls = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final isNotesPull = request.method == 'GET' && request.uri.path == '/rest/v1/notes';
      if (isNotesPull) notesPulls++;
      if (isNotesPull && notesPulls == 2) await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (request.method == 'GET' && (isNotesPull || request.uri.path == '/rest/v1/folders')) {
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
      for (var i = 0; i < 400 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_interval_restart_vault_');
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
      syncInterval: const Duration(seconds: 1),
    );
    addTearDown(() async {
      await connectivity.close();
    });
    final syncService = SyncService(dbService, vaultService, triggers: triggers);
    addTearDown(syncService.dispose);

    // The start-up run ends and arms the 1 s interval.
    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => notesPulls == 1 && !syncService.isSyncing);
    expect(notesPulls, 1);

    // A request starts a run at once; it outlasts the armed interval. The interval must not start a run during it.
    unawaited(syncService.syncNow());
    await waitUntil(() => notesPulls == 2 && syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);
    expect(notesPulls, 2);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(notesPulls, 2, reason: 'the cancelled interval must not start an extra run right after the run');

    // The count restarts from the end of that run: one minute's worth of time (here 1 s) later, a run starts again.
    await waitUntil(() => notesPulls == 3);
    expect(notesPulls, 3);
  });
}
