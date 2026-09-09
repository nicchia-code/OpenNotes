import 'package:flutter/cupertino.dart';
import '../../core/services/security_service.dart';
import '../theme/apple_theme.dart';

/// Modal dialog for unlocking protected notes or configuring the Master PIN.
class LockNoteDialog {
  /// Shows the dialog to verify PIN and unlock a note
  static Future<bool> showUnlockDialog(BuildContext context, SecurityService securityService) async {
    final pinController = TextEditingController();
    String? errorMessage;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.lock_shield_fill, color: AppleTheme.accentYellow, size: 28),
                SizedBox(width: 8),
                Text('Nota Protetta', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inserisci il PIN di sicurezza per visualizzare questa nota:'),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: pinController,
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    placeholder: 'PIN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 6, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Sblocca', style: TextStyle(color: AppleTheme.adaptiveAccent(ctx), fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final entered = pinController.text.trim();
                  if (entered.isEmpty) return;

                  final isValid = await securityService.verifyPin(entered);
                  if (isValid) {
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  } else {
                    setState(() {
                      errorMessage = 'PIN non corretto. Riprova.';
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );

    return result ?? false;
  }

  /// Shows the dialog to set a new Master PIN
  static Future<bool> showSetPinDialog(BuildContext context, SecurityService securityService) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: const Text('Crea PIN di Sicurezza', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Questo PIN proteggerà le tue note con lucchetto.'),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: pinController,
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    placeholder: 'Nuovo PIN',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    placeholder: 'Conferma PIN',
                    textAlign: TextAlign.center,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Imposta PIN', style: TextStyle(color: AppleTheme.adaptiveAccent(ctx), fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final pin = pinController.text.trim();
                  final confirm = confirmController.text.trim();

                  if (pin.length < 4) {
                    setState(() => errorMessage = 'Il PIN deve avere almeno 4 cifre.');
                    return;
                  }
                  if (pin != confirm) {
                    setState(() => errorMessage = 'I PIN inseriti non coincidono.');
                    return;
                  }

                  await securityService.setMasterPin(pin);
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                },
              ),
            ],
          );
        },
      ),
    );

    return result ?? false;
  }
}
