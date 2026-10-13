import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/vault_service.dart';
import '../../core/models/note_model.dart';
import '../../core/state/notes_provider.dart';
import '../drawing/apple_pencil_canvas.dart';
import '../editor/notion_document_editor.dart';
import '../mobile/mobile_folders_screen.dart';
import '../mobile/mobile_notes_list_screen.dart';
import '../mobile/mobile_note_editor_screen.dart';
import '../notes_list/notes_list_view.dart';
import '../sidebar/sidebar_view.dart';
import '../notes_list/note_action_menu.dart';
import '../notes_list/note_actions.dart';
import '../theme/apple_theme.dart';
import 'mac_title_bar.dart';

/// Responsive and Adaptive Shell with Authentic macOS Sequoia Window Frame.
class AdaptiveAppShell extends StatefulWidget {
  const AdaptiveAppShell({super.key});

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  bool? _userToggledSidebar;
  final GlobalKey<NotionDocumentEditorState> _editorKey =
      GlobalKey<NotionDocumentEditorState>();

  void _onChecklist() => _editorKey.currentState?.insertChecklist();
  void _onSelectBlockType(BlockType type) =>
      _editorKey.currentState?.setBlockType(type);
  void _onBold() => _editorKey.currentState?.toggleBold();
  void _onItalic() => _editorKey.currentState?.toggleItalic();
  void _onUnderline() => _editorKey.currentState?.toggleUnderline();
  void _onTable() => _editorKey.currentState?.insertTable();

  void _onDrawing(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (ctx) => ApplePencilCanvas(
          onSave: (pngBytes) async {
            final vault = context.read<VaultService>();
            final relativePath = await vault.saveAttachment(pngBytes, 'png');
            _editorKey.currentState?.insertImage(relativePath);
          },
        ),
      ),
    );
  }

  Future<void> _onPhoto(BuildContext context) async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.image,
    );
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      final vault = context.read<VaultService>();
      final ext = result.first.extension ?? 'png';
      final relativePath = await vault.saveAttachment(bytes, ext);
      _editorKey.currentState?.insertImage(relativePath);
    }
  }

  void _onDelete(NotesProvider provider) {
    final note = provider.selectedNote;
    if (note == null) return;
    // In the trash the note is already trashed: only refresh its trash date.
    // No snackbar Annulla, which would restore it.
    if (provider.isTrashSelected) {
      provider.moveToTrash(note.id);
    } else {
      NoteActions.handle(context, note, NoteMenuAction.trash);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 680) {
          return _buildDesktopLayout(context, constraints);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  /// macOS Sequoia Layout with Unified Window Chrome and Adaptive Columns
  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    // Only rebuild shell when the selected note ID or its lock status changes, never on content keystrokes
    context.select<NotesProvider, (String?, bool?)>(
      (p) => (p.selectedNoteId, p.selectedNote?.isLocked),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-collapse sidebar on medium screens (< 960px) unless user explicitly toggled it
    final bool isSidebarVisible =
        _userToggledSidebar ?? (constraints.maxWidth >= 960);

    return Scaffold(
      backgroundColor: isDark ? AppleTheme.darkEditor : AppleTheme.lightEditor,
      body: Column(
        children: [
          // Unified macOS Window Titlebar & Toolbar
          MacTitleBar(
            isSidebarVisible: isSidebarVisible,
            onToggleSidebar: () =>
                setState(() => _userToggledSidebar = !isSidebarVisible),
            onSelectBlockType: _onSelectBlockType,
            onBold: _onBold,
            onItalic: _onItalic,
            onUnderline: _onUnderline,
            onChecklist: _onChecklist,
            onTable: _onTable,
            onDrawing: () => _onDrawing(context),
            onPhoto: () => _onPhoto(context),
            onLock: () {
              final note = context.read<NotesProvider>().selectedNote;
              if (note != null) {
                NoteActions.handle(context, note, NoteMenuAction.lock);
              }
            },
            onMoreActions: () {
              final note = context.read<NotesProvider>().selectedNote;
              if (note != null) {
                NoteActions.showDesktop(
                  context,
                  note,
                  Offset(MediaQuery.sizeOf(context).width - 230, 48),
                );
              }
            },
            onDelete: () => _onDelete(context.read<NotesProvider>()),
            onNewNote: () => context.read<NotesProvider>().createNote(),
          ),

          // Adaptive Split View Body
          Expanded(
            child: Row(
              children: [
                // Column 1: Sidebar (220px standard macOS)
                if (isSidebarVisible) const SidebarView(),

                // Column 2: Notes List (260px)
                const SizedBox(width: 260, child: NotesListView()),

                // Column 3: Note Editor
                Expanded(
                  child: Selector<NotesProvider, Note?>(
                    selector: (_, p) => p.selectedNote,
                    builder: (_, selectedNote, _) => selectedNote != null
                        ? NotionDocumentEditor(
                            key: _editorKey,
                            note: selectedNote,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 56,
                                  color: isDark
                                      ? AppleTheme.darkTextSecondary.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppleTheme.lightTextSecondary.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nessuna nota selezionata',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? AppleTheme.darkTextSecondary
                                        : AppleTheme.lightTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Stack Navigation for Mobile screens with authentic iOS Apple Notes flow
  Widget _buildMobileLayout(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          CupertinoPageRoute(
            builder: (foldersContext) => MobileFoldersScreen(
              onOpenNotesList: () {
                Navigator.of(foldersContext).push(
                  CupertinoPageRoute(
                    builder: (listContext) =>
                        _buildMobileNotesListScreen(context, listContext),
                  ),
                );
              },
              onSelectFolder: (folderId) {
                context.read<NotesProvider>().selectFolder(folderId);
              },
              onNewNote: () async {
                final newNote = await context
                    .read<NotesProvider>()
                    .createNote();
                if (newNote != null && foldersContext.mounted) {
                  Navigator.of(foldersContext).push(
                    CupertinoPageRoute(
                      builder: (editorContext) => MobileNoteEditorScreen(
                        note: newNote,
                        backFolderTitle: 'Cartelle',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          CupertinoPageRoute(
            builder: (listContext) =>
                _buildMobileNotesListScreen(context, listContext),
          ),
        ];
      },
    );
  }

  Widget _buildMobileNotesListScreen(
    BuildContext appContext,
    BuildContext navContext,
  ) {
    final provider = appContext.read<NotesProvider>();
    return MobileNotesListScreen(
      onBackToFolders: () {
        if (Navigator.of(navContext).canPop()) {
          Navigator.of(navContext).pop();
        }
      },
      onNoteSelected: (note) {
        Navigator.of(navContext).push(
          CupertinoPageRoute(
            builder: (_) => MobileNoteEditorScreen(
              note: note,
              backFolderTitle: provider.isTrashSelected
                  ? 'Cestino'
                  : (provider.selectedTags.isNotEmpty
                        ? provider.selectedTags.map((t) => '#$t').join(' ')
                        : 'Note'),
            ),
          ),
        );
      },
      onNewNote: () async {
        final newNote = await provider.createNote();
        if (newNote != null && navContext.mounted) {
          Navigator.of(navContext).push(
            CupertinoPageRoute(
              builder: (_) => MobileNoteEditorScreen(
                note: newNote,
                backFolderTitle: 'Note',
              ),
            ),
          );
        }
      },
    );
  }
}
