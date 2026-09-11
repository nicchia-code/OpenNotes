import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../models/tag_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/vault_service.dart';

/// Central state provider for OpenNotes.
/// Connects SQLite database, Vault file system, and UI seamlessly.
class NotesProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final VaultService _vaultService;
  final SyncService _syncService;

  List<Folder> _folders = [];
  List<Note> _notes = [];
  List<Tag> _tags = [];
  String _selectedFolderId = Folder.allNotesId;
  Set<String> _selectedTags = {};
  String? _selectedNoteId;
  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _debounceSaveTimer;
  Map<String, int> _folderCounts = {};
  int _trashCount = 0;
  bool _disposed = false;

  NotesProvider({
    required DatabaseService dbService,
    required VaultService vaultService,
    required SyncService syncService,
  })  : _dbService = dbService,
        _vaultService = vaultService,
        _syncService = syncService {
    _syncService.addListener(_onSyncChanged);
  }

  void _onSyncChanged() {
    if (_disposed) return;
    if (!_syncService.isSyncing) {
      refreshFolders();
      refreshTags();
      refreshNotes();
    }
  }

  List<Folder> get folders => _folders;
  List<Note> get notes => _notes;
  List<Tag> get tags => _tags;
  String get selectedFolderId => _selectedFolderId;
  String? get selectedTag => _selectedTags.isNotEmpty ? _selectedTags.first : null;
  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);
  bool isTagSelected(String tag) => _selectedTags.contains(tag.replaceAll('#', '').trim().toLowerCase());
  String? get selectedNoteId => _selectedNoteId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  int getNoteCountForFolder(String folderId) => _folderCounts[folderId] ?? 0;
  int get trashCount => _trashCount;

  Note? get selectedNote {
    if (_selectedNoteId == null) return null;
    try {
      return _notes.firstWhere((n) => n.id == _selectedNoteId);
    } catch (_) {
      return null;
    }
  }

  bool get isTrashSelected => _selectedFolderId == Folder.trashId;

  /// Initializes provider and loads folders, tags and initial notes.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await refreshFolders();
    await refreshTags();
    await refreshNotes();

    // Auto-select first note if available on desktop/tablet
    if (_notes.isNotEmpty && _selectedNoteId == null) {
      _selectedNoteId = _notes.first.id;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refreshes folder list from database
  Future<void> refreshFolders() async {
    _folders = await _dbService.getFolders();
    notifyListeners();
    refreshCounts();
  }

  /// Refreshes tag list from database
  Future<void> refreshTags() async {
    _tags = await _dbService.getAllTags();
    notifyListeners();
  }

  /// Refreshes folder note counts and trash count
  Future<void> refreshCounts() async {
    final counts = <String, int>{};
    counts[Folder.allNotesId] = await _dbService.getNotesCount(isDeleted: false);
    counts[Folder.defaultNotesId] = await _dbService.getNotesCount(folderId: Folder.defaultNotesId, isDeleted: false);
    for (final folder in _folders) {
      counts[folder.id] = await _dbService.getNotesCount(folderId: folder.id, isDeleted: false);
    }
    _folderCounts = counts;
    _trashCount = await _dbService.getTrashCount();
    notifyListeners();
  }

  /// Refreshes notes list based on current filters
  Future<void> refreshNotes() async {
    final isDeleted = isTrashSelected;
    // When filtering by tag, search across all folders
    final folderId = _selectedTags.isNotEmpty
        ? null
        : (isTrashSelected ? null : (_selectedFolderId.isEmpty ? null : _selectedFolderId));

    _notes = await _dbService.getNotes(
      folderId: folderId,
      tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
      isDeleted: isDeleted,
      searchQuery: _searchQuery,
    );

    // If currently selected note is no longer in the list, select first or null
    if (_selectedNoteId != null && !_notes.any((n) => n.id == _selectedNoteId)) {
      _selectedNoteId = _notes.isNotEmpty ? _notes.first.id : null;
    } else if (_selectedNoteId == null && _notes.isNotEmpty) {
      _selectedNoteId = _notes.first.id;
    }

    notifyListeners();
    refreshCounts();
  }

  /// Selects a folder and filters notes
  void selectFolder(String folderId) {
    _selectedFolderId = folderId;
    _selectedTags.clear();
    refreshNotes();
  }

  /// Selects a tag and filters notes across all folders (toggles off if tapped again, or multi-selects)
  void selectTag(String? tag, {bool multiSelect = false}) {
    if (tag == null) {
      _selectedTags.clear();
    } else {
      final clean = tag.replaceAll('#', '').trim().toLowerCase();
      if (clean.isEmpty) {
        _selectedTags.clear();
      } else if (multiSelect) {
        if (_selectedTags.contains(clean)) {
          _selectedTags.remove(clean);
        } else {
          _selectedTags.add(clean);
        }
      } else {
        if (_selectedTags.length == 1 && _selectedTags.contains(clean)) {
          _selectedTags.clear();
        } else {
          _selectedTags = {clean};
        }
      }
    }
    _selectedFolderId = Folder.allNotesId;
    refreshNotes();
  }

  /// Toggles a tag in the multi-tag selection
  void toggleTag(String tag) => selectTag(tag, multiSelect: true);

  /// Clears active tag selection
  void clearSelectedTags() {
    _selectedTags.clear();
    refreshNotes();
  }

  /// Selects an active note for viewing/editing
  void selectNote(String? noteId) {
    _selectedNoteId = noteId;
    notifyListeners();
  }

  /// Updates live search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshNotes();
  }

  /// Creates a new Note in the current folder (or default notes folder)
  /// If creating inside a tag view (or multiple tags), appends those tags at the top of the note.
  Future<Note> createNote({String initialTitle = 'Nuova nota', String initialContent = ''}) async {
    const uuid = Uuid();
    final now = DateTime.now();

    String targetFolderId = _selectedFolderId;
    if (targetFolderId == Folder.allNotesId ||
        targetFolderId == Folder.quickNotesId ||
        targetFolderId == Folder.trashId ||
        targetFolderId.isEmpty) {
      targetFolderId = Folder.defaultNotesId;
    }

    String content = initialContent;
    final noteTags = <String>[];

    if (_selectedTags.isNotEmpty) {
      final tagsPrefix = _selectedTags.map((t) => '#$t').join(' ');
      noteTags.addAll(_selectedTags);
      if (content.trim().isEmpty) {
        content = '$tagsPrefix\n\n';
      } else if (!content.contains(tagsPrefix)) {
        content = '$tagsPrefix\n$content';
      }
    }

    final newNote = Note(
      id: uuid.v4(),
      title: initialTitle,
      content: content,
      folderId: targetFolderId,
      tags: noteTags,
      createdAt: now,
      updatedAt: now,
      cachedSnippet: Note.extractSnippet(content),
    );

    // Save to database
    await _dbService.upsertNote(newNote);
    // Save to Vault Markdown file
    await _vaultService.saveNote(newNote);
    // Queue sync
    await _syncService.notifyNoteChanged(newNote);

    await refreshNotes();
    await refreshTags();

    _selectedNoteId = newNote.id;
    notifyListeners();
    return newNote;
  }

  /// Updates note content with debouncing to prevent excessive disk/DB writes
  void updateNoteContent(String noteId, String newContent) {
    final note = _notes.cast<Note?>().firstWhere((n) => n?.id == noteId, orElse: () => null);
    if (note == null) return;

    final newTitle = Note.extractTitle(newContent);
    final tags = Note.extractTagsFromContent(newContent);
    final updatedNote = note.copyWith(
      title: newTitle,
      content: newContent,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    // Optimistically update memory list for instant typing responsiveness
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }

    // Debounced persist to DB and File
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 400), () async {
      await _dbService.upsertNote(updatedNote);
      await _vaultService.saveNote(updatedNote);
      await _syncService.notifyNoteChanged(updatedNote);
      await refreshTags();
    });
  }

  /// Toggles pinned state of a note
  Future<void> togglePin(String noteId) async {
    final note = await _dbService.getNoteById(noteId);
    if (note == null) return;

    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );

    await _dbService.upsertNote(updated);
    await _vaultService.saveNote(updated);
    await _syncService.notifyNoteChanged(updated);
    await refreshNotes();
  }

  /// Toggles locked state of a note
  Future<void> toggleLock(String noteId) async {
    final note = await _dbService.getNoteById(noteId);
    if (note == null) return;

    final updated = note.copyWith(
      isLocked: !note.isLocked,
      updatedAt: DateTime.now(),
    );

    await _dbService.upsertNote(updated);
    await _vaultService.saveNote(updated);
    await _syncService.notifyNoteChanged(updated);
    await refreshNotes();
  }

  /// Moves note to trash
  Future<void> moveToTrash(String noteId) async {
    await _dbService.moveToTrash(noteId);
    final note = await _dbService.getNoteById(noteId);
    if (note != null) {
      await _vaultService.saveNote(note);
      await _syncService.notifyNoteChanged(note);
    }
    await refreshNotes();
  }

  /// Restores note from trash
  Future<void> restoreFromTrash(String noteId) async {
    await _dbService.restoreFromTrash(noteId);
    final note = await _dbService.getNoteById(noteId);
    if (note != null) {
      await _vaultService.saveNote(note);
      await _syncService.notifyNoteChanged(note);
    }
    await refreshNotes();
  }

  /// Permanently deletes note
  Future<void> permanentlyDeleteNote(String noteId) async {
    final note = await _dbService.getNoteById(noteId);
    if (note != null && note.filePath != null) {
      await _vaultService.deleteNoteFile(note.filePath!);
      await _syncService.notifyNoteChanged(note, isDelete: true);
    }
    await _dbService.permanentlyDeleteNote(noteId);
    await refreshNotes();
  }

  /// Empties trash completely
  Future<void> emptyTrash() async {
    final trashed = await _dbService.getNotes(isDeleted: true);
    for (final note in trashed) {
      if (note.filePath != null) {
        await _vaultService.deleteNoteFile(note.filePath!);
      }
      await _syncService.notifyNoteChanged(note, isDelete: true);
    }
    await _dbService.emptyTrash();
    await refreshNotes();
  }

  /// Creates a new user folder
  Future<Folder> createFolder(String name, {String? parentId}) async {
    const uuid = Uuid();
    final now = DateTime.now();
    final folder = Folder(
      id: uuid.v4(),
      name: name.trim(),
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );
    await _dbService.upsertFolder(folder);
    await refreshFolders();
    return folder;
  }

  /// Renames a folder
  Future<void> renameFolder(String folderId, String newName) async {
    final folder = _folders.firstWhere((f) => f.id == folderId);
    final updated = folder.copyWith(name: newName.trim(), updatedAt: DateTime.now());
    await _dbService.upsertFolder(updated);
    await refreshFolders();
  }

  /// Deletes a folder
  Future<void> deleteFolder(String folderId) async {
    await _dbService.deleteFolder(folderId);
    if (_selectedFolderId == folderId) {
      _selectedFolderId = Folder.allNotesId;
    }
    await refreshFolders();
    await refreshNotes();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _syncService.removeListener(_onSyncChanged);
    _debounceSaveTimer?.cancel();
    super.dispose();
  }
}
