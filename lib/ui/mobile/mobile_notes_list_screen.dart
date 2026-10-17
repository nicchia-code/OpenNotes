import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/folder_model.dart';
import '../../core/models/note_model.dart';
import '../../core/services/sync_service.dart';
import '../../core/state/notes_provider.dart';
import '../../core/services/security_service.dart';
import '../notes_list/note_card.dart';
import '../notes_list/note_actions.dart';
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
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // The list is a new route each time it opens: show the query still filtering it.
    _searchController = TextEditingController(
      text: context.read<NotesProvider>().searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // The provider drops the query when a note is created: clear the field too.
  void _syncSearchField(String query) {
    if (query.isEmpty && _searchController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchController.clear();
      });
    }
  }

  String _getTitle(NotesProvider provider) {
    if (provider.isTrashSelected) return 'Eliminati di recente';
    if (provider.selectedTags.isNotEmpty) {
      return provider.selectedTags.map((t) => '#$t').join(' ');
    }
    if (provider.selectedFolderId == Folder.allNotesId) return 'Tutte le note';
    if (provider.selectedFolderId == Folder.defaultNotesId) return 'Note';

    return provider.selectedFolderName ?? 'Note';
  }

  void _showNoteContextMenu(
    BuildContext context,
    Note note,
    NotesProvider provider,
  ) {
    NoteActions.showMobile(
      context,
      note,
      onOpenAfterDuplicate: (opened) {
        provider.selectNote(opened.id);
        widget.onNoteSelected?.call(opened);
      },
      fromList: true,
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
                  builder: (dialogContext) => CupertinoAlertDialog(
                    title: const Text('Svuotare il cestino?'),
                    content: const Text(
                      'Tutte le note eliminate verranno rimosse permanentemente.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Annulla'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Svuota'),
                      ),
                    ],
                  ),
                );
                if (confirm != true || !context.mounted) return;
                final hasProtected = await provider.trashHasProtectedNote();
                if (!context.mounted) return;
                if (hasProtected) {
                  final security = context.read<SecurityService>();
                  final unlocked = await LockNoteDialog.showUnlockDialog(
                    context,
                    security,
                  );
                  if (!unlocked || !context.mounted) return;
                }
                await provider.emptyTrash();
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
    final sync = context.watch<SyncService>();
    _syncSearchField(provider.searchQuery);
    final notes = provider.notes;
    final tags = provider.tags;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppleTheme.darkSidebar : const Color(0xFFF2F2F7);
    final accentColor = isDark
        ? AppleTheme.accentYellow
        : AppleTheme.accentAmberLight;
    final secondaryTextColor = isDark
        ? AppleTheme.darkTextSecondary
        : AppleTheme.lightTextSecondary;

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
          child: Icon(
            CupertinoIcons.ellipsis_circle,
            color: accentColor,
            size: 22,
          ),
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
                  color: isDark
                      ? AppleTheme.darkTextPrimary
                      : AppleTheme.lightTextPrimary,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(
                                    alpha: isDark ? 0.3 : 0.2,
                                  )
                                : (isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFE5E5EA)),
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
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? accentColor
                                      : (isDark
                                            ? AppleTheme.darkTextPrimary
                                            : AppleTheme.lightTextPrimary),
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
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // Only with a connected account: without one the gesture is not available.
                  if (sync.isAuthenticated)
                    CupertinoSliverRefreshControl(onRefresh: sync.syncNow),
                  if (notes.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
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
                              provider.searchQuery.isNotEmpty
                                  ? 'Nessun risultato'
                                  : 'Nessuna nota',
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      sliver: SliverList.list(
                        children: [
                          // Pinned notes section
                          if (pinnedNotes.isNotEmpty) ...[
                            _buildSectionHeader('FISSATE', secondaryTextColor),
                            ...pinnedNotes.map(
                              (note) => _buildDismissibleNoteCard(note, provider),
                            ),
                          ],

                          // Regular notes section
                          if (unpinnedNotes.isNotEmpty) ...[
                            if (pinnedNotes.isNotEmpty)
                              _buildSectionHeader('NOTE', secondaryTextColor),
                            ...unpinnedNotes.map(
                              (note) => _buildDismissibleNoteCard(note, provider),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Toolbar: Note counter & Nuova nota
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF9F9F9),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppleTheme.darkDivider
                        : AppleTheme.lightDivider,
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
                  if (provider.isTrashSelected)
                    const SizedBox(width: 44) // keep the counter centred
                  else
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.onNewNote,
                      child: Icon(
                        CupertinoIcons.square_pencil,
                        color: accentColor,
                        size: 24,
                      ),
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
      // Swipe right: Pin/Unpin; swipe left: Move to trash (not in trash)
      direction: provider.isTrashSelected
          ? DismissDirection.startToEnd
          : DismissDirection.horizontal,
      background: Container(
        color: AppleTheme.accentYellow,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          note.isPinned
              ? CupertinoIcons.pin_slash_fill
              : CupertinoIcons.pin_fill,
          color: Colors.white,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        color: CupertinoColors.destructiveRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          CupertinoIcons.trash,
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
          // Move to trash
          if (!await provider.moveToTrash(note.id)) return false;
          if (mounted) {
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
          return true;
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
          isSetAside: provider.isNoteSetAside(note.id),
          onTagTap: (tag) => provider.selectTag(tag),
        ),
      ),
    );
  }
}
