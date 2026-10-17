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

  test('Offline: no automatic run starts, no retry is scheduled, a manual run still tries', () async {
    const userId = '77777777-7777-4777-8777-777777777777';
    HttpOverrides.global = null;

    // The cloud always fails; each pull of notes is counted.
    var notesPulls = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') notesPulls++;
      if (request.uri.path == '/rest/v1/notes' || request.uri.path == '/rest/v1/folders') {
        request.response.statusCode = 500;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"message":"unavailable"}');
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

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 300));

    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_offline_vault_');
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
    final syncService = SyncService(dbService, vaultService, triggers: triggers);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await settle();
    expect(syncService.runState, SyncRunState.offline);
    expect(notesPulls, 0, reason: 'session start must not run while offline');

    // Losing the network, returning to the foreground: no run, no retry.
    visibility.add(false);
    visibility.add(true);
    await settle();
    expect(notesPulls, 0, reason: 'return to the foreground must not run while offline');
    expect(syncService.retryDueAt, isNull);
    expect(syncService.runState, SyncRunState.offline);

    // A request made by hand still tries; its failure leads to Offline, not to Waiting to retry.
    await syncService.syncNow();
    expect(notesPulls, 1, reason: 'a manual request runs while offline');
    expect(syncService.retryDueAt, isNull, reason: 'a failed run while offline schedules no retry');
    expect(syncService.runState, SyncRunState.offline);
    await settle();
    expect(notesPulls, 1, reason: 'no automatic retry may follow the failed run');

    // The return of the network starts a run at once.
    connectivity.add([ConnectivityResult.wifi]);
    await settle();
    expect(notesPulls, 2, reason: 'the return of the network must start a run');
    expect(syncService.runState, SyncRunState.waitingToRetry);
  });
}
