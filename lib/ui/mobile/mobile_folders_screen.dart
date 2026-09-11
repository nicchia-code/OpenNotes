import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/folder_model.dart';
import '../../core/state/notes_provider.dart';
import '../settings/supabase_settings_dialog.dart';
import '../sidebar/folder_dialog.dart';
import '../theme/apple_theme.dart';

/// Authentic Apple Notes iOS full-width Folders screen ("Cartelle").
class MobileFoldersScreen extends StatelessWidget {
  final VoidCallback? onOpenNotesList;
  final ValueChanged<String>? onSelectFolder;
  final ValueChanged<String?>? onSelectTag;
  final VoidCallback? onNewNote;

  const MobileFoldersScreen({
    super.key,
    this.onOpenNotesList,
    this.onSelectFolder,
    this.onSelectTag,
    this.onNewNote,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final folders = provider.folders;
    final tags = provider.tags;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppleTheme.darkSidebar : const Color(0xFFF2F2F7);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary;
    final accentColor = isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bgColor.withValues(alpha: 0.85),
        border: null,
        middle: const Text('Cartelle', style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.gear, color: accentColor, size: 22),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const SupabaseSettingsDialog(),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Section 1: OPENNOTES
                  _buildSectionHeader('OPENNOTES', secondaryTextColor),
                  _buildGroupedCard(
                    cardBg: cardBg,
                    isDark: isDark,
                    children: [
                      _buildRow(
                        icon: CupertinoIcons.tray_fill,
                        iconColor: accentColor,
                        title: 'Tutte le note',
                        count: provider.getNoteCountForFolder(Folder.allNotesId),
                        textColor: textColor,
                        secondaryColor: secondaryTextColor,
                        onTap: () {
                          provider.selectFolder(Folder.allNotesId);
                          onSelectFolder?.call(Folder.allNotesId);
                          onOpenNotesList?.call();
                        },
                      ),
                      _buildDivider(isDark),
                      _buildRow(
                        icon: CupertinoIcons.folder_fill,
                        iconColor: accentColor,
                        title: 'Note',
                        count: provider.getNoteCountForFolder(Folder.defaultNotesId),
                        textColor: textColor,
                        secondaryColor: secondaryTextColor,
                        onTap: () {
                          provider.selectFolder(Folder.defaultNotesId);
                          onSelectFolder?.call(Folder.defaultNotesId);
                          onOpenNotesList?.call();
                        },
                      ),
                      // Custom Folders
                      ...folders.where((f) => !f.isSystem).expand((folder) sync* {
                        yield _buildDivider(isDark);
                        yield Dismissible(
                          key: ValueKey(folder.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await FolderDialog.showDeleteConfirmDialog(context, folder.name);
                          },
                          onDismissed: (_) {
                            provider.deleteFolder(folder.id);
                          },
                          background: Container(
                            color: CupertinoColors.destructiveRed,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(CupertinoIcons.trash_fill, color: Colors.white, size: 20),
                          ),
                          child: GestureDetector(
                            onLongPress: () async {
                              final action = await showCupertinoModalPopup<String>(
                                context: context,
                                builder: (ctx) => CupertinoActionSheet(
                                  title: Text(folder.name),
                                  actions: [
                                    CupertinoActionSheetAction(
                                      child: const Text('Rinomina cartella'),
                                      onPressed: () => Navigator.pop(ctx, 'rename'),
                                    ),
                                    CupertinoActionSheetAction(
                                      isDestructiveAction: true,
                                      child: const Text('Elimina cartella'),
                                      onPressed: () => Navigator.pop(ctx, 'delete'),
                                    ),
                                  ],
                                  cancelButton: CupertinoActionSheetAction(
                                    isDefaultAction: true,
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Annulla'),
                                  ),
                                ),
                              );

                              if (action == 'rename' && context.mounted) {
                                final newName = await FolderDialog.showRenameFolderDialog(context, folder.name);
                                if (newName != null && newName.isNotEmpty) {
                                  await provider.renameFolder(folder.id, newName);
                                }
                              } else if (action == 'delete' && context.mounted) {
                                final confirm = await FolderDialog.showDeleteConfirmDialog(context, folder.name);
                                if (confirm) {
                                  await provider.deleteFolder(folder.id);
                                }
                              }
                            },
                            child: _buildRow(
                              icon: CupertinoIcons.folder_fill,
                              iconColor: accentColor,
                              title: folder.name,
                              count: provider.getNoteCountForFolder(folder.id),
                              textColor: textColor,
                              secondaryColor: secondaryTextColor,
                              onTap: () {
                                provider.selectFolder(folder.id);
                                onSelectFolder?.call(folder.id);
                                onOpenNotesList?.call();
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  // Section 2: TAG (if available)
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader('TAG', secondaryTextColor),
                    _buildGroupedCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      children: [
                        for (int i = 0; i < tags.length; i++) ...[
                          if (i > 0) _buildDivider(isDark),
                          _buildRow(
                            icon: CupertinoIcons.number,
                            iconColor: secondaryTextColor,
                            title: tags[i].name,
                            count: tags[i].count,
                            textColor: textColor,
                            secondaryColor: secondaryTextColor,
                            onTap: () {
                              provider.selectTag(tags[i].name);
                              onSelectTag?.call(tags[i].name);
                              onOpenNotesList?.call();
                            },
                          ),
                        ],
                      ],
                    ),
                  ],

                  // Section 3: ALTRO
                  const SizedBox(height: 20),
                  _buildSectionHeader('ALTRO', secondaryTextColor),
                  _buildGroupedCard(
                    cardBg: cardBg,
                    isDark: isDark,
                    children: [
                      _buildRow(
                        icon: CupertinoIcons.trash,
                        iconColor: secondaryTextColor,
                        title: 'Eliminati di recente',
                        count: provider.trashCount,
                        textColor: textColor,
                        secondaryColor: secondaryTextColor,
                        onTap: () {
                          provider.selectFolder(Folder.trashId);
                          onSelectFolder?.call(Folder.trashId);
                          onOpenNotesList?.call();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Toolbar: Nuova Cartella & Nuova Nota
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
                    width: 0.6,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nuova cartella (Bottom Left)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final name = await FolderDialog.showCreateFolderDialog(context);
                      if (name != null && name.trim().isNotEmpty) {
                        await provider.createFolder(name.trim());
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.folder_badge_plus, color: accentColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Nuova cartella',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nuova nota (Bottom Right)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onNewNote,
                    child: Icon(CupertinoIcons.square_pencil, color: accentColor, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard({
    required Color cardBg,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required Color textColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onPressed: onTap,
      minimumSize: const Size(0, 48),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              color: secondaryColor,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 14,
            color: secondaryColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 0.6,
      thickness: 0.6,
      indent: 48,
      endIndent: 0,
      color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
    );
  }
}
