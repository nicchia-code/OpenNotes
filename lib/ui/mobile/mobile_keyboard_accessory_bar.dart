import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../editor/notion_document_editor.dart';
import '../theme/apple_theme.dart';

/// Floating iOS-style Keyboard Accessory Toolbar for mobile note editing.
class MobileKeyboardAccessoryBar extends StatelessWidget {
  final VoidCallback? onChecklist;
  final VoidCallback? onTable;
  final VoidCallback? onDrawing;
  final VoidCallback? onPhoto;
  final ValueChanged<BlockType>? onSelectBlockType;
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUnderline;
  final VoidCallback? onDismissKeyboard;

  const MobileKeyboardAccessoryBar({
    super.key,
    this.onChecklist,
    this.onTable,
    this.onDrawing,
    this.onPhoto,
    this.onSelectBlockType,
    this.onBold,
    this.onItalic,
    this.onUnderline,
    this.onDismissKeyboard,
  });

  void _showFormatMenu(BuildContext context, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Formattazione Testo', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.bold, size: 20),
                SizedBox(width: 8),
                Text('Grassetto'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onBold?.call();
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.italic, size: 20),
                SizedBox(width: 8),
                Text('Corsivo'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onItalic?.call();
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.underline, size: 20),
                SizedBox(width: 8),
                Text('Sottolineato'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onUnderline?.call();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Titolo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              onSelectBlockType?.call(BlockType.title);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Intestazione', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            onPressed: () {
              Navigator.pop(ctx);
              onSelectBlockType?.call(BlockType.h1);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Sottointestazione', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            onPressed: () {
              Navigator.pop(ctx);
              onSelectBlockType?.call(BlockType.h2);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Corpo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal)),
            onPressed: () {
              Navigator.pop(ctx);
              onSelectBlockType?.call(BlockType.paragraph);
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.list_bullet, size: 20),
                SizedBox(width: 8),
                Text('Elenco Puntato'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onSelectBlockType?.call(BlockType.bullet);
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.list_number, size: 20),
                SizedBox(width: 8),
                Text('Elenco Numerato'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onSelectBlockType?.call(BlockType.numbered);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Chiudi'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary;
    final accentColor = isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7),
        border: Border(
          top: BorderSide(
            color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
            width: 0.6,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Checklist button
          _buildItem(
            icon: CupertinoIcons.checkmark_circle,
            tooltip: 'Elenco di controllo',
            color: iconColor,
            onTap: onChecklist,
          ),

          // Format Aa button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 36),
            onPressed: () => _showFormatMenu(context, isDark),
            child: Text(
              'Aa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: iconColor,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Table button
          _buildItem(
            icon: CupertinoIcons.table,
            tooltip: 'Tabella',
            color: iconColor,
            onTap: onTable,
          ),

          // Drawing / Apple pencil button
          _buildItem(
            icon: CupertinoIcons.pencil_outline,
            tooltip: 'Disegno',
            color: iconColor,
            onTap: onDrawing,
          ),

          // Photo / Attachment button
          _buildItem(
            icon: CupertinoIcons.camera,
            tooltip: 'Foto o allegato',
            color: iconColor,
            onTap: onPhoto,
          ),

          const Spacer(),

          // "Fine" (Done) button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 36),
            onPressed: () {
              FocusScope.of(context).unfocus();
              onDismissKeyboard?.call();
            },
            child: Text(
              'Fine',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String tooltip,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 36),
        onPressed: onTap,
        child: Icon(icon, size: 21, color: color),
      ),
    );
  }
}
