import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/note_model.dart';
import '../../core/services/security_service.dart';
import '../../core/state/notes_provider.dart';
import '../security/lock_note_dialog.dart';
import 'folder_picker.dart';
import 'note_action_menu.dart';

class NoteActions {
  static const _fileChannel = MethodChannel('opennotes/file');
  static Future<void> showMobile(
    BuildContext context,
    Note note, {
    VoidCallback? onRemoved,
    /// After Duplica: the copy, or [note] when the unlock was cancelled.
    ValueChanged<Note>? onOpenAfterDuplicate,
    /// The notes list long-press menu: no trashing or permanent deletion.
    bool fromList = false,
  }) async {
    await NoteActionMenu.showCupertino(
      context: context,
      note: note,
      fromList: fromList,
      onSelected: (action) {
        handle(context, note, action, onRemoved: onRemoved).then((done) {
          if (action == NoteMenuAction.duplicate && context.mounted) {
            final copy = done
                ? context.read<NotesProvider>().selectedNote
                : null;
            onOpenAfterDuplicate?.call(copy ?? note);
          }
        });
      },
    );
  }

  static Future<void> showDesktop(
    BuildContext context,
    Note note,
    Offset position, {
    VoidCallback? onRemoved,
  }) async {
    await NoteActionMenu.showMaterial(
      context: context,
      position: position,
      note: note,
      onSelected: (action) =>
          handle(context, note, action, onRemoved: onRemoved),
    );
  }

  static Future<bool> handle(
    BuildContext context,
    Note note,
    NoteMenuAction action, {
    VoidCallback? onRemoved,
  }) async {
    final provider = context.read<NotesProvider>();
    final security = context.read<SecurityService>();
    // Every PIN and lock decision uses the stored note, not the copy the menu or the editor was given.
    final stored = await provider.fetchNote(note.id);
    if (stored == null) return false;
    if (stored.isLocked &&
        (action == NoteMenuAction.duplicate ||
            action == NoteMenuAction.share ||
            action == NoteMenuAction.export)) {
      final unlocked = await LockNoteDialog.showUnlockDialog(context, security);
      if (!unlocked || !context.mounted) return false;
    }
    switch (action) {
      case NoteMenuAction.pin:
        await provider.togglePin(note.id);
      case NoteMenuAction.lock:
        if (stored.isLocked) {
          final unlocked = await LockNoteDialog.showUnlockDialog(
            context,
            security,
          );
          if (unlocked) {
            await provider.toggleLock(note.id, wasLocked: true);
          }
        } else {
          if (!security.hasMasterPin &&
              !await LockNoteDialog.showSetPinDialog(context, security)) {
            return false;
          }
          await provider.toggleLock(note.id, wasLocked: false);
          security.relockNote(note.id);
        }
      case NoteMenuAction.duplicate:
        return await provider.duplicateNote(note.id) != null;
      case NoteMenuAction.move:
        final destination = await showFolderPicker(
          context,
          provider.folders,
          note.folderId,
        );
        if (destination != null) {
          // Move what is on screen: hand over and write the edit still waiting in the editor.
          provider.deliverWaitingEdits();
          await provider.flushPendingContent();
          await provider.moveNoteToFolder(note.id, destination);
        }
      case NoteMenuAction.share:
        // Share what is on screen: hand over the edit still waiting in the editor.
        provider.deliverWaitingEdits();
        final shownList = provider.notes.where((n) => n.id == note.id);
        final shown = shownList.isEmpty ? note : shownList.first;
        try {
          await SharePlus.instance.share(
            ShareParams(
              text: '${shown.title}\n\n${shown.toMarkdownBody()}',
              subject: shown.title,
            ),
          );
        } catch (error) {
          debugPrint('Sharing "${shown.title}" failed: $error');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Nota non condivisa: impossibile aprire il foglio di condivisione.',
                ),
              ),
            );
          }
          return false;
        }
      case NoteMenuAction.export:
        // Export what is on screen: hand over the edit still waiting in the editor.
        provider.deliverWaitingEdits();
        final listed = provider.notes.where((n) => n.id == note.id);
        final current = listed.isEmpty ? note : listed.first;
        final cleanTitle = current.title
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
            .trim();
        final fileName = '${cleanTitle.isEmpty ? 'Nota' : cleanTitle}.md';
        String? savedPath;
        try {
          savedPath = await FilePicker.saveFile(
            dialogTitle: 'Esporta come Markdown (.md)',
            fileName: fileName,
            bytes: Uint8List.fromList(utf8.encode(current.toMarkdown())),
          );
        } catch (error) {
          debugPrint('Markdown export of "$fileName" failed: $error');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Nota non esportata: impossibile scrivere il file nella posizione scelta.',
                ),
              ),
            );
          }
          return false;
        }
        if (savedPath != null) {
          final savedName = await NoteActions.savedFileNameOf(
            Uri.file(savedPath),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Nota esportata come ${savedName ?? fileName}',
                ),
              ),
            );
          }
        }
      case NoteMenuAction.trash:
        if (!await provider.moveToTrash(note.id)) return false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nota spostata nel cestino'),
              action: SnackBarAction(
                label: 'Annulla',
                onPressed: () => provider.restoreFromTrash(note.id),
              ),
            ),
          );
        }
        onRemoved?.call();
      case NoteMenuAction.restore:
        await provider.restoreFromTrash(note.id);
      case NoteMenuAction.permanentlyDelete:
        if (await confirmPermanentDelete(context, stored)) {
          final deleted = await provider.permanentlyDeleteNote(note.id);
          if (deleted) onRemoved?.call();
          return deleted;
        }
        return false;
    }
    return false;
  }

  /// Name of the file the save dialog wrote, or null when none is known. On
  /// Android the system gives the name of a content URI, also when the URI is
  /// opaque; otherwise the name comes from the URI itself.
  static Future<String?> savedFileNameOf(Uri uri) async {
    if (uri.scheme == 'content') {
      try {
        final name = await _fileChannel.invokeMethod<String>(
          'displayName',
          uri.toString(),
        );
        if (name != null && name.isNotEmpty) return name;
      } on PlatformException catch (error) {
        debugPrint('Reading the name of ${uri.path} failed: $error');
      } on MissingPluginException {
        // No native handler on this platform: use the name in the URI.
      }
    }
    return savedFileName(uri);
  }

  /// Readable file name carried by the URI of a file returned by the save
  /// dialog, or null when the URI carries none. A local file always has a
  /// readable name, with or without extension; a content identifier (for
  /// example an opaque Android content identifier) is readable only with an
  /// extension.
  static String? savedFileName(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty);
    if (segments.isEmpty) return null;
    final last = segments.last.split(RegExp(r'[/:]')).last;
    if (last.isEmpty) return null;
    if (uri.scheme == 'file') return last;
    return RegExp(r'\.[A-Za-z0-9]+$').hasMatch(last) ? last : null;
  }

  static Future<bool> confirmPermanentDelete(
    BuildContext context,
    Note note,
  ) async {
    if (!await _confirmIrreversible(context)) return false;
    if (!note.isLocked) return true;
    if (!context.mounted) return false;
    final security = context.read<SecurityService>();
    if (security.isNoteUnlocked(note.id)) return true;
    return LockNoteDialog.showUnlockDialog(context, security);
  }

  /// Asks the user to confirm that the deletion cannot be undone. Shown before
  /// the PIN of a protected note.
  static Future<bool> _confirmIrreversible(BuildContext context) async {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.android) {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Eliminare definitivamente la nota?'),
          content: const Text('Questa azione non può essere annullata.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Elimina definitivamente'),
            ),
          ],
        ),
      );
      return confirmed == true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare definitivamente la nota?'),
        content: const Text('Questa azione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Elimina definitivamente',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
