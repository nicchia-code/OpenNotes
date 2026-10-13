import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_service.dart';

/// Handles user authentication via Supabase Auth (Google SSO).
class AuthService extends ChangeNotifier {
  final SyncService _syncService;
  HttpServer? _oauthServer;

  AuthService(this._syncService);

  /// The Supabase client, available only once the cloud connection is ready.
  SupabaseClient? get _client {
    if (!_syncService.isConfigured) return null;
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
    if (client == null) {
      throw Exception(_syncService.notConfiguredMessage ?? 'Supabase non è ancora configurato.');
    }

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

    _syncService.setAwaitingLogin(true);
    bool opened;
    try {
      opened = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } on PlatformException catch (e) {
      // url_launcher throws when the browser cannot be opened: same outcome as `false`.
      debugPrint('Impossibile aprire il browser: $e');
      opened = false;
    } catch (e) {
      // Any other start failure (e.g. a cloud service error) leaves the user signed out, like `false`.
      debugPrint('Avvio accesso Google fallito: $e');
      opened = false;
    }
    if (!opened) await _abortSignIn();
    return opened;
  }

  /// Ends a sign-in that did not reach the browser: closes the local return server, then leaves Awaiting login.
  Future<void> _abortSignIn() async {
    await _oauthServer?.close(force: true);
    _oauthServer = null;
    _syncService.setAwaitingLogin(false);
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
          _syncService.setAwaitingLogin(false);
        } finally {
          await request.response.close();
          await server.close(force: true);
          _oauthServer = null;
        }
      } else if (fullUri.queryParameters.containsKey('error')) {
        final err = fullUri.queryParameters['error_description'] ?? fullUri.queryParameters['error'] ?? 'Errore sconosciuto';
        request.response.write('<h2>Errore autenticazione: $err</h2>');
        _syncService.setAwaitingLogin(false);
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

  /// Signs out on this device. Returns false when the cloud session could not be closed (e.g. no network):
  /// the local sign-out still happens, the cloud session expires on its own.
  Future<bool> signOut() async {
    final client = _client;
    if (client == null) return true;
    var closedOnCloud = true;
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Sessione cloud non chiusa: $e');
      closedOnCloud = false;
    }
    notifyListeners();
    return closedOnCloud;
  }
}
