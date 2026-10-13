import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/state/notes_provider.dart';
import '../editor/notion_document_editor.dart';
import '../theme/apple_theme.dart';

/// Authentic macOS Sequoia Unified Window Titlebar & Toolbar.
class MacTitleBar extends StatelessWidget {
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;
  final ValueChanged<BlockType>? onSelectBlockType;
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUnderline;
  final VoidCallback? onChecklist;
  final VoidCallback? onTable;
  final VoidCallback? onDrawing;
  final VoidCallback? onPhoto;
  final VoidCallback? onLock;
  final VoidCallback? onMoreActions;
  final VoidCallback? onDelete;
  final VoidCallback? onNewNote;

  const MacTitleBar({
    super.key,
    required this.isSidebarVisible,
    required this.onToggleSidebar,
    this.onSelectBlockType,
    this.onBold,
    this.onItalic,
    this.onUnderline,
    this.onChecklist,
    this.onTable,
    this.onDrawing,
    this.onPhoto,
    this.onLock,
    this.onMoreActions,
    this.onDelete,
    this.onNewNote,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveNote = context.select<NotesProvider, bool>(
      (p) => p.selectedNoteId != null,
    );
    final isLocked = context.select<NotesProvider, bool>(
      (p) => p.selectedNote?.isLocked ?? false,
    );
    final isTrashSelected = context.select<NotesProvider, bool>(
      (p) => p.isTrashSelected,
    );
    final folderTitle = context.select<NotesProvider, String>(
      (p) => _getFolderTitle(p),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppleTheme.darkTextPrimary
        : AppleTheme.lightTextPrimary;

    final titleBar = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppleTheme.darkSidebar : AppleTheme.lightSidebar,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
            width: 0.8,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 840;
          final isVeryCompact = constraints.maxWidth < 660;

          return Row(
            children: [
              // 1. macOS Traffic Lights (Close, Minimize, Maximize)
              // On macOS, native traffic lights are rendered directly by the OS in the frameless window.
              // We reserve space for them so they do not overlap custom controls.
              if (!kIsWeb && Platform.isMacOS)
                const SizedBox(width: 68)
              else if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) ...[
                Row(
                  children: [
                    _buildTrafficLight(
                      color: AppleTheme.trafficRed,
                      tooltip: 'Chiudi',
                      onTap: () async {
                        if (!kIsWeb &&
                            (Platform.isLinux || Platform.isWindows)) {
                          // The waiting edit is written before the window closes and the app ends.
                          await context.read<NotesProvider>().flushOnAppLeavingForeground();
                          await windowManager.close();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildTrafficLight(
                      color: AppleTheme.trafficYellow,
                      tooltip: 'Riduci a icona',
                      onTap: () async {
                        if (!kIsWeb &&
                            (Platform.isLinux || Platform.isWindows)) {
                          await windowManager.minimize();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildTrafficLight(
                      color: AppleTheme.trafficGreen,
                      tooltip: 'Ingrandisci',
                      onTap: () async {
                        if (!kIsWeb &&
                            (Platform.isLinux || Platform.isWindows)) {
                          await _toggleMaximized();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],

              // Sidebar Toggle Button
              _MacIconButton(
                icon: CupertinoIcons.sidebar_left,
                tooltip: isSidebarVisible
                    ? 'Nascondi barra laterale'
                    : 'Mostra barra laterale',
                onPressed: onToggleSidebar,
                isActive: isSidebarVisible,
              ),
              const SizedBox(width: 10),

              // Divider
              Container(
                height: 18,
                width: 1,
                color: isDark
                    ? AppleTheme.darkDivider
                    : AppleTheme.lightDivider,
              ),
              const SizedBox(width: 10),

              // Section Title (Folder name)
              Flexible(
                child: Text(
                  folderTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),
              const Spacer(),

              // 2. Rich Text Toolbar Controls
              if (hasActiveNote && !isTrashSelected) ...[
                // macOS Sequoia-style "Aa" Paragraph Style Menu
                PopupMenuButton<BlockType>(
                  tooltip: 'Stile testo (Aa)',
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  onSelected: onSelectBlockType,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: BlockType.title,
                      child: Text(
                        'Titolo',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: BlockType.h1,
                      child: Text(
                        'Intestazione',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: BlockType.h2,
                      child: Text(
                        'Sottointestazione',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: BlockType.paragraph,
                      child: Text(
                        'Corpo',
                        style: TextStyle(fontSize: 13.5, color: textColor),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: BlockType.checklist,
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle,
                            size: 16,
                            color: isDark
                                ? AppleTheme.accentYellow
                                : AppleTheme.accentAmberLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Checklist',
                            style: TextStyle(fontSize: 13.5, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: BlockType.bullet,
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.list_bullet,
                            size: 16,
                            color: textColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Elenco puntato',
                            style: TextStyle(fontSize: 13.5, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: BlockType.numbered,
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.list_number,
                            size: 16,
                            color: textColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Elenco numerato',
                            style: TextStyle(fontSize: 13.5, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: BlockType.code,
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.chevron_left_slash_chevron_right,
                            size: 16,
                            color: textColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Monospazio',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: BlockType.quote,
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.quote_bubble,
                            size: 16,
                            color: textColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Citazione',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontStyle: FontStyle.italic,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 11,
                          color:
                              (isDark
                                      ? AppleTheme.darkTextSecondary
                                      : AppleTheme.lightTextSecondary)
                                  .withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Bold, Italic, Underline (spacious screens only; available via shortcuts and Aa menu)
                if (!isCompact) ...[
                  _MacIconButton(
                    icon: CupertinoIcons.bold,
                    tooltip: 'Grassetto (CTRL+B)',
                    onPressed: onBold,
                  ),
                  const SizedBox(width: 2),
                  _MacIconButton(
                    icon: CupertinoIcons.italic,
                    tooltip: 'Corsivo (CTRL+I)',
                    onPressed: onItalic,
                  ),
                  const SizedBox(width: 2),
                  _MacIconButton(
                    icon: CupertinoIcons.underline,
                    tooltip: 'Sottolineato (CTRL+U)',
                    onPressed: onUnderline,
                  ),
                  const SizedBox(width: 4),
                ],

                // Checklist quick button
                _MacIconButton(
                  icon: CupertinoIcons.checkmark_circle,
                  tooltip: 'Checklist',
                  onPressed: onChecklist,
                ),
                const SizedBox(width: 4),

                if (isVeryCompact) ...[
                  // Collapsed Insert / Attachments Menu
                  PopupMenuButton<String>(
                    tooltip: 'Inserisci',
                    offset: const Offset(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    onSelected: (val) {
                      if (val == 'table') onTable?.call();
                      if (val == 'drawing') onDrawing?.call();
                      if (val == 'photo') onPhoto?.call();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'table',
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.table,
                              size: 16,
                              color: textColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tabella',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'drawing',
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.pencil_outline,
                              size: 16,
                              color: textColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Disegno',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'photo',
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.photo,
                              size: 16,
                              color: textColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Immagine',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(CupertinoIcons.add, size: 18),
                    ),
                  ),
                ] else ...[
                  // Table
                  _MacIconButton(
                    icon: CupertinoIcons.table,
                    tooltip: 'Tabella',
                    onPressed: onTable,
                  ),
                  const SizedBox(width: 4),

                  // Drawing canvas
                  _MacIconButton(
                    icon: CupertinoIcons.pencil_outline,
                    tooltip: 'Disegno',
                    onPressed: onDrawing,
                  ),
                  const SizedBox(width: 4),

                  // Photo attachment
                  _MacIconButton(
                    icon: CupertinoIcons.photo,
                    tooltip: 'Inserisci immagine',
                    onPressed: onPhoto,
                  ),
                ],
                const SizedBox(width: 6),

                // Subtle vertical separator
                Container(
                  height: 18,
                  width: 1,
                  color: isDark
                      ? AppleTheme.darkDivider
                      : AppleTheme.lightDivider,
                ),
                const SizedBox(width: 6),

                // Lock
                _MacIconButton(
                  icon: isLocked
                      ? CupertinoIcons.lock_fill
                      : CupertinoIcons.lock,
                  color: isLocked
                      ? (isDark
                            ? AppleTheme.accentYellow
                            : AppleTheme.accentAmberLight)
                      : null,
                  tooltip: isLocked
                      ? 'Nota Protetta'
                      : 'Proteggi con Lucchetto',
                  onPressed: onLock,
                ),
                const SizedBox(width: 4),

                _MacIconButton(
                  icon: CupertinoIcons.ellipsis,
                  tooltip: 'Altre azioni',
                  onPressed: onMoreActions,
                ),
                const SizedBox(width: 4),

                // Delete
                _MacIconButton(
                  icon: CupertinoIcons.trash,
                  tooltip: 'Elimina nota',
                  onPressed: onDelete,
                ),
                const SizedBox(width: 6),
              ],
              if (hasActiveNote && isTrashSelected) ...[
                _MacIconButton(
                  icon: isLocked
                      ? CupertinoIcons.lock_fill
                      : CupertinoIcons.lock,
                  color: isLocked
                      ? (isDark
                            ? AppleTheme.accentYellow
                            : AppleTheme.accentAmberLight)
                      : null,
                  tooltip: isLocked
                      ? 'Nota Protetta'
                      : 'Proteggi con Lucchetto',
                  onPressed: onLock,
                ),
                const SizedBox(width: 4),
                _MacIconButton(
                  icon: CupertinoIcons.ellipsis,
                  tooltip: 'Altre azioni',
                  onPressed: onMoreActions,
                ),
                const SizedBox(width: 4),
                // Delete again: re-stamps the trash date of the trashed note
                _MacIconButton(
                  icon: CupertinoIcons.trash,
                  tooltip: 'Elimina nota',
                  onPressed: onDelete,
                ),
                const SizedBox(width: 6),
              ],

              // New Note Button (Apple Gold Button)
              if (!isTrashSelected) ...[
                if (isCompact)
                  _MacIconButton(
                    icon: CupertinoIcons.square_pencil,
                    tooltip: 'Nuova nota',
                    color: isDark
                        ? AppleTheme.accentYellow
                        : AppleTheme.accentAmberLight,
                    isActive: true,
                    onPressed:
                        onNewNote ??
                        () => context.read<NotesProvider>().createNote(),
                  )
                else
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minSize: 30,
                    color: AppleTheme.accentYellow,
                    borderRadius: BorderRadius.circular(8),
                    onPressed:
                        onNewNote ??
                        () => context.read<NotesProvider>().createNote(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          CupertinoIcons.square_pencil,
                          color: CupertinoColors.black,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Nuova nota',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );

    if (!kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => windowManager.startDragging(),
        onDoubleTap: _toggleMaximized,
        child: titleBar,
      );
    }
    return titleBar;
  }

  Future<void> _toggleMaximized() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  String _getFolderTitle(NotesProvider provider) {
    if (provider.isTrashSelected) return 'Eliminati di recente';
    if (provider.selectedTags.isNotEmpty) {
      return provider.selectedTags.map((t) => '#$t').join(' ');
    }
    final folder = provider.folders.cast<dynamic>().firstWhere(
      (f) => f.id == provider.selectedFolderId,
      orElse: () => null,
    );
    return folder?.name ?? 'Tutte le note';
  }

  Widget _buildTrafficLight({
    required Color color,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    final light = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 0.8,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: light,
      );
    }
    return light;
  }
}

class _MacIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isActive;

  const _MacIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor =
        color ??
        (isActive
            ? AppleTheme.accentYellow
            : (isDark
                  ? AppleTheme.darkTextSecondary
                  : AppleTheme.lightTextSecondary));

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: CupertinoButton(
        padding: const EdgeInsets.all(6),
        minSize: 32,
        borderRadius: BorderRadius.circular(6),
        color: isActive ? AppleTheme.accentYellow.withOpacity(0.15) : null,
        onPressed: onPressed,
        child: Icon(icon, size: 18, color: baseColor),
      ),
    );
  }
}
