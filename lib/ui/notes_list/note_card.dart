import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/note_model.dart';
import '../../core/state/notes_provider.dart';
import '../theme/apple_theme.dart';
import '../../core/services/sync_service.dart';
import '../sync/sync_state_glyph.dart';

/// Single Note Card in the middle list, mimicking Apple Notes macOS Sequoia layout.
class NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(String tag)? onTagTap;
  final VoidCallback? onMenu;
  final bool isSetAside;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    this.onTagTap,
    this.onMenu,
    this.isSetAside = false,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(date.year, date.month, date.day);

    if (noteDay == today) {
      return DateFormat('HH:mm').format(date);
    } else if (today.difference(noteDay).inDays == 1) {
      return 'Ieri';
    } else if (today.difference(noteDay).inDays < 7) {
      return DateFormat('EEEE', 'it_IT').format(date);
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isSelected
        ? (isDark ? AppleTheme.darkCardSelected : AppleTheme.lightCardSelected)
        : Colors.transparent;

    final titleColor = isSelected
        ? (isDark ? Colors.white : const Color(0xFF1D1D1F))
        : (isDark ? AppleTheme.darkTextPrimary : AppleTheme.lightTextPrimary);

    final secondaryColor = isSelected
        ? (isDark ? const Color(0xFFD4A843) : const Color(0xFF8A6400))
        : (isDark
              ? AppleTheme.darkTextSecondary
              : AppleTheme.lightTextSecondary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppleTheme.accentYellow.withOpacity(
                    isDark ? 0.2 : 0.25,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: isDark
              ? AppleTheme.darkCardHover
              : AppleTheme.lightCardHover,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Status Indicators
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Nuova nota' : note.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: titleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onMenu != null && isSelected)
                      IconButton(
                        tooltip: 'Altre azioni',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onMenu,
                        icon: Icon(
                          CupertinoIcons.ellipsis,
                          size: 17,
                          color: secondaryColor,
                        ),
                      ),
                    if (note.isLocked) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 13,
                        color: secondaryColor,
                      ),
                    ],
                    if (note.isPinned) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        CupertinoIcons.pin_fill,
                        size: 13,
                        color: AppleTheme.accentYellow,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),

                // Date & Snippet Row
                Row(
                  children: [
                    Text(
                      _formatDate(note.updatedAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                    if (isSetAside) ...[
                      const SizedBox(width: 4),
                      SyncStateGlyph(
                        state: SyncRunState.offline,
                        color: secondaryColor,
                        size: 14,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note.snippet,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isSelected
                              ? (isDark
                                    ? Colors.white70
                                    : const Color(0xFF4A4A4F))
                              : (isDark
                                    ? AppleTheme.darkTextSecondary
                                    : AppleTheme.lightTextSecondary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Tags Chips
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      ...note.tags.take(3).map((tag) {
                        final tagColor = isDark
                            ? AppleTheme.accentYellow
                            : AppleTheme.accentAmberLight;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (onTagTap != null) {
                              onTagTap!(tag);
                            } else {
                              try {
                                context.read<NotesProvider>().selectTag(tag);
                              } catch (_) {}
                            }
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? Colors.black26 : Colors.white70)
                                    : tagColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: tagColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (note.tags.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppleTheme.darkTextSecondary
                                        : AppleTheme.lightTextSecondary)
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '+${note.tags.length - 3}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppleTheme.darkTextSecondary
                                  : AppleTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
