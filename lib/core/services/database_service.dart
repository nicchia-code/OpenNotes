import 'dart:convert';
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

    for (final cleanTag in targetTags) {
      whereClauses.add('(LOWER(tags) LIKE ? OR LOWER(content) LIKE ?)');
      whereArgs.add('%"$cleanTag"%');
      whereArgs.add('%#$cleanTag%');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(title) LIKE ? OR LOWER(content) LIKE ?)');
      whereArgs.add(q);
      whereArgs.add(q);
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    // Apple Notes sorts by pinned first (descending), then updated_at (descending)
    final results = await db.query(
      'notes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );

    return results.map((m) => Note.fromMap(m)).toList();
  }

  Future<void> moveToTrash(String noteId) async {
    await db.update(
      'notes',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<void> restoreFromTrash(String noteId) async {
    await db.update(
      'notes',
      {
        'is_deleted': 0,
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<void> permanentlyDeleteNote(String noteId) async {
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  Future<void> emptyTrash() async {
    await db.delete('notes', where: 'is_deleted = 1');
  }

  // --- FOLDERS CRUD ---

  Future<List<Folder>> getFolders() async {
    final results = await db.query('folders', orderBy: 'is_system DESC, name ASC');
    return results.map((m) => Folder.fromMap(m)).toList();
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
    final results = await db.query('notes', columns: ['tags', 'content'], where: 'is_deleted = 0');
    final tagCountMap = <String, int>{};

    for (final row in results) {
      final rawTags = row['tags'];
      final rawContent = row['content'] as String? ?? '';
      final noteTags = <String>{};

      if (rawTags is String) {
        try {
          final decoded = jsonDecode(rawTags);
          if (decoded is List) {
            for (final t in decoded) {
              final clean = t.toString().replaceAll('#', '').trim().toLowerCase();
              if (clean.isNotEmpty) noteTags.add(clean);
            }
          }
        } catch (_) {}
      } else if (rawTags is List) {
        for (final t in rawTags) {
          final clean = t.toString().replaceAll('#', '').trim().toLowerCase();
          if (clean.isNotEmpty) noteTags.add(clean);
        }
      }

      if (rawContent.isNotEmpty) {
        for (final t in Note.extractTagsFromContent(rawContent)) {
          final clean = t.replaceAll('#', '').trim().toLowerCase();
          if (clean.isNotEmpty) noteTags.add(clean);
        }
      }

      for (final cleanTag in noteTags) {
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
}
