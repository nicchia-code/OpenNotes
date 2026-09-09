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
  String? _selectedTag;
  String? _selectedNoteId;
  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _debounceSaveTimer;

  NotesProvider({
    required DatabaseService dbService,
    required VaultService vaultService,
    required SyncService syncService,
  })  : _dbService = dbService,
        _vaultService = vaultService,
        _syncService = syncService;

  List<Folder> get folders => _folders;
  List<Note> get notes => _notes;
  List<Tag> get tags => _tags;
  String get selectedFolderId => _selectedFolderId;
  String? get selectedTag => _selectedTag;
  String? get selectedNoteId => _selectedNoteId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

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
  }

  /// Refreshes tag list from database
  Future<void> refreshTags() async {
    _tags = await _dbService.getAllTags();
    notifyListeners();
  }

  /// Refreshes notes list based on current filters
  Future<void> refreshNotes() async {
    final isDeleted = isTrashSelected;
    // When filtering by tag, search across all folders
    final folderId = (_selectedTag != null && _selectedTag!.isNotEmpty)
        ? null
        : (isTrashSelected ? null : (_selectedFolderId.isEmpty ? null : _selectedFolderId));

    _notes = await _dbService.getNotes(
      folderId: folderId,
      tag: _selectedTag,
      isDeleted: isDeleted,
      searchQuery: _searchQuery,
    );

    // If currently selected note is no longer in the list, select first or null
    if (_selectedNoteId != null && !_notes.any((n) => n.id == _selectedNoteId)) {
      _selectedNoteId = _notes.isNotEmpty ? _notes.first.id : null;
    }

    notifyListeners();
  }

  /// Selects a folder and filters notes
  void selectFolder(String folderId) {
    _selectedFolderId = folderId;
    _selectedTag = null;
    refreshNotes();
  }

  /// Selects a tag and filters notes across all folders (toggles off if tapped again)
  void selectTag(String? tag) {
    final clean = tag?.replaceAll('#', '').trim().toLowerCase();
    if (_selectedTag == clean || clean == null || clean.isEmpty) {
      _selectedTag = null;
    } else {
      _selectedTag = clean;
    }
    _selectedFolderId = Folder.allNotesId;
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

    final newNote = Note(
      id: uuid.v4(),
      title: initialTitle,
      content: initialContent,
      folderId: targetFolderId,
      createdAt: now,
      updatedAt: now,
      cachedSnippet: Note.extractSnippet(initialContent),
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
  void dispose() {
    _debounceSaveTimer?.cancel();
    super.dispose();
  }
}
