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
import 'package:supabase_flutter/supabase_flutter.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Signing out cancels the scheduled retry and the sync goes back to rest', () async {
    const userId = '55555555-5555-4555-8555-555555555555';
    HttpOverrides.global = null;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') {
        // Every pull fails, so the first run schedules a retry.
        request.response.statusCode = 500;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"message":"unavailable"}');
      } else if (request.uri.path == '/rest/v1/folders' && request.method == 'GET') {
        request.response.statusCode = 500;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"message":"unavailable"}');
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
    final tempDir = await Directory.systemTemp.createTemp('sync_sign_out_retry_vault_');
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
      triggers.dispose();
      await connectivity.close();
    });
    final syncService = SyncService(dbService, vaultService, triggers: triggers);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => syncService.retryDueAt != null && !syncService.isSyncing);
    expect(syncService.retryDueAt, isNotNull, reason: 'the failed startup run must schedule a retry');
    expect(syncService.runState, SyncRunState.waitingToRetry);

    await Supabase.instance.client.auth.signOut();
    await waitUntil(() => Supabase.instance.client.auth.currentUser == null);
    // Well before the 2 s retry wait ends: the cancelled retry must already be gone.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(syncService.retryDueAt, isNull, reason: 'sign-out must cancel the scheduled retry');
    expect(syncService.runState, SyncRunState.idle);
  });
}
