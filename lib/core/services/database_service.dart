import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../models/tag_model.dart';

/// SQLite Database Service powering instant queries, FTS search,
/// pinned notes ordering, and offline sync queue.
class DatabaseService {
  Database? _db;

  Database get db {
    if (_db == null) {
      throw StateError('DatabaseService is not initialized. Call init() first.');
    }
    return _db!;
  }

  Future<void> init({bool inMemory = false}) async {
    // Initialize FFI for desktop (Linux, macOS, Windows) or inMemory test
    if (inMemory || (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS))) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String dbPath;
    if (inMemory) {
      dbPath = inMemoryDatabasePath;
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, 'opennotes.db');
    }

    _db = await openDatabase(
      dbPath,
      version: 1,
      singleInstance: !inMemory, // in-memory tests must not share one open database
      onCreate: (db, version) async {
        // Folders table
        await db.execute('''
          CREATE TABLE folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            parent_id TEXT,
            icon TEXT NOT NULL DEFAULT 'folder',
            is_system INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Insert default Apple Notes system folders
        final now = DateTime.now().toIso8601String();
        await db.rawInsert('''
          INSERT INTO folders (id, name, parent_id, icon, is_system, created_at, updated_at)
          VALUES ('notes', 'Note', NULL, 'folder', 1, '$now', '$now')
        ''');

        // Notes table
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            folder_id TEXT NOT NULL DEFAULT 'notes',
            tags TEXT NOT NULL DEFAULT '[]',
            is_pinned INTEGER NOT NULL DEFAULT 0,
            is_locked INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            deleted_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            synced_at TEXT,
            file_path TEXT
          )
        ''');

        // Sync queue table for offline-first sync
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            action TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Index for performance
        await db.execute('CREATE INDEX idx_notes_folder ON notes(folder_id)');
        await db.execute('CREATE INDEX idx_notes_pinned ON notes(is_pinned)');
        await db.execute('CREATE INDEX idx_notes_deleted ON notes(is_deleted)');
        await db.execute('CREATE INDEX idx_notes_updated ON notes(updated_at)');
      },
    );
  }

  // --- NOTES CRUD ---

  Future<void> upsertNote(Note note) async {
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Note?> getNoteById(String id) async {
    final results = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Note.fromMap(results.first);
  }

  /// Notes still recorded as written to [filePath], other than [exceptNoteId], newest first.
  Future<List<Note>> getNotesWrittenTo(String filePath, {String? exceptNoteId}) async {
    final results = await db.query(
      'notes',
      where: exceptNoteId == null ? 'file_path = ?' : 'file_path = ? AND id != ?',
      whereArgs: [filePath, ?exceptNoteId],
    );
    final notes = results.map(Note.fromMap).toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<List<Note>> getNotes({
    String? folderId,
    String? tag,
    List<String>? tags,
    bool? isDeleted = false,
    String? searchQuery,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (isDeleted != null) {
      whereClauses.add('is_deleted = ?');
      whereArgs.add(isDeleted ? 1 : 0);
    }

    if (folderId != null && folderId != Folder.allNotesId && folderId.isNotEmpty) {
      whereClauses.add('folder_id = ?');
      whereArgs.add(folderId);
    }

    final targetTags = <String>{};
    if (tag != null && tag.isNotEmpty) {
      targetTags.add(tag.replaceAll('#', '').trim().toLowerCase());
    }
    if (tags != null) {
      for (final t in tags) {
        final clean = t.replaceAll('#', '').trim().toLowerCase();
        if (clean.isNotEmpty) targetTags.add(clean);
      }
    }

    // Literal substring match, case-folded in Dart (SQLite LOWER/LIKE treat
    // `%`/`_` as wildcards and do not fold accented capitals). Filtered after
    // the query; ponytail: whole table loaded, push back to SQL if archives grow large.
    final q = searchQuery?.trim().toLowerCase() ?? '';

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    // Pinned first, then updated_at descending, compared as instants in Dart: stored dates
    // mix local times (no zone) and cloud UTC ones, so SQL text order is wrong.
    final results = await db.query(
      'notes',
      where: where,
      whereArgs: whereArgs,
    );

    final matching = results.where((m) {
      if (targetTags.isNotEmpty) {
        final noteTags = Note.fromMap(m).storedTags;
        if (!targetTags.every(noteTags.contains)) return false;
      }
      if (q.isEmpty) return true;
      final title = (m['title'] as String? ?? '').toLowerCase();
      final content = (m['content'] as String? ?? '').toLowerCase();
      return title.contains(q) || content.contains(q);
    });
    final notes = matching.map((m) => Note.fromMap(m)).toList();
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  /// Removes the note row. A note this device had synced takes its queued saves with it: they are discarded
  /// here, while the row still says the note was synced. A note never synced keeps its queued saves, which are sent.
  Future<void> permanentlyDeleteNote(String noteId) async {
    final rows = await db.query('notes', columns: ['synced_at'], where: 'id = ?', whereArgs: [noteId], limit: 1);
    if (rows.isNotEmpty && rows.single['synced_at'] != null) {
      await db.delete(
        'sync_queue',
        where: 'entity_type = ? AND entity_id = ? AND action = ?',
        whereArgs: ['note', noteId, 'upsert'],
      );
    }
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  // --- FOLDERS CRUD ---

  Future<List<Folder>> getFolders() async {
    final results = await db.query('folders', orderBy: 'is_system DESC, name ASC');
    return results.map((m) => Folder.fromMap(m)).toList();
  }

  Future<bool> folderExists(String folderId) async {
    final results = await db.query('folders', columns: ['id'], where: 'id = ?', whereArgs: [folderId], limit: 1);
    return results.isNotEmpty;
  }

  Future<void> upsertFolder(Folder folder) async {
    await db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFolder(String folderId) async {
    // Cannot delete system folders
    await db.delete('folders', where: 'id = ? AND is_system = 0', whereArgs: [folderId]);
    // Move contained notes to default 'notes' folder
    await db.update(
      'notes',
      {'folder_id': Folder.defaultNotesId},
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  // --- COUNTS & TAGS ---

  Future<int> getNotesCount({String? folderId, bool isDeleted = false}) async {
    final whereClauses = ['is_deleted = ?'];
    final whereArgs = <Object>[isDeleted ? 1 : 0];

    if (folderId != null && folderId != Folder.allNotesId) {
      whereClauses.add('folder_id = ?');
      whereArgs.add(folderId);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE ${whereClauses.join(' AND ')}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTrashCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notes WHERE is_deleted = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Tag>> getAllTags() async {
    final results = await db.query('notes', where: 'is_deleted = 0');
    final tagCountMap = <String, int>{};

    for (final note in results.map(Note.fromMap)) {
      for (final cleanTag in note.storedTags) {
        tagCountMap[cleanTag] = (tagCountMap[cleanTag] ?? 0) + 1;
      }
    }

    final list = tagCountMap.entries
        .map((e) => Tag(name: e.key, count: e.value))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // --- SYNC QUEUE OPERATIONS ---

  Future<void> queueSyncAction({
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
  }) async {
    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  Future<void> removeSyncAction(int id) async {
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeSyncActionsFor(String entityType, String entityId, {String? action}) async {
    await db.delete(
      'sync_queue',
      where: action == null
          ? 'entity_type = ? AND entity_id = ?'
          : 'entity_type = ? AND entity_id = ? AND action = ?',
      whereArgs: [entityType, entityId, ?action],
    );
  }

  /// When the queued delete of this entity was made; null when no delete waits to be sent.
  Future<DateTime?> pendingDeleteQueuedAt(String entityType, String entityId) async {
    final rows = await db.query(
      'sync_queue',
      columns: ['created_at'],
      where: 'entity_type = ? AND entity_id = ? AND action = ?',
      whereArgs: [entityType, entityId, 'delete'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.single['created_at'] as String);
  }

  /// When the queued delete of this entity was made; null when no delete waits to be sent.
  Future<DateTime?> getPendingSyncDeleteTime(String entityType, String entityId) async {
    final rows = await db.query(
      'sync_queue',
      columns: ['created_at'],
      where: 'entity_type = ? AND entity_id = ? AND action = ?',
      whereArgs: [entityType, entityId, 'delete'],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.first['created_at'] as String);
  }

  /// Removes the queued deletes of this entity; other queued changes stay.
  Future<void> removePendingSyncDeletes(String entityType, String entityId) async {
    await db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ? AND action = ?',
      whereArgs: [entityType, entityId, 'delete'],
    );
  }

  /// Whether a queued change of this entity waits to be sent; any action when [action] is null.
  Future<bool> hasPendingSyncAction({
    required String entityType,
    required String entityId,
    String? action,
  }) async {
    final rows = await db.query(
      'sync_queue',
      columns: ['id'],
      where: action == null
          ? 'entity_type = ? AND entity_id = ?'
          : 'entity_type = ? AND entity_id = ? AND action = ?',
      whereArgs: [entityType, entityId, ?action],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
