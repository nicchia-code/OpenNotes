import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/folder_model.dart';
import '../../core/models/tag_model.dart';
import '../../core/services/sync_service.dart';
import '../../core/state/notes_provider.dart';
import '../settings/supabase_settings_dialog.dart';
import '../theme/apple_theme.dart';
import 'folder_dialog.dart';

/// Authentic macOS Sequoia Sidebar.
class SidebarView extends StatelessWidget {
  final VoidCallback? onFolderSelected;

  const SidebarView({super.key, this.onFolderSelected});

  @override
  Widget build(BuildContext context) {
    final selectedFolderId = context.select<NotesProvider, String>((p) => p.selectedFolderId);
    final selectedTag = context.select<NotesProvider, String?>((p) => p.selectedTag);
    final isTrashSelected = context.select<NotesProvider, bool>((p) => p.isTrashSelected);
    final folders = context.select<NotesProvider, List<Folder>>((p) => p.folders);
    final tags = context.select<NotesProvider, List<Tag>>((p) => p.tags);

    final sync = context.watch<SyncService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? AppleTheme.darkSidebar : AppleTheme.lightSidebar,
        border: Border(
          right: BorderSide(
            color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        children: [
          // Cloud / Account Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Icon(CupertinoIcons.cloud, color: AppleTheme.accentYellow, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sync.isAuthenticated ? (sync.currentUser?.email ?? 'Cloud') : 'Cloud',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 24,
                  child: Icon(
                    CupertinoIcons.gear,
                    size: 16,
                    color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SupabaseSettingsDialog(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Main Folder Tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              children: [
                _buildSectionHeader('RACCOLTE', isDark),

                // "Tutte le note"
                _MacSidebarRow(
                  icon: CupertinoIcons.tray_fill,
                  title: 'Tutte le note',
                  isSelected: selectedFolderId == Folder.allNotesId && selectedTag == null,
                  onTap: () {
                    context.read<NotesProvider>().selectFolder(Folder.allNotesId);
                    onFolderSelected?.call();
                  },
                ),

                // "Note" (Default folder)
                _MacSidebarRow(
                  icon: CupertinoIcons.folder_fill,
                  title: 'Note',
                  isSelected: selectedFolderId == Folder.defaultNotesId && selectedTag == null,
                  onTap: () {
                    context.read<NotesProvider>().selectFolder(Folder.defaultNotesId);
                    onFolderSelected?.call();
                  },
                ),

                // User Folders
                ...folders.where((f) => !f.isSystem).map((folder) {
                  return _MacSidebarRow(
                    icon: CupertinoIcons.folder_fill,
                    title: folder.name,
                    isSelected: selectedFolderId == folder.id && selectedTag == null,
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 20,
                      child: const Icon(CupertinoIcons.ellipsis, size: 14, color: CupertinoColors.systemGrey),
                      onPressed: () => _showFolderOptions(context, folder, context.read<NotesProvider>()),
                    ),
                    onTap: () {
                      context.read<NotesProvider>().selectFolder(folder.id);
                      onFolderSelected?.call();
                    },
                  );
                }),

                // Tags Section
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSectionHeader('TAG', isDark),
                  ...tags.map((tag) {
                    final isSelected = selectedTag == tag.name;
                    return _MacSidebarRow(
                      icon: CupertinoIcons.number,
                      title: tag.name,
                      badge: '${tag.count}',
                      isSelected: isSelected,
                      onTap: () {
                        context.read<NotesProvider>().selectTag(tag.name);
                        onFolderSelected?.call();
                      },
                    );
                  }),
                ],

                const SizedBox(height: 14),
                _buildSectionHeader('ALTRO', isDark),

                // "Eliminati di recente" (Trash)
                _MacSidebarRow(
                  icon: CupertinoIcons.trash,
                  title: 'Eliminati di recente',
                  isSelected: isTrashSelected,
                  onTap: () {
                    context.read<NotesProvider>().selectFolder(Folder.trashId);
                    onFolderSelected?.call();
                  },
                ),
              ],
            ),
          ),

          // Bottom Bar "+ Nuova cartella"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.folder_badge_plus,
                        color: isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nuova cartella',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    final provider = context.read<NotesProvider>();
                    final name = await FolderDialog.showCreateFolderDialog(context);
                    if (name != null && name.isNotEmpty) {
                      await provider.createFolder(name);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark ? AppleTheme.darkTextSecondary.withOpacity(0.8) : AppleTheme.lightTextSecondary,
        ),
      ),
    );
  }

  void _showFolderOptions(BuildContext context, Folder folder, NotesProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(folder.name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('Elimina cartella'),
            onPressed: () {
              provider.deleteFolder(folder.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Annulla'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

class _MacSidebarRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final bool isSelected;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MacSidebarRow({
    required this.icon,
    required this.title,
    this.badge,
    required this.isSelected,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rowBg = isSelected
        ? (isDark ? const Color(0xFF2C2C30) : const Color(0xFFDFDFE4))
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          hoverColor: isDark ? AppleTheme.darkCardHover : AppleTheme.lightCardHover,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppleTheme.accentYellow,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.1,
                      color: isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                    ),
                  ),
                ],
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
