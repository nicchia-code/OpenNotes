import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../models/tag_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/security_service.dart';
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
  // Name of the open user folder when last seen; kept if the folder disappears.
  String? _selectedFolderName;
  Set<String> _selectedTags = {};
  String? _selectedNoteId;
  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _debounceSaveTimer;
  // Version waiting to be written; kept after a failed write for the next retry.
  _PendingContentSave? _pendingContent;
  bool _contentSaveFailed = false;
  // Versions being written now; the list keeps showing them until their writes end.
  final List<_PendingContentSave> _writingContents = [];
  // Content writes running now; a state change waits for them before it reads the note.
  final List<Future<void>> _contentWrites = [];
  // Hands over the text the open editor still holds; set while an editor is shown.
  VoidCallback? _deliverEditorText;
  Map<String, int> _folderCounts = {};
  int _trashCount = 0;
  // Neighbours of a note being moved to trash, in fallback order; used only while that move runs.
  List<String> _trashFallbackIds = const [];
  // Notes whose queued change is set aside by the sync; shown with a badge in the lists.
  Set<String> _setAsideNoteIds = {};
  bool _disposed = false;
  StreamSubscription<RemoteChange>? _remoteSubscription;
  final SecurityService? _securityService;
  // Emits once for each note action cancelled because its vault file could not be written or removed.
  final _actionFailures = StreamController<void>.broadcast();

  NotesProvider({
    required DatabaseService dbService,
    required VaultService vaultService,
    required SyncService syncService,
    SecurityService? securityService,
  }) : _dbService = dbService,
       _vaultService = vaultService,
       _syncService = syncService,
       _securityService = securityService {
    _syncService.addListener(_onSyncChanged);
    _securityService?.addListener(_onSecurityChanged);
    _remoteSubscription = _syncService.remoteChanges.listen((change) {
      if (_disposed) return;
      // A cloud version that protects a note hides it: the edit still waiting is handed over first, then
      // the note is hidden, and the edit is written at once instead of after the 400 ms wait.
      if (change is CloudNoteApplied && change.isLocked) {
        deliverWaitingEdits();
        _securityService?.relockNote(change.noteId);
        unawaited(flushPendingContent());
      }
      _reloadLists();
    });
  }

  void _onSyncChanged() {
    if (_disposed) return;
    if (!_syncService.isSyncing) _reloadLists();
  }

  /// Session unlocks change which tags are visible: the tag list is reloaded with the notes.
  void _onSecurityChanged() {
    if (_disposed) return;
    unawaited(refreshTags());
    refreshNotes();
  }

  /// Reloads folders, tags and notes in this order: notes read the folder selection that the
  /// folder reload may correct. Remote changes call it even during a full sync.
  Future<void> _reloadLists() async {
    await refreshFolders();
    await refreshTags();
    await refreshNotes();
  }

  List<Folder> get folders => _folders;
  List<Note> get notes => _notes;
  List<Tag> get tags => _tags;
  bool get contentSaveFailed => _contentSaveFailed;
  /// Whether a version of [noteId] delivered by the editor is still waiting to be written or being written.
  bool hasWaitingContent(String noteId) =>
      _pendingContent?.noteId == noteId ||
      _writingContents.any((w) => w.noteId == noteId);
  /// One event per note action cancelled because its vault file could not be written or removed.
  Stream<void> get actionFailures => _actionFailures.stream;
  String get selectedFolderId => _selectedFolderId;
  /// Name of the open user folder, kept while the folder is missing from the list.
  String? get selectedFolderName => _selectedFolderName;
  String? get selectedTag =>
      _selectedTags.isNotEmpty ? _selectedTags.first : null;
  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);
  bool isTagSelected(String tag) =>
      _selectedTags.contains(tag.replaceAll('#', '').trim().toLowerCase());
  String? get selectedNoteId => _selectedNoteId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  int getNoteCountForFolder(String folderId) => _folderCounts[folderId] ?? 0;

  /// Current stored version of a note, or null if it no longer exists.
  Future<Note?> fetchNote(String noteId) => _dbService.getNoteById(noteId);
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
    _rememberSelectedFolderName();
    notifyListeners();
    refreshCounts();
  }

  /// Refreshes tag list from database
  Future<void> refreshTags() async {
    _tags = await _dbService.getAllTags(isUnlocked: _securityService?.isNoteUnlocked);
    notifyListeners();
  }

  /// Refreshes folder note counts and trash count
  Future<void> refreshCounts() async {
    final counts = <String, int>{};
    counts[Folder.allNotesId] = await _dbService.getNotesCount(
      isDeleted: false,
    );
    counts[Folder.defaultNotesId] = await _dbService.getNotesCount(
      folderId: Folder.defaultNotesId,
      isDeleted: false,
    );
    for (final folder in _folders) {
      counts[folder.id] = await _dbService.getNotesCount(
        folderId: folder.id,
        isDeleted: false,
      );
    }
    _folderCounts = counts;
    _trashCount = await _dbService.getTrashCount();
    _setAsideNoteIds = await _dbService.getSetAsideNoteIds();
    notifyListeners();
  }

  /// Refreshes notes list based on current filters
  Future<void> refreshNotes() async {
    final isDeleted = isTrashSelected;
    // When filtering by tag, search across all folders
    final folderId = _selectedTags.isNotEmpty
        ? null
        : (isTrashSelected
              ? null
              : (_selectedFolderId.isEmpty ? null : _selectedFolderId));

    _notes = await _dbService.getNotes(
      folderId: folderId,
      tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
      isDeleted: isDeleted,
      searchQuery: _searchQuery,
      isUnlocked: _securityService?.isNoteUnlocked,
    );
    _showWaitingContent();

    // If currently selected note is no longer in the list, select the trash fallback, first or null
    if (_selectedNoteId != null &&
        !_notes.any((n) => n.id == _selectedNoteId)) {
      _selectedNoteId = _notes.isNotEmpty ? _notes.first.id : null;
      for (final id in _trashFallbackIds) {
        if (_notes.any((n) => n.id == id)) {
          _selectedNoteId = id;
          break;
        }
      }
    } else if (_selectedNoteId == null && _notes.isNotEmpty) {
      _selectedNoteId = _notes.first.id;
    }

    notifyListeners();
    refreshCounts();
  }

  /// Whether the queued change of [noteId] is set aside, so the note is shown with a badge.
  bool isNoteSetAside(String noteId) => _setAsideNoteIds.contains(noteId);

  /// Selects a folder and filters notes
  void selectFolder(String folderId) {
    _selectedFolderId = folderId;
    _selectedFolderName = null;
    _rememberSelectedFolderName();
    _selectedTags.clear();
    refreshNotes();
  }

  /// Keeps the name of the open user folder, so the view keeps its title when the folder is deleted elsewhere.
  void _rememberSelectedFolderName() {
    final match = _folders.where((f) => f.id == _selectedFolderId);
    if (match.isNotEmpty) _selectedFolderName = match.first.name;
  }

  /// Selects a tag and filters notes across all folders (toggles off if tapped again, or multi-selects).
  /// With `toggleOff: false`, tapping the only selected tag keeps it selected instead of clearing it.
  void selectTag(String? tag, {bool multiSelect = false, bool toggleOff = true}) {
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
        if (toggleOff && _selectedTags.length == 1 && _selectedTags.contains(clean)) {
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

  /// True when the open view is a user folder that is no longer in the folder list
  /// (deleted, for example, from another device). The view stays open and empty.
  bool get _isSelectedFolderGone =>
      _selectedFolderId != Folder.allNotesId &&
      _selectedFolderId != Folder.trashId &&
      _selectedFolderId != Folder.defaultNotesId &&
      _selectedFolderId.isNotEmpty &&
      !_folders.any((f) => f.id == _selectedFolderId);

  /// Folder of a duplicate: the original's folder, or Notes when that folder no longer exists.
  Future<String> _folderIdForCopy(String originalFolderId) async {
    if (originalFolderId == Folder.defaultNotesId) return originalFolderId;
    final folder = await _dbService.getFolderById(originalFolderId);
    return folder != null ? originalFolderId : Folder.defaultNotesId;
  }

  /// Creates a new Note in the current folder (or default notes folder)
  /// If creating inside a tag view (or multiple tags), appends those tags at the top of the note.
  Future<Note?> createNote({
    String initialTitle = 'Nuova nota',
    String initialContent = '',
  }) async {
    const uuid = Uuid();
    final now = DateTime.now();

    final folderGone = _isSelectedFolderGone;
    String targetFolderId = _selectedFolderId;
    if (targetFolderId == Folder.allNotesId ||
        targetFolderId == Folder.trashId ||
        targetFolderId.isEmpty ||
        folderGone) {
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
      tags: {...noteTags, ...Note.extractTagsFromContent(content)}.toList(),
      createdAt: now,
      updatedAt: now,
      cachedSnippet: Note.extractSnippet(content),
    );

    // Vault file first: a note whose file cannot be written is not created
    final saved = await _writeToVault(newNote);
    if (saved == null) return null;
    await _dbService.upsertNote(saved);
    // Queue sync
    await _syncService.notifyNoteChanged(saved);

    // A new note must be visible in the list it is selected in: drop the search.
    // When the open folder is gone, the view moves to Notes, where the new note lives.
    _searchQuery = '';
    if (folderGone) {
      _selectedFolderId = Folder.defaultNotesId;
      _selectedFolderName = null;
    }
    _selectedNoteId = newNote.id;
    await refreshNotes();
    await refreshTags();

    return newNote;
  }

  /// Updates note content with debouncing to prevent excessive disk/DB writes
  void updateNoteContent(String noteId, String newContent) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    // Only a note in the loaded list takes an edit: any other edit is neither waited for nor written.
    if (index == -1) return;

    final pending = _PendingContentSave(
      noteId: noteId,
      title: Note.extractTitle(newContent),
      content: newContent,
      tags: Note.extractTagsFromContent(newContent),
      updatedAt: DateTime.now(),
    );
    // Optimistic update of the list; the save below reads the stored note anyway.
    _notes[index] = _withContent(_notes[index], pending);
    notifyListeners();

    // One shared wait: a version of another note still waiting is written now, not replaced
    if (_pendingContent != null && _pendingContent!.noteId != noteId) {
      unawaited(flushPendingContent());
    }
    _pendingContent = pending;
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 400), flushPendingContent);
  }

  /// Writes the waiting content version to the DB and its Markdown file, then
  /// notifies sync. If a write fails, the version stays waiting (unless a newer
  /// one has replaced it) and [contentSaveFailed] turns true. It is retried at
  /// the next delivery or when the app leaves the foreground.
  Future<void> flushPendingContent() async {
    _debounceSaveTimer?.cancel();
    final pending = _pendingContent;
    if (pending == null) return;
    _pendingContent = null;
    _writingContents.add(pending);
    final write = _writeContent(pending);
    _contentWrites.add(write);
    final saved = await write;
    _contentWrites.remove(write);
    if (!saved) return;
    _setContentSaveFailed(false);
    await refreshNotes();
    await refreshTags();
  }

  /// Writes [pending] to the DB and its Markdown file, then notifies sync. Returns false if
  /// the write failed: the version waits again and [contentSaveFailed] turns true.
  Future<bool> _writeContent(_PendingContentSave pending) async {
    try {
      final stored = await _dbService.getNoteById(pending.noteId);
      if (stored != null) {
        final path = await _vaultService.saveNote(_withContent(stored, pending));
        // Re-read after the file write: pin, folder, trash and lock may have changed meanwhile.
        final latest = await _dbService.getNoteById(pending.noteId);
        if (latest != null) {
          final savedContent = _withContent(latest, pending).copyWith(filePath: path);
          await _dbService.upsertNote(savedContent);
          await _syncService.notifyNoteChanged(savedContent);
        }
      }
      return true;
    } catch (error) {
      debugPrint('Note content save failed: $error');
      final discarded = _pendingContent != null;
      _pendingContent ??= pending;
      _setContentSaveFailed(true);
      if (discarded) await _restoreStoredContent(pending);
      return false;
    } finally {
      _writingContents.remove(pending);
    }
  }

  /// Run first by every note state change (pin, trash, restore, move): hands over the editor
  /// text, writes the waiting version and waits for the writes already running, so the change
  /// applies to the newest stored version instead of an older one.
  Future<void> _settleContent() async {
    deliverWaitingEdits();
    await flushPendingContent();
    await Future.wait(List.of(_contentWrites));
  }

  /// [note] with the content fields of [pending]; pin, folder, trash and lock stay as they are.
  Note _withContent(Note note, _PendingContentSave pending) => note.copyWith(
    title: pending.title,
    content: pending.content,
    tags: pending.tags,
    updatedAt: pending.updatedAt,
  );

  /// The list shows the newest versions the editor delivered, even while they are being written.
  void _showWaitingContent() {
    for (final waiting in [..._writingContents, _pendingContent]) {
      if (waiting == null) continue;
      final index = _notes.indexWhere((n) => n.id == waiting.noteId);
      if (index != -1) _notes[index] = _withContent(_notes[index], waiting);
    }
  }

  /// Puts back the stored version of the note whose waiting version was discarded, then
  /// shows again the versions still waiting.
  Future<void> _restoreStoredContent(_PendingContentSave discarded) async {
    _writingContents.remove(discarded);
    final stored = await _dbService.getNoteById(discarded.noteId);
    final index = _notes.indexWhere((n) => n.id == discarded.noteId);
    if (stored != null && index != -1) _notes[index] = stored;
    _showWaitingContent();
    notifyListeners();
  }

  void _setContentSaveFailed(bool failed) {
    if (_contentSaveFailed == failed) return;
    _contentSaveFailed = failed;
    notifyListeners();
  }

  /// Writes [note] to its vault file and returns it with that file path, or null if the
  /// write fails: the action then stops before the database changes, and the user is warned.
  Future<Note?> _writeToVault(Note note) async {
    try {
      final path = await _vaultService.saveNote(note);
      return note.copyWith(filePath: path);
    } catch (error) {
      _cancelAction(error);
      return null;
    }
  }

  /// Tells the user, through [actionFailures], that a note action was cancelled.
  void _cancelAction(Object error) {
    debugPrint('Note action cancelled: $error');
    if (!_disposed) _actionFailures.add(null);
  }

  /// The open editor registers [deliver] so text it still holds can be handed
  /// over before the notes are read (export). Pair with [detachEditorDelivery].
  void attachEditorDelivery(VoidCallback deliver) {
    _deliverEditorText = deliver;
  }

  void detachEditorDelivery(VoidCallback deliver) {
    if (_deliverEditorText == deliver) _deliverEditorText = null;
  }

  /// Hands over the text waiting in the open editor, so [notes] holds the
  /// version shown on screen.
  void deliverWaitingEdits() => _deliverEditorText?.call();

  /// The app is leaving the foreground or closing: the open editor hands over its
  /// text, and the waiting version is written now instead of after the 400 ms wait.
  Future<void> flushOnAppLeavingForeground() async {
    deliverWaitingEdits();
    await flushPendingContent();
  }

  /// Toggles pinned state of a note
  Future<void> togglePin(String noteId) async {
    await _settleContent();
    final note = await _dbService.getNoteById(noteId);
    if (note == null) return;

    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );

    final savedPin = await _writeToVault(updated);
    if (savedPin == null) return;
    await _dbService.upsertNote(savedPin);
    await _syncService.notifyNoteChanged(savedPin);
    await refreshNotes();
  }

  /// Toggles locked state of a note, only while the stored note is still in [wasLocked] state: the caller decided
  /// on that state (and any PIN) before, so a change made meanwhile is never flipped blindly. Returns false and writes
  /// nothing when the state differs or the write fails.
  Future<bool> toggleLock(String noteId, {required bool wasLocked}) async {
    await _settleContent();
    final note = await _dbService.getNoteById(noteId);
    if (note == null || note.isLocked != wasLocked) return false;

    final updated = note.copyWith(
      isLocked: !note.isLocked,
      updatedAt: DateTime.now(),
    );

    final savedLock = await _writeToVault(updated);
    if (savedLock == null) return false;
    await _dbService.upsertNote(savedLock);
    await _syncService.notifyNoteChanged(savedLock);
    await refreshNotes();
    await refreshTags();
    return true;
  }

  /// Moves note to trash. The file is written first: if it cannot be written, the note stays where it was.
  /// While the move runs, for a note leaving the view the next note (else the previous one) is the selection fallback for any reload.
  Future<bool> moveToTrash(String noteId) async {
    await _settleContent();
    final note = await _dbService.getNoteById(noteId);
    if (note == null) return false;
    // A note already in the trash stays listed: only its trash date is renewed and the selection stays.
    final leavesView = !note.isDeleted;
    final oldIndex = _notes.indexWhere((n) => n.id == noteId);
    final nextNoteId = leavesView && oldIndex >= 0 && oldIndex + 1 < _notes.length ? _notes[oldIndex + 1].id : null;
    final previousNoteId = leavesView && oldIndex > 0 ? _notes[oldIndex - 1].id : null;
    // Select the neighbour before the write, so the list never shows another note first.
    final previousSelection = _selectedNoteId;
    if (leavesView && oldIndex >= 0) {
      _selectedNoteId = nextNoteId ?? previousNoteId;
      _trashFallbackIds = [?nextNoteId, ?previousNoteId];
    }
    try {
      final now = DateTime.now();
      final savedTrash = await _writeToVault(note.copyWith(isDeleted: true, deletedAt: now, updatedAt: now));
      if (savedTrash == null) {
        _selectedNoteId = previousSelection;
        notifyListeners();
        return false;
      }
      await _dbService.upsertNote(savedTrash);
      await _syncService.notifyNoteChanged(savedTrash);
      await refreshNotes();
      await refreshTags();
      return true;
    } finally {
      _trashFallbackIds = const [];
    }
  }

  /// Restores a trashed note to its original folder. The file is written first.
  Future<void> restoreFromTrash(String noteId) async {
    await _settleContent();
    final note = await _dbService.getNoteById(noteId);
    if (note == null) return;
    final savedRestore = await _writeToVault(note.copyWith(
      isDeleted: false,
      clearDeletedAt: true,
      updatedAt: DateTime.now(),
    ));
    if (savedRestore == null) return;
    await _dbService.upsertNote(savedRestore);
    await _syncService.notifyNoteChanged(savedRestore);
    await refreshNotes();
    await refreshTags();
  }

  /// Restores a trashed note directly into a destination folder, or moves an
  /// active note there.
  Future<void> moveNoteToFolder(String noteId, String folderId) async {
    await _settleContent();
    final note = await _dbService.getNoteById(noteId);
    if (note == null) return;
    final updated = note.copyWith(
      clearDeletedAt: true,
      folderId: folderId,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );
    final savedMove = await _writeToVault(updated);
    if (savedMove == null) return;
    await _dbService.upsertNote(savedMove);
    await _syncService.notifyNoteChanged(savedMove);
    await refreshNotes();
    await refreshTags();
  }

  /// Duplicates an active note and selects the new copy.
  Future<Note?> duplicateNote(String noteId) async {
    // Copy what is on screen: hand over the waiting edit and wait for a write already running.
    await _settleContent();
    final note = await _dbService.getNoteById(noteId);
    if (note == null || note.isDeleted) return null;
    const uuid = Uuid();
    final now = DateTime.now();
    final copyTitle = '${note.title} (copia)';
    String content = note.content;
    final blocks = note.readBlocks();
    if (blocks != null) {
      final titleIndex = blocks.indexWhere(
        (block) => block is Map && block['type'] == 'title',
      );
      if (titleIndex >= 0) {
        (blocks[titleIndex] as Map<String, dynamic>)['text'] = copyTitle;
      } else {
        blocks.insert(0, {
          'id': uuid.v4(),
          'type': 'title',
          'text': copyTitle,
          'spans': <dynamic>[],
        });
      }
      content = jsonEncode(blocks);
    } else if (content.trimLeft().startsWith('# ')) {
      content = content.replaceFirstMapped(
        RegExp(r'^([ \t\r\n]*)#[ \t]+[^\n]*'),
        (match) => '${match.group(1)}# $copyTitle',
      );
    } else {
      content = '# $copyTitle\n$content';
    }
    final copy = Note(
      id: uuid.v4(),
      title: copyTitle,
      content: content,
      folderId: await _folderIdForCopy(note.folderId),
      tags: List<String>.from(note.tags),
      isLocked: note.isLocked,
      createdAt: now,
      updatedAt: now,
      cachedSnippet: Note.extractSnippet(content, isLocked: note.isLocked),
    );
    final savedCopy = await _writeToVault(copy);
    if (savedCopy == null) return null;
    await _dbService.upsertNote(savedCopy);
    await _syncService.notifyNoteChanged(savedCopy);
    // The copy must be listed in the view it is selected in: drop the search, as createNote does.
    _searchQuery = '';
    _selectedNoteId = copy.id;
    await refreshNotes();
    await refreshTags();
    notifyListeners();
    return copy;
  }

  /// Permanently deletes [notes] one by one: the Markdown file (unless another note still
  /// uses it), then the cloud deletion, then the local row. If a file cannot be removed the
  /// note stays in the trash, nothing is queued for the cloud, and the notes after it wait.
  Future<bool> _purgeNotes(List<Note> notes) async {
    for (final note in notes) {
      try {
        await _vaultService.deleteNoteFileIfUnused(_dbService, note.filePath, exceptNoteId: note.id);
      } catch (error) {
        _cancelAction(error);
        return false;
      }
      await _syncService.notifyNoteChanged(note, isDelete: true);
      await _dbService.deleteNoteRow(note.id);
    }
    return true;
  }

  /// Permanently deletes note. Returns false when its file could not be removed.
  Future<bool> permanentlyDeleteNote(String noteId) async {
    final note = await _dbService.getNoteById(noteId);
    final deleted = note != null && await _purgeNotes([note]);
    await refreshNotes();
    return deleted;
  }

  /// Empties trash completely
  Future<void> emptyTrash() async {
    await _purgeNotes(await _dbService.getNotes(isDeleted: true));
    await refreshNotes();
  }

  /// Whether any trashed note is protected, including those hidden by the active filter.
  Future<bool> trashHasProtectedNote() async =>
      (await _dbService.getNotes(isDeleted: true)).any((note) => note.isLocked);

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
    await _syncService.notifyFolderChanged(folder);
    await refreshFolders();
    await refreshNotes();
    return folder;
  }

  /// Renames a folder
  Future<void> renameFolder(String folderId, String newName) async {
    final folder = _folders.firstWhere((f) => f.id == folderId);
    final updated = folder.copyWith(
      name: newName.trim(),
      updatedAt: DateTime.now(),
    );
    await _dbService.upsertFolder(updated);
    await _syncService.notifyFolderChanged(updated);
    await refreshFolders();
    await refreshNotes();
  }

  /// Deletes a folder
  Future<void> deleteFolder(String folderId) async {
    // The notes are read from the newest version of their content, so their vault copies are written from it.
    await _settleContent();
    final folder = _folders.where((f) => f.id == folderId).firstOrNull;
    // The notes moved to Notes (trashed ones too) are queued with the folder delete.
    final movedNotes = folder != null && !folder.isSystem
        ? await _dbService.getNotes(folderId: folderId, isDeleted: null)
        : const <Note>[];
    // Their vault copies name Notes before the folder goes; a failed write cancels the delete, as any other note action.
    try {
      await _vaultService.rewriteMovedNotes(_dbService, [
        for (final note in movedNotes) note.copyWith(folderId: Folder.defaultNotesId),
      ]);
    } catch (error) {
      _cancelAction(error);
      return;
    }
    if (folder != null && !folder.isSystem) {
      // Deleted here: the open view moves to All notes. A delete received from the cloud never reaches this code.
      if (_selectedFolderId == folderId) _selectedFolderId = Folder.allNotesId;
      for (final note in movedNotes) {
        await _syncService.notifyNoteChanged(note.copyWith(folderId: Folder.defaultNotesId));
      }
      // Queued while the folder row still exists: the queued delete takes the row's cloud revision as its base.
      await _syncService.notifyFolderChanged(folder, isDelete: true);
    }
    await _dbService.deleteFolder(folderId);
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
    _securityService?.removeListener(_onSecurityChanged);
    _remoteSubscription?.cancel();
    _actionFailures.close();
    // Write the waiting version now: cancelling the wait would drop it.
    unawaited(flushPendingContent());
    super.dispose();
  }
}

/// A note content version waiting to be written.
class _PendingContentSave {
  const _PendingContentSave({
    required this.noteId,
    required this.title,
    required this.content,
    required this.tags,
    required this.updatedAt,
  });

  final String noteId;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime updatedAt;
}
