import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Session renewal refreshes the token and starts a sync run', () async {
    const userId = '44444444-4444-4444-8444-444444444444';
    HttpOverrides.global = null;

    var notesGets = 0;
    var refreshes = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final session = {
        'access_token': 'renewed-access',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'refresh_token': 'renewed-refresh',
        'user': {
          'id': userId,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'test@example.com',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2024-01-01T00:00:00Z',
        },
      };
      if (request.uri.path == '/auth/v1/token') {
        refreshes++;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(session));
      } else if (request.uri.path == '/rest/v1/notes' && request.method == 'GET') {
        notesGets++;
        request.response.headers.contentType = ContentType.json;
        request.response.write('[]');
      } else if (request.uri.path == '/rest/v1/folders' && request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        request.response.write('[]');
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
    final tempDir = await Directory.systemTemp.createTemp('sync_token_refresh_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => notesGets > 0 && !syncService.isSyncing);
    expect(syncService.isAuthenticated, isTrue);
    final getsAfterStartup = notesGets;

    await Supabase.instance.client.auth.refreshSession();
    await waitUntil(() => refreshes > 0 && Supabase.instance.client.auth.currentSession?.accessToken == 'renewed-access');
    await waitUntil(() => notesGets > getsAfterStartup && !syncService.isSyncing);

    expect(refreshes, greaterThan(0));
    expect(notesGets, greaterThan(getsAfterStartup), reason: 'a session renewal must start a sync run');
    expect(syncService.isSyncing, isFalse);
  });
}
