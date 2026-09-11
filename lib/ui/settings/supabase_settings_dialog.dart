import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/vault_service.dart';
import '../theme/apple_theme.dart';

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

  Future<void> _handleGoogleSignIn(AuthService auth) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Apertura browser per autenticazione Google...';
      _isError = false;
    });

    try {
      final success = await auth.signInWithGoogle();
      if (!success && mounted) {
        setState(() {
          _statusMessage = 'Accesso Google non completato.';
          _isError = true;
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Accesso completato! Sincronizzazione in corso...';
          _isError = false;
        });
        await context.read<SyncService>().syncNow();
        if (mounted) {
          setState(() {
            _statusMessage = 'Sincronizzazione completata con successo.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Errore: ${e.toString().replaceAll('Exception:', '')}';
          _isError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final auth = context.watch<AuthService>();
    final vault = context.read<VaultService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        onPressed: () => auth.signOut(),
                      ),
                    ],
                  ),
                ),
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

              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isError ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
