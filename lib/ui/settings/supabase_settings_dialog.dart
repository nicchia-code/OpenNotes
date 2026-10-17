import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/vault_service.dart';
import '../theme/apple_theme.dart';
import '../sync/sync_status_label.dart';
import '../sync/sync_state_glyph.dart';

/// Text the settings window shows when the sign-in sync run ends: success, or its failure with the retry wait.
String signInSyncOutcomeMessage(SyncErrorCategory? failure, DateTime? retryDueAt, {DateTime? now}) {
  if (failure == null) return 'Sincronizzazione completata con successo.';
  final label = syncErrorCategoryLabel(failure);
  if (retryDueAt == null) return 'Sincronizzazione non riuscita: $label.';
  final seconds = syncRetryCountdown(retryDueAt, now: now);
  return 'Sincronizzazione non riuscita: $label. Nuovo tentativo tra $seconds s';
}

/// Where the sign-in sync run stands in the settings window: none, running after the sign-in, or finished.
enum _SignInSync { none, running, finished }

/// Modal for managing Supabase Cloud Sync, Authentication, and Vault location.
class SupabaseSettingsDialog extends StatefulWidget {
  const SupabaseSettingsDialog({super.key});

  @override
  State<SupabaseSettingsDialog> createState() => _SupabaseSettingsDialogState();
}

class _SupabaseSettingsDialogState extends State<SupabaseSettingsDialog> {
  bool _isConnecting = false;
  String? _statusMessage;
  bool _isError = false;
  _SignInSync _signInSync = _SignInSync.none;
  Timer? _ticker;
  SyncService? _listenedSync;
  /// Changes the sync has set aside, listed under "Non sincronizzate" in the signed-in view.
  List<SetAsideChange> _setAside = const [];
  int _setAsideLoad = 0;
  /// Counts the sign-in requests; a request superseded by a newer one stops updating the window.
  int _signInAttempt = 0;
  static const _browserOpeningMessage = 'Apertura browser per autenticazione Google...';

  @override
  void initState() {
    super.initState();
    // The status lines (retry countdown, time since the last sync) are redrawn each second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The list of set-aside changes follows every change of the SyncService, as the rest of the window does.
    final sync = context.read<SyncService>();
    if (identical(sync, _listenedSync)) return;
    _listenedSync?.removeListener(_reloadSetAside);
    _listenedSync = sync..addListener(_reloadSetAside);
    _reloadSetAside();
  }

  /// Reads the changes the sync has set aside; a read that is overtaken by a later one is dropped.
  Future<void> _reloadSetAside() async {
    final load = ++_setAsideLoad;
    final changes = await _listenedSync!.setAsideChanges();
    if (mounted && load == _setAsideLoad) setState(() => _setAside = changes);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _listenedSync?.removeListener(_reloadSetAside);
    super.dispose();
  }

  Future<void> _handleSignOut(AuthService auth) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Disconnessione in corso...';
      _signInSync = _SignInSync.none;
      _isError = false;
    });

    try {
      final closedOnCloud = await auth.signOut();
      if (mounted) {
        setState(() {
          _statusMessage = closedOnCloud
              ? null
              : 'Disconnesso da questo dispositivo. La sessione sul cloud non è stata chiusa perché manca la connessione: scadrà da sola.';
          _isError = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn(AuthService auth) async {
    // A new request supersedes the one still awaiting the browser: only the latest attempt updates the window.
    final attempt = ++_signInAttempt;
    bool isCurrent() => mounted && attempt == _signInAttempt;
    setState(() {
      _isConnecting = true;
      _statusMessage = _browserOpeningMessage;
      _isError = false;
      _signInSync = _SignInSync.none;
    });

    try {
      final success = await auth.signInWithGoogle();
      if (!isCurrent()) return;
      if (!success) {
        setState(() {
          _statusMessage = 'Accesso Google non completato.';
          _isError = true;
        });
      } else {
        final sync = context.read<SyncService>();
        await _waitUntil(sync, () => !sync.isAwaitingLogin || attempt != _signInAttempt);
        if (!isCurrent()) return;
        if (!sync.isAuthenticated) {
          setState(() {
            _statusMessage = 'Accesso Google non completato.';
            _isError = true;
          });
          return;
        }
        if (!sync.signInRunStarted) {
          // Model: an access while offline starts no sync run, so the window announces no outcome; the offline status
          // of the sync shows instead.
          setState(() => _statusMessage = null);
          return;
        }
        setState(() {
          _statusMessage = null;
          _signInSync = _SignInSync.running;
        });
        // The window waits for the end of the first run the sign-in started, not for the runs that run starts after it,
        // which the sync status shows. That run may already have ended.
        await sync.signInRun;
        if (!isCurrent()) return;
        setState(() => _signInSync = _SignInSync.finished);
      }
    } catch (e) {
      if (isCurrent()) {
        // Missing build variables: show the exact notice, without the "Errore:" prefix.
        final notice = context.read<SyncService>().notConfiguredMessage;
        setState(() {
          _statusMessage = notice ?? 'Errore: ${e.toString().replaceAll('Exception:', '')}';
          _isError = true;
        });
      }
    } finally {
      if (isCurrent()) {
        setState(() => _isConnecting = false);
      }
    }
  }

  /// The sign-in sync line, read live from the SyncService: a run that fails or retries later is shown as it happens.
  ({String text, bool isError})? _signInSyncLine(SyncService sync) => switch (_signInSync) {
        _SignInSync.none => null,
        _SignInSync.running => (text: 'Accesso completato! Sincronizzazione in corso...', isError: false),
        // A retry of a failed sign-in run shows it running; a later run after a success leaves the outcome announced.
        _SignInSync.finished when sync.isSyncing && sync.lastFailure != null => (text: syncStatusText(SyncRunState.running), isError: false),
        _SignInSync.finished => (
            text: signInSyncOutcomeMessage(sync.lastFailure, sync.retryDueAt),
            isError: sync.lastFailure != null,
          ),
      };

  /// Waits until [isDone] holds, checked again after every change of the SyncService.
  Future<void> _waitUntil(SyncService sync, bool Function() isDone) async {
    if (isDone()) return;
    final done = Completer<void>();
    void onChange() {
      if (isDone() && !done.isCompleted) done.complete();
    }

    sync.addListener(onChange);
    try {
      await done.future;
    } finally {
      sync.removeListener(onChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final auth = context.watch<AuthService>();
    final vault = context.read<VaultService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final retryDueAt = sync.retryDueAt;
    final signInLine = _signInSyncLine(sync);
    // Model (Awaiting login): the window keeps saying the browser is being opened until the return.
    final awaitingBrowser = sync.isAwaitingLogin && !auth.isAuthenticated;
    final statusText = sync.signInError != null
        ? 'Accesso non completato: ${sync.signInError}'
        : (signInLine?.text ?? _statusMessage ?? (awaitingBrowser ? _browserOpeningMessage : null));
    final statusIsError = sync.signInError != null || (signInLine?.isError ?? _isError);

    return Dialog(
      backgroundColor: isDark ? AppleTheme.darkSidebar : AppleTheme.lightSidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppleTheme.accentYellow.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.cloud_upload_fill, color: AppleTheme.accentYellow, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sincronizzazione Cloud',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Local Vault Info
              Text(
                'VAULT LOCALE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppleTheme.darkCard : AppleTheme.lightCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.folder_fill, color: AppleTheme.accentYellow, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vault.vaultDir.path,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Account & Cloud Sync Section
              Text(
                'ACCOUNT & SINCRONIZZAZIONE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              if (auth.isAuthenticated) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.person_crop_circle_badge_checkmark, color: CupertinoColors.activeGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Accesso eseguito: ${auth.currentUser?.email ?? 'Account Google'}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Disconnetti', style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13)),
                        onPressed: () => _handleSignOut(auth),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SyncStateGlyph(
                      state: sync.runState,
                      color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      syncStatusText(
                        sync.runState,
                        failure: sync.lastFailure,
                        retryInSeconds: retryDueAt == null ? 0 : syncRetryCountdown(retryDueAt),
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  syncLastSyncedLabel(sync.lastSyncedAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modifiche in attesa: ${sync.pendingChangeCount}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                  ),
                ),
                if (sync.runState == SyncRunState.waitingToRetry && retryDueAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${syncErrorCategoryLabel(sync.lastFailure ?? SyncErrorCategory.unexpected)}. '
                    'Nuovo tentativo tra ${syncRetryCountdown(retryDueAt)} s',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.destructiveRed),
                  ),
                ],
                if (_setAside.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'NON SINCRONIZZATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final change in _setAside)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppleTheme.darkCard : AppleTheme.lightCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(change.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          const Text(
                            'Il cloud ha rifiutato la modifica',
                            style: TextStyle(fontSize: 12, color: CupertinoColors.destructiveRed),
                          ),
                          Row(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Text('Riprova', style: TextStyle(fontSize: 13, color: CupertinoColors.activeBlue)),
                                onPressed: () => sync.retrySetAsideChange(change.entityType, change.entityId),
                              ),
                              if (change.cloudHasCopy) ...[
                                const SizedBox(width: 16),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Text(
                                    'Usa la versione del cloud',
                                    style: TextStyle(fontSize: 13, color: CupertinoColors.activeBlue),
                                  ),
                                  onPressed: () => sync.useCloudVersion(change.entityType, change.entityId),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 14),
                CupertinoButton(
                  color: AppleTheme.accentYellow,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: sync.isSyncing ? null : () => sync.syncNow(),
                  child: sync.isSyncing
                      ? const CupertinoActivityIndicator(color: CupertinoColors.black)
                      : const Text(
                          'Sincronizza Adesso',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CupertinoColors.black),
                        ),
                ),
              ] else ...[
                Text(
                  'Accedi con il tuo account Google per sincronizzare automaticamente le note e le modifiche con il cloud.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                CupertinoButton(
                  color: AppleTheme.accentYellow,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onPressed: _isConnecting ? null : () => _handleGoogleSignIn(auth),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isConnecting) ...[
                        const CupertinoActivityIndicator(color: CupertinoColors.black),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Icon(CupertinoIcons.globe, size: 18, color: CupertinoColors.black),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _isConnecting ? 'Accesso in corso...' : 'Accedi con Google',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (statusText != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusIsError ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (awaitingBrowser) ...[
                      const SizedBox(width: 16),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          "Riprova l'accesso",
                          style: TextStyle(fontSize: 13, color: CupertinoColors.activeBlue),
                        ),
                        onPressed: () => _handleGoogleSignIn(auth),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
