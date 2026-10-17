import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/note_model.dart';
import '../../core/services/security_service.dart';
import '../../core/services/vault_service.dart';
import '../../core/state/notes_provider.dart';
import '../drawing/apple_pencil_canvas.dart';
import '../editor/notion_document_editor.dart';
import '../security/lock_note_dialog.dart';
import '../notes_list/note_action_menu.dart';
import '../notes_list/note_actions.dart';
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
  // Last version received from the list. When the note leaves the current
  // selection (moved, pinned, restored) or disappears from the data, the
  // editor stays open: it keeps the text of this version and re-reads the
  // stored folder, trash, pin and lock state on every data change.
  Note? _lastKnownNote;
  NotesProvider? _provider;
  // Set once the editor closes, so it pops only once.
  bool _leaving = false;
  // Set when the note is trashed or deleted from its menu: the editor closes and the waiting edit is discarded.
  bool _removed = false;
  final GlobalKey<NotionDocumentEditorState> _editorKey =
      GlobalKey<NotionDocumentEditorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NotesProvider>();
    if (identical(provider, _provider)) return;
    _provider?.removeListener(_onDataChanged);
    _provider = provider;
    provider.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _provider?.removeListener(_onDataChanged);
    super.dispose();
  }

  // Runs before the editor is disposed, for any way back (button, gesture, system key), so the edit still waiting
  // is handed over when its 300 ms wait ends, while the screen leaves.
  @override
  void deactivate() {
    if (!_removed) _editorKey.currentState?.keepWaitingTextOnExit();
    super.deactivate();
  }

  // Only a note outside the list needs a stored read: listed notes already
  // arrive through build.
  void _onDataChanged() {
    final provider = _provider;
    if (provider == null || _leaving) return;
    if (provider.notes.any((n) => n.id == widget.note.id)) return;
    unawaited(_refreshStoredState(provider));
  }

  // Takes folder, trash, pin and lock from the stored note; the text stays as it is.
  Future<void> _refreshStoredState(NotesProvider provider) async {
    final stored = await provider.fetchNote(widget.note.id);
    if (!mounted || stored == null) return;
    final current = _lastKnownNote ?? widget.note;
    setState(() {
      _lastKnownNote = current.copyWith(
        folderId: stored.folderId,
        isPinned: stored.isPinned,
        isLocked: stored.isLocked,
        isDeleted: stored.isDeleted,
        deletedAt: stored.deletedAt,
        clearDeletedAt: stored.deletedAt == null,
      );
    });
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    widget.onBack?.call();
    Navigator.maybePop(context);
  }

  void _leaveRemoved() {
    _removed = true;
    _leave();
  }

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
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.image,
    );
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final ext = result.first.extension ?? 'png';
      final relativePath = await vault.saveAttachment(bytes, ext);
      _editorKey.currentState?.insertImage(relativePath);
    }
  }

  Future<void> _onLock(BuildContext context) async {
    // Same version the editor shows; the lock decision itself is taken on the stored note.
    final currentNote = _lastKnownNote ?? widget.note;
    await NoteActions.handle(context, currentNote, NoteMenuAction.lock);
  }

  void _showMoreMenu(BuildContext context) {
    // The menu acts on the version the editor shows, not the stored copy, which
    // lags behind the 400 ms save wait.
    final note = _lastKnownNote ?? widget.note;
    // Protected notes stay on the placeholder after trash or delete: the Model gives Protected only the back exit.
    final security = context.read<SecurityService>();
    final isProtected = note.isLocked && !security.isNoteUnlocked(note.id);
    NoteActions.showMobile(
      context,
      note,
      onRemoved: isProtected ? null : _leaveRemoved,
      onOpenAfterDuplicate: (opened) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (_) => MobileNoteEditorScreen(
              note: opened,
              backFolderTitle: widget.backFolderTitle,
              onBack: widget.onBack,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final security = context.watch<SecurityService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppleTheme.darkEditor : AppleTheme.lightEditor;
    final accentColor = isDark
        ? AppleTheme.accentYellow
        : AppleTheme.accentAmberLight;

    // Reactive note from the provider; falls back to the last one received
    final listedNotes = provider.notes.where((n) => n.id == widget.note.id);
    if (listedNotes.isNotEmpty) {
      _lastKnownNote = listedNotes.first;
    }
    final currentNote = _lastKnownNote ?? widget.note;
    // Protected notes show no text, so the Block menu button stays disabled until the note is unlocked.
    final isProtected =
        currentNote.isLocked && !security.isNoteUnlocked(currentNote.id);

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bgColor.withValues(alpha: 0.85),
        border: null,
        leading: CupertinoNavigationBarBackButton(
          previousPageTitle: widget.backFolderTitle ?? 'Note',
          color: accentColor,
          onPressed: _leave,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Share button
            if (!currentNote.isDeleted)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(CupertinoIcons.share, color: accentColor, size: 22),
                onPressed: () => NoteActions.handle(
                  context,
                  currentNote,
                  NoteMenuAction.share,
                ),
              ),

            // Lock button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                currentNote.isLocked
                    ? CupertinoIcons.lock_fill
                    : CupertinoIcons.lock,
                color: accentColor,
                size: 21,
              ),
              onPressed: () => _onLock(context),
            ),

            // More options button
            CupertinoButton(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                color: accentColor,
                size: 22,
              ),
              onPressed: () => _showMoreMenu(context),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Main Note Editor
            Expanded(
              child: NotionDocumentEditor(key: _editorKey, note: currentNote),
            ),

            // Keyboard Accessory Toolbar
            MobileKeyboardAccessoryBar(
              onChecklist: () => _editorKey.currentState?.insertChecklist(),
              onTable: () => _editorKey.currentState?.insertTable(),
              onDrawing: () => _onDrawing(context),
              onPhoto: () => _onPhoto(context),
              onBlockMenu: isProtected
                  ? null
                  : () => _editorKey.currentState?.openBlockMenu(),
              onSelectBlockType: (type) =>
                  _editorKey.currentState?.setBlockType(type),
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
