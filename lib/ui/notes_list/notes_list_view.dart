import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/note_model.dart';
import '../../core/state/notes_provider.dart';
import '../../core/services/security_service.dart';
import '../theme/apple_theme.dart';
import 'note_actions.dart';
import '../security/lock_note_dialog.dart';
import 'note_card.dart';

/// Middle pane displaying the search field and grouped list of notes.
class NotesListView extends StatefulWidget {
  final Function(Note note)? onNoteSelected;

  const NotesListView({super.key, this.onNoteSelected});

  @override
  State<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<NotesListView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // The layout can switch while a search is active: show the query still filtering the list.
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

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    _syncSearchField(notesProvider.searchQuery);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = notesProvider.notes;

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final otherNotes = notes.where((n) => !n.isPinned).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppleTheme.darkNoteList : AppleTheme.lightNoteList,
        border: Border(
          right: BorderSide(
            color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Field
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Cerca',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppleTheme.darkTextPrimary
                    : AppleTheme.lightTextPrimary,
              ),
              backgroundColor: isDark
                  ? AppleTheme.darkSearchBg
                  : AppleTheme.lightSearchBg,
              borderRadius: BorderRadius.circular(8),
              onChanged: (value) => notesProvider.setSearchQuery(value),
            ),
          ),

          // Trash Notice Banner
          if (notesProvider.isTrashSelected)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.destructiveRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle,
                    color: CupertinoColors.destructiveRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Eliminati di recente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    child: const Text(
                      'Svuota',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                    onPressed: () => _confirmEmptyTrash(context, notesProvider),
                  ),
                ],
              ),
            ),

          // Active Tag Filter Banner
          if (notesProvider.selectedTags.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? AppleTheme.accentYellow
                            : AppleTheme.accentAmberLight)
                        .withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      (isDark
                              ? AppleTheme.accentYellow
                              : AppleTheme.accentAmberLight)
                          .withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.number,
                    size: 13,
                    color: isDark
                        ? AppleTheme.accentYellow
                        : AppleTheme.accentAmberLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tag: ${notesProvider.selectedTags.map((t) => '#$t').join(' ')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppleTheme.accentYellow
                            : AppleTheme.accentAmberLight,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 20,
                    onPressed: () => notesProvider.selectTag(null),
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 16,
                      color: isDark
                          ? AppleTheme.darkTextSecondary
                          : AppleTheme.lightTextSecondary,
                    ),
                  ),
                ],
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
                          CupertinoIcons.doc_text_search,
                          size: 40,
                          color: isDark
                              ? AppleTheme.darkTextSecondary.withOpacity(0.5)
                              : AppleTheme.lightTextSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notesProvider.selectedTags.isNotEmpty
                              ? 'Nessuna nota con ${notesProvider.selectedTags.map((t) => '#$t').join(', ')}'
                              : (notesProvider.searchQuery.isNotEmpty
                                    ? 'Nessun risultato trovato'
                                    : (notesProvider.isTrashSelected
                                          ? 'Cestino vuoto'
                                          : 'Nessuna nota')),
                          style: TextStyle(
                            color: isDark
                                ? AppleTheme.darkTextSecondary
                                : AppleTheme.lightTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notesProvider.selectedTags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minSize: 28,
                            color:
                                (isDark
                                        ? AppleTheme.accentYellow
                                        : AppleTheme.accentAmberLight)
                                    .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            onPressed: () => notesProvider.selectTag(null),
                            child: Text(
                              'Mostra tutte le note',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppleTheme.accentYellow
                                    : AppleTheme.accentAmberLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      // Pinned Section
                      if (pinnedNotes.isNotEmpty) ...[
                        _buildSectionHeader('IN PRIMO PIANO', isDark),
                        ...pinnedNotes.map(
                          (note) =>
                              _buildNoteCard(context, note, notesProvider),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Other Notes Section
                      if (otherNotes.isNotEmpty) ...[
                        if (pinnedNotes.isNotEmpty)
                          _buildSectionHeader('NOTE', isDark),
                        ...otherNotes.map(
                          (note) =>
                              _buildNoteCard(context, note, notesProvider),
                        ),
                      ],
                    ],
                  ),
          ),

          // Bottom Count Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppleTheme.darkDivider
                      : AppleTheme.lightDivider,
                  width: 0.8,
                ),
              ),
            ),
            child: Center(
              child: Text(
                '${notes.length} ${notes.length == 1 ? 'nota' : 'note'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppleTheme.darkTextSecondary
                      : AppleTheme.lightTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark
              ? AppleTheme.darkTextSecondary.withOpacity(0.8)
              : AppleTheme.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    Note note,
    NotesProvider provider,
  ) {
    void openMenu(Offset position) {
      NoteActions.showDesktop(context, note, position);
    }

    return Focus(
      canRequestFocus: true,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.f10, shift: true): () =>
              openMenu(const Offset(260, 60)),
          const SingleActivator(LogicalKeyboardKey.contextMenu): () =>
              openMenu(const Offset(260, 60)),
        },
        child: GestureDetector(
          onSecondaryTapDown: (details) => openMenu(details.globalPosition),
          onLongPressStart: (details) => openMenu(details.globalPosition),
          child: NoteCard(
            note: note,
            isSetAside: provider.isNoteSetAside(note.id),
            isSelected: note.id == provider.selectedNoteId,
            onMenu: () {
              final box = context.findRenderObject() as RenderBox?;
              final position = box?.localToGlobal(Offset.zero) ?? Offset.zero;
              openMenu(position + const Offset(240, 50));
            },
            onTap: () {
              provider.selectNote(note.id);
              widget.onNoteSelected?.call(note);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    NotesProvider provider,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Svuota Cestino'),
        content: const Text(
          'Tutte le note nel cestino verranno eliminate definitivamente.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annulla'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Svuota'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final hasProtected = await provider.trashHasProtectedNote();
    if (!context.mounted) return;
    if (hasProtected) {
      final security = context.read<SecurityService>();
      final unlocked = await LockNoteDialog.showUnlockDialog(context, security);
      if (!unlocked || !context.mounted) return;
    }
    await provider.emptyTrash();
  }
}
