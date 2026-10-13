import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/folder_model.dart';

Future<String?> showFolderPicker(
  BuildContext context,
  List<Folder> folders,
  String currentFolderId,
) {
  final destinations = folders
      .where(
        (folder) =>
            folder.id != Folder.allNotesId && folder.id != Folder.trashId,
      )
      .toList();
  final isMobile =
      Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.android;
  if (isMobile) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sposta in…',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: _folderList(sheetContext, destinations, currentFolderId),
              ),
            ],
          ),
        ),
      ),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sposta in…'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 360,
        height: 360,
        child: _folderList(dialogContext, destinations, currentFolderId),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Annulla'),
        ),
      ],
    ),
  );
}

Widget _folderList(
  BuildContext context,
  List<Folder> folders,
  String currentFolderId,
) => ListView(
  children: [
    for (final entry in _orderedFolders(folders))
      ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 + 20.0 * entry.depth),
        leading: const Icon(CupertinoIcons.folder),
        title: Text(entry.folder.name),
        enabled: entry.folder.id != currentFolderId,
        trailing: entry.folder.id == currentFolderId
            ? const Icon(CupertinoIcons.check_mark)
            : null,
        onTap: entry.folder.id == currentFolderId
            ? null
            : () => Navigator.pop(context, entry.folder.id),
      ),
  ],
);

typedef _FolderRow = ({Folder folder, int depth});

int _byName(Folder a, Folder b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

/// Folders as a tree: roots, then orphans (parent missing on the device),
/// each with its subtree. Siblings sorted by name, ignoring case.
List<_FolderRow> _orderedFolders(List<Folder> folders) {
  final sorted = [...folders]..sort(_byName);
  final ids = {for (final folder in sorted) folder.id};
  final byParent = <String, List<Folder>>{};
  final roots = <Folder>[];
  final orphans = <Folder>[];
  for (final folder in sorted) {
    final parentId = folder.parentId;
    if (parentId == null) {
      roots.add(folder);
    } else if (ids.contains(parentId)) {
      byParent.putIfAbsent(parentId, () => []).add(folder);
    } else {
      orphans.add(folder);
    }
  }

  final ordered = <_FolderRow>[];
  final seen = <String>{};
  void visit(Folder folder, int depth) {
    if (!seen.add(folder.id)) return;
    ordered.add((folder: folder, depth: depth));
    for (final child in byParent[folder.id] ?? const <Folder>[]) {
      visit(child, depth + 1);
    }
  }

  for (final root in [...roots, ...orphans]) {
    visit(root, 0);
  }
  // Parent cycles reach no root: keep those folders at the end.
  for (final folder in sorted) {
    visit(folder, 0);
  }
  return ordered;
}
