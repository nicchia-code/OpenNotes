import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/note_model.dart';
import '../../core/services/security_service.dart';
import '../../core/services/vault_service.dart';
import '../../core/state/notes_provider.dart';
import '../drawing/apple_pencil_canvas.dart';
import '../editor/notion_document_editor.dart';
import '../security/lock_note_dialog.dart';
import '../theme/apple_theme.dart';
import 'mobile_keyboard_accessory_bar.dart';

/// Fullscreen Mobile Note Editor screen with Apple Notes styling and Keyboard Accessory Bar.
class MobileNoteEditorScreen extends StatefulWidget {
  final Note note;
  final String? backFolderTitle;
  final VoidCallback? onBack;

  const MobileNoteEditorScreen({
    super.key,
    required this.note,
    this.backFolderTitle,
    this.onBack,
  });

  @override
  State<MobileNoteEditorScreen> createState() => _MobileNoteEditorScreenState();
}

class _MobileNoteEditorScreenState extends State<MobileNoteEditorScreen> {
  final GlobalKey<NotionDocumentEditorState> _editorKey = GlobalKey<NotionDocumentEditorState>();

  void _onDrawing(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (ctx) => ApplePencilCanvas(
          onSave: (pngBytes) async {
            final vault = context.read<VaultService>();
            final relativePath = await vault.saveAttachment(pngBytes, 'png');
            _editorKey.currentState?.insertImage(relativePath);
          },
        ),
      ),
    );
  }

  Future<void> _onPhoto(BuildContext context) async {
    final vault = context.read<VaultService>();
    final result = await FilePickerPlatform.instance.pickFiles(type: FileType.image);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final ext = result.first.extension ?? 'png';
      final relativePath = await vault.saveAttachment(bytes, ext);
      _editorKey.currentState?.insertImage(relativePath);
    }
  }

  Future<void> _onLock(BuildContext context, NotesProvider provider, SecurityService security) async {
    final currentNote = provider.notes.firstWhere(
      (n) => n.id == widget.note.id,
      orElse: () => widget.note,
    );

    if (currentNote.isLocked) {
      final unlocked = await LockNoteDialog.showUnlockDialog(context, security);
      if (unlocked) {
        await provider.toggleLock(currentNote.id);
      }
    } else {
      if (!security.hasMasterPin) {
        final setPin = await LockNoteDialog.showSetPinDialog(context, security);
        if (!setPin) return;
      }
      await provider.toggleLock(currentNote.id);
    }
  }

  void _onShare(Note currentNote) {
    SharePlus.instance.share(
      ShareParams(
        text: '${currentNote.title}\n\n${currentNote.toMarkdown()}',
        subject: currentNote.title,
      ),
    );
  }

  Future<void> _onExportMarkdown(BuildContext context, Note currentNote) async {
    final messenger = ScaffoldMessenger.of(context);
    final markdown = currentNote.toMarkdown();
    final cleanTitle = currentNote.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final fileName = '${cleanTitle.isEmpty ? 'Nota' : cleanTitle}.md';
    final bytes = Uint8List.fromList(utf8.encode(markdown));

    final uri = await FilePicker.saveFile(
      dialogTitle: 'Esporta come Markdown (.md)',
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/markdown',
    );

    if (uri != null && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Nota esportata come $fileName'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showMoreMenu(BuildContext context, NotesProvider provider, SecurityService security, Note currentNote) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          currentNote.title.isEmpty ? 'Nuova nota' : currentNote.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Pin / Unpin
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currentNote.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin, size: 20),
                const SizedBox(width: 8),
                Text(currentNote.isPinned ? 'Rimuovi da fissate' : 'Fissa nota'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.togglePin(currentNote.id);
            },
          ),

          // Lock / Unlock
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currentNote.isLocked ? CupertinoIcons.lock_open : CupertinoIcons.lock, size: 20),
                const SizedBox(width: 8),
                Text(currentNote.isLocked ? 'Rimuovi protezione' : 'Proteggi nota'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _onLock(context, provider, security);
            },
          ),

          // Export as Markdown
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_down_doc, size: 20),
                SizedBox(width: 8),
                Text('Esporta come Markdown (.md)'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _onExportMarkdown(context, currentNote);
            },
          ),

          // Delete
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 20),
                SizedBox(width: 8),
                Text('Elimina nota'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.moveToTrash(currentNote.id);
              widget.onBack?.call();
              Navigator.maybePop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annulla'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final security = context.watch<SecurityService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppleTheme.darkEditor : AppleTheme.lightEditor;
    final accentColor = isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight;

    // Get reactive note instance from provider
    final currentNote = provider.notes.firstWhere(
      (n) => n.id == widget.note.id,
      orElse: () => widget.note,
    );

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bgColor.withValues(alpha: 0.85),
        border: null,
        leading: CupertinoNavigationBarBackButton(
          previousPageTitle: widget.backFolderTitle ?? 'Note',
          color: accentColor,
          onPressed: () {
            widget.onBack?.call();
            Navigator.maybePop(context);
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Share button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(CupertinoIcons.share, color: accentColor, size: 22),
              onPressed: () => _onShare(currentNote),
            ),

            // Lock button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                currentNote.isLocked ? CupertinoIcons.lock_fill : CupertinoIcons.lock,
                color: accentColor,
                size: 21,
              ),
              onPressed: () => _onLock(context, provider, security),
            ),

            // More options button
            CupertinoButton(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(CupertinoIcons.ellipsis_circle, color: accentColor, size: 22),
              onPressed: () => _showMoreMenu(context, provider, security, currentNote),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Main Note Editor
            Expanded(
              child: NotionDocumentEditor(
                key: _editorKey,
                note: currentNote,
              ),
            ),

            // Keyboard Accessory Toolbar
            MobileKeyboardAccessoryBar(
              onChecklist: () => _editorKey.currentState?.insertChecklist(),
              onTable: () => _editorKey.currentState?.insertTable(),
              onDrawing: () => _onDrawing(context),
              onPhoto: () => _onPhoto(context),
              onSelectBlockType: (type) => _editorKey.currentState?.setBlockType(type),
              onBold: () => _editorKey.currentState?.toggleBold(),
              onItalic: () => _editorKey.currentState?.toggleItalic(),
              onUnderline: () => _editorKey.currentState?.toggleUnderline(),
              onDismissKeyboard: () => FocusScope.of(context).unfocus(),
            ),
          ],
        ),
      ),
    );
  }
}
