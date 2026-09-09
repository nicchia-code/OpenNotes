import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles user authentication via Supabase Auth (Google SSO).
class AuthService extends ChangeNotifier {
  HttpServer? _oauthServer;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  /// Sign In with Google SSO (OAuth) with desktop loopback support
  Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) throw Exception('Supabase non è ancora configurato.');

    String? redirectUrl;

    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      await _oauthServer?.close(force: true);
      try {
        _oauthServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
        redirectUrl = 'http://localhost:3000';
        _listenForOAuthCallback(_oauthServer!, client);
      } catch (e) {
        debugPrint('Errore bind porta 3000 per OAuth: $e');
        redirectUrl = 'opennotes://login-callback';
      }
    } else if (!kIsWeb) {
      redirectUrl = 'opennotes://login-callback';
    }

    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  void _listenForOAuthCallback(HttpServer server, SupabaseClient client) {
    server.listen((HttpRequest request) async {
      final uri = request.uri;
      final fullUri = Uri.parse('http://localhost:${server.port}${uri.toString()}');

      request.response.headers.contentType = ContentType.html;

      if (fullUri.queryParameters.containsKey('code') || fullUri.queryParameters.containsKey('access_token')) {
        try {
          await client.auth.getSessionFromUrl(fullUri);
          notifyListeners();
          request.response.write('''
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"><title>OpenNotes - Accesso riuscito</title></head>
            <body style="font-family: system-ui, sans-serif; display: flex; align-items: center; justify-content: center; height: 80vh; background: #1c1c1e; color: #fff;">
              <div style="text-align: center; padding: 30px; background: #2c2c2e; border-radius: 12px;">
                <h2 style="color: #34c759;">Accesso completato con successo!</h2>
                <p style="color: #a1a1a6;">Puoi chiudere questa scheda e tornare su OpenNotes.</p>
              </div>
              <script>setTimeout(() => window.close(), 1500);</script>
            </body>
            </html>
          ''');
        } catch (e) {
          request.response.write('<h2>Errore sessione: $e</h2>');
        } finally {
          await request.response.close();
          await server.close(force: true);
          _oauthServer = null;
        }
      } else if (fullUri.queryParameters.containsKey('error')) {
        final err = fullUri.queryParameters['error_description'] ?? fullUri.queryParameters['error'] ?? 'Errore sconosciuto';
        request.response.write('<h2>Errore autenticazione: $err</h2>');
        await request.response.close();
        await server.close(force: true);
        _oauthServer = null;
      } else {
        // Forward potential fragment parameters (#access_token=...)
        request.response.write('''
          <!DOCTYPE html>
          <html>
          <body>
            <script>
              if (window.location.hash) {
                window.location.href = '/?' + window.location.hash.substring(1);
              } else {
                document.body.innerHTML = '<h2>In attesa...</h2>';
              }
            </script>
          </body>
          </html>
        ''');
        await request.response.close();
      }
    });
  }

  /// Sign Out
  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
      notifyListeners();
    }
  }
}
