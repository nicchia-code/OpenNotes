import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/note_model.dart';
import '../../core/state/notes_provider.dart';
import '../theme/apple_theme.dart';
import 'note_card.dart';

/// Middle pane displaying the search field and grouped list of notes.
class NotesListView extends StatefulWidget {
  final Function(Note note)? onNoteSelected;

  const NotesListView({super.key, this.onNoteSelected});

  @override
  State<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<NotesListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
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
                color: isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary,
              ),
              backgroundColor: isDark ? AppleTheme.darkSearchBg : AppleTheme.lightSearchBg,
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
                  const Icon(CupertinoIcons.info_circle, color: CupertinoColors.destructiveRed, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Eliminati di recente',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.destructiveRed),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    child: const Text('Svuota', style: TextStyle(fontSize: 12, color: CupertinoColors.destructiveRed)),
                    onPressed: () => _confirmEmptyTrash(context, notesProvider),
                  ),
                ],
              ),
            ),

          // Active Tag Filter Banner
          if (notesProvider.selectedTag != null && notesProvider.selectedTag!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight).withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.number,
                    size: 13,
                    color: isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tag: #${notesProvider.selectedTag}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight,
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
                      color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
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
                          color: isDark ? AppleTheme.darkTextSecondary.withOpacity(0.5) : AppleTheme.lightTextSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notesProvider.selectedTag != null
                              ? 'Nessuna nota con #${notesProvider.selectedTag}'
                              : (notesProvider.searchQuery.isNotEmpty
                                  ? 'Nessun risultato trovato'
                                  : (notesProvider.isTrashSelected ? 'Cestino vuoto' : 'Nessuna nota')),
                          style: TextStyle(
                            color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notesProvider.selectedTag != null) ...[
                          const SizedBox(height: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minSize: 28,
                            color: (isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            onPressed: () => notesProvider.selectTag(null),
                            child: Text(
                              'Mostra tutte le note',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight,
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
                        ...pinnedNotes.map((note) => NoteCard(
                              note: note,
                              isSelected: note.id == notesProvider.selectedNoteId,
                              onTap: () {
                                notesProvider.selectNote(note.id);
                                widget.onNoteSelected?.call(note);
                              },
                            )),
                        const SizedBox(height: 8),
                      ],

                      // Other Notes Section
                      if (otherNotes.isNotEmpty) ...[
                        if (pinnedNotes.isNotEmpty) _buildSectionHeader('NOTE', isDark),
                        ...otherNotes.map((note) => NoteCard(
                              note: note,
                              isSelected: note.id == notesProvider.selectedNoteId,
                              onTap: () {
                                notesProvider.selectNote(note.id);
                                widget.onNoteSelected?.call(note);
                              },
                            )),
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
                  color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
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
                  color: isDark ? AppleTheme.darkTextSecondary : AppleTheme.lightTextSecondary,
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
          color: isDark ? AppleTheme.darkTextSecondary.withOpacity(0.8) : AppleTheme.lightTextSecondary,
        ),
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, NotesProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Svuota Cestino'),
        content: const Text('Tutte le note nel cestino verranno eliminate definitivamente.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annulla'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Svuota'),
            onPressed: () {
              provider.emptyTrash();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
