import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/folder_model.dart';
import '../../core/models/note_model.dart';
import '../../core/services/security_service.dart';
import '../../core/state/notes_provider.dart';
import '../notes_list/note_card.dart';
import '../security/lock_note_dialog.dart';
import '../theme/apple_theme.dart';

/// Authentic Apple Notes iOS Notes List screen.
class MobileNotesListScreen extends StatefulWidget {
  final VoidCallback? onBackToFolders;
  final ValueChanged<Note>? onNoteSelected;
  final VoidCallback? onNewNote;

  const MobileNotesListScreen({
    super.key,
    this.onBackToFolders,
    this.onNoteSelected,
    this.onNewNote,
  });

  @override
  State<MobileNotesListScreen> createState() => _MobileNotesListScreenState();
}

class _MobileNotesListScreenState extends State<MobileNotesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getTitle(NotesProvider provider) {
    if (provider.isTrashSelected) return 'Eliminati di recente';
    if (provider.selectedTags.isNotEmpty) {
      return provider.selectedTags.map((t) => '#$t').join(' ');
    }
    if (provider.selectedFolderId == Folder.allNotesId) return 'Tutte le note';
    if (provider.selectedFolderId == Folder.defaultNotesId) return 'Note';

    try {
      final folder = provider.folders.firstWhere((f) => f.id == provider.selectedFolderId);
      return folder.name;
    } catch (_) {
      return 'Note';
    }
  }

  void _showNoteContextMenu(BuildContext context, Note note, NotesProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          note.title.isEmpty ? 'Nuova nota' : note.title,
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
                Icon(
                  note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                  color: isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(note.isPinned ? 'Rimuovi da fissate' : 'Fissa nota'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.togglePin(note.id);
            },
          ),

          // Lock / Unlock
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  note.isLocked ? CupertinoIcons.lock_open : CupertinoIcons.lock,
                  color: isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(note.isLocked ? 'Rimuovi protezione' : 'Proteggi nota'),
              ],
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final security = context.read<SecurityService>();
              if (note.isLocked) {
                final unlocked = await LockNoteDialog.showUnlockDialog(context, security);
                if (unlocked) {
                  await provider.toggleLock(note.id);
                }
              } else {
                if (!security.hasMasterPin) {
                  final setPin = await LockNoteDialog.showSetPinDialog(context, security);
                  if (!setPin) return;
                }
                await provider.toggleLock(note.id);
              }
            },
          ),

          // Delete / Restore
          CupertinoActionSheetAction(
            isDestructiveAction: !provider.isTrashSelected,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  provider.isTrashSelected ? CupertinoIcons.arrow_uturn_left : CupertinoIcons.trash,
                  color: provider.isTrashSelected ? CupertinoColors.activeBlue : CupertinoColors.destructiveRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(provider.isTrashSelected ? 'Ripristina nota' : 'Elimina nota'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (provider.isTrashSelected) {
                provider.restoreFromTrash(note.id);
              } else {
                provider.moveToTrash(note.id);
              }
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

  void _showMoreMenu(BuildContext context, NotesProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(_getTitle(provider)),
        actions: [
          if (provider.isTrashSelected)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text('Svuota cestino'),
              onPressed: () async {
                Navigator.pop(ctx);
                final confirm = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (dCtx) => CupertinoAlertDialog(
                    title: const Text('Svuotare il cestino?'),
                    content: const Text('Tutte le note eliminate verranno rimosse permanentemente.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('Annulla'),
                        onPressed: () => Navigator.pop(dCtx, false),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Svuota'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.emptyTrash();
                }
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
    final notes = provider.notes;
    final tags = provider.tags;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppleTheme.darkSidebar : const Color(0xFFF2F2F7);
    final accentColor = isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight;
    final secondaryTextColor = isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary;

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bgColor.withValues(alpha: 0.85),
        border: null,
        leading: CupertinoNavigationBarBackButton(
          previousPageTitle: 'Cartelle',
          color: accentColor,
          onPressed: widget.onBackToFolders,
        ),
        middle: Text(
          _getTitle(provider),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.ellipsis_circle, color: accentColor, size: 22),
          onPressed: () => _showMoreMenu(context, provider),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Cerca note...',
                style: TextStyle(
                  color: isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary,
                  fontSize: 14,
                ),
                onChanged: (value) => provider.setSearchQuery(value),
              ),
            ),

            // Horizontal Tags Filter Carousel (if tags available)
            if (tags.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final isSelected = provider.isTagSelected(tag.name);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: GestureDetector(
                        onTap: () => provider.toggleTag(tag.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(alpha: isDark ? 0.3 : 0.2)
                                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(color: accentColor, width: 1.2)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#${tag.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? accentColor
                                      : (isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tag.count}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? accentColor
                                      : secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Notes List
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 48,
                            color: secondaryTextColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.searchQuery.isNotEmpty ? 'Nessun risultato' : 'Nessuna nota',
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      children: [
                        // Pinned notes section
                        if (pinnedNotes.isNotEmpty) ...[
                          _buildSectionHeader('FISSATE', secondaryTextColor),
                          ...pinnedNotes.map((note) => _buildDismissibleNoteCard(note, provider)),
                        ],

                        // Regular notes section
                        if (unpinnedNotes.isNotEmpty) ...[
                          if (pinnedNotes.isNotEmpty)
                            _buildSectionHeader('NOTE', secondaryTextColor),
                          ...unpinnedNotes.map((note) => _buildDismissibleNoteCard(note, provider)),
                        ],
                      ],
                    ),
            ),

            // Bottom Toolbar: Note counter & Nuova nota
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
                children: [
                  const SizedBox(width: 44), // balance right button
                  Expanded(
                    child: Center(
                      child: Text(
                        '${notes.length} ${notes.length == 1 ? 'nota' : 'note'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: widget.onNewNote,
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
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
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

  Widget _buildDismissibleNoteCard(Note note, NotesProvider provider) {
    return Dismissible(
      key: ValueKey(note.id),
      // Swipe right: Pin/Unpin, Swipe left: Delete/Trash
      background: Container(
        color: AppleTheme.accentYellow,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          note.isPinned ? CupertinoIcons.pin_slash_fill : CupertinoIcons.pin_fill,
          color: Colors.white,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        color: CupertinoColors.destructiveRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          provider.isTrashSelected ? CupertinoIcons.trash_fill : CupertinoIcons.trash,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Pin / Unpin
          await provider.togglePin(note.id);
          return false; // don't remove from tree
        } else if (direction == DismissDirection.endToStart) {
          // Delete / Move to trash
          if (provider.isTrashSelected) {
            await provider.permanentlyDeleteNote(note.id);
          } else {
            await provider.moveToTrash(note.id);
          }
          return true; // remove row
        }
        return false;
      },
      child: GestureDetector(
        onLongPress: () => _showNoteContextMenu(context, note, provider),
        child: NoteCard(
          note: note,
          isSelected: provider.selectedNoteId == note.id,
          onTap: () {
            provider.selectNote(note.id);
            widget.onNoteSelected?.call(note);
          },
          onTagTap: (tag) => provider.selectTag(tag),
        ),
      ),
    );
  }
}
