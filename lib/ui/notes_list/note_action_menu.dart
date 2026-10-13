import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/note_model.dart';

enum NoteMenuAction {
  pin,
  lock,
  duplicate,
  move,
  share,
  export,
  trash,
  restore,
  permanentlyDelete,
}

class NoteActionMenu {
  /// [fromList] is the notes list long-press menu, which leaves out trashing and
  /// permanent deletion: those are swipe and editor actions.
  static List<NoteMenuAction> actionsFor(Note note, {bool fromList = false}) {
    final all = note.isDeleted
        ? [
            NoteMenuAction.restore,
            NoteMenuAction.move,
            NoteMenuAction.lock,
            NoteMenuAction.permanentlyDelete,
          ]
        : [
            NoteMenuAction.pin,
            NoteMenuAction.lock,
            NoteMenuAction.duplicate,
            NoteMenuAction.move,
            NoteMenuAction.share,
            NoteMenuAction.export,
            NoteMenuAction.trash,
          ];
    if (!fromList) return all;
    return [
      for (final action in all)
        if (action != NoteMenuAction.trash &&
            action != NoteMenuAction.permanentlyDelete)
          action,
    ];
  }

  static String label(NoteMenuAction action, Note note) => switch (action) {
    NoteMenuAction.pin => note.isPinned ? 'Rimuovi da fissate' : 'Fissa nota',
    NoteMenuAction.lock =>
      note.isLocked ? 'Rimuovi protezione' : 'Proteggi nota',
    NoteMenuAction.duplicate => 'Duplica',
    NoteMenuAction.move => 'Sposta in…',
    NoteMenuAction.share => 'Condividi',
    NoteMenuAction.export => 'Esporta come Markdown (.md)',
    NoteMenuAction.trash => 'Sposta nel cestino',
    NoteMenuAction.restore => 'Ripristina nota',
    NoteMenuAction.permanentlyDelete => 'Elimina definitivamente',
  };

  static IconData icon(NoteMenuAction action, Note note) => switch (action) {
    NoteMenuAction.pin =>
      note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
    NoteMenuAction.lock =>
      note.isLocked ? CupertinoIcons.lock_open : CupertinoIcons.lock,
    NoteMenuAction.duplicate => CupertinoIcons.doc_on_doc,
    NoteMenuAction.move => CupertinoIcons.folder,
    NoteMenuAction.share => CupertinoIcons.share,
    NoteMenuAction.export => CupertinoIcons.arrow_down_doc,
    NoteMenuAction.trash ||
    NoteMenuAction.permanentlyDelete => CupertinoIcons.trash,
    NoteMenuAction.restore => CupertinoIcons.arrow_uturn_left,
  };

  static bool isDestructive(NoteMenuAction action) =>
      action == NoteMenuAction.trash ||
      action == NoteMenuAction.permanentlyDelete;

  static Future<void> showCupertino({
    required BuildContext context,
    required Note note,
    required ValueChanged<NoteMenuAction> onSelected,
    bool fromList = false,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(
          note.title.isEmpty ? 'Nuova nota' : note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          for (final action in actionsFor(note, fromList: fromList))
            CupertinoActionSheetAction(
              isDestructiveAction: isDestructive(action),
              onPressed: () {
                Navigator.pop(popupContext);
                onSelected(action);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon(action, note), size: 19),
                  const SizedBox(width: 8),
                  Text(label(action, note)),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('Annulla'),
        ),
      ),
    );
  }

  static Future<void> showMaterial({
    required BuildContext context,
    required Offset position,
    required Note note,
    required ValueChanged<NoteMenuAction> onSelected,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<NoteMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final action in actionsFor(note))
          PopupMenuItem(
            value: action,
            child: Row(
              children: [
                Icon(
                  icon(action, note),
                  size: 18,
                  color: isDestructive(action)
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label(action, note),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDestructive(action)
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (selected != null) onSelected(selected);
  }
}
