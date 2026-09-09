import 'package:flutter/cupertino.dart';
import '../theme/apple_theme.dart';

/// Cupertino dialog to create a new folder
class FolderDialog {
  static Future<String?> showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Nuova cartella'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Nome cartella',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annulla'),
            onPressed: () => Navigator.of(ctx).pop(null),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Salva', style: TextStyle(color: AppleTheme.adaptiveAccent(ctx), fontWeight: FontWeight.bold)),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop(name);
              }
            },
          ),
        ],
      ),
    );
  }
}
