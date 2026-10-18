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

  Future<void> init({
    bool inMemory = false,
    @visibleForTesting String? databasePath,
  }) async {
    // Initialize FFI for desktop (Linux, macOS, Windows) or inMemory test
    if (inMemory || (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS))) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String dbPath;
    if (inMemory) {
      dbPath = inMemoryDatabasePath;
    } else if (databasePath != null) {
      dbPath = databasePath;
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, 'opennotes.db');
    }

    _db = await openDatabase(
      dbPath,
      version: 2,
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
            updated_at TEXT NOT NULL,
            cloud_revision INTEGER
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
            cloud_revision INTEGER,
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
            created_at TEXT NOT NULL,
            base_revision INTEGER,
            attempts INTEGER NOT NULL DEFAULT 0,
            set_aside INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
        await db.execute('CREATE UNIQUE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id)');

        // Attachments already present in the cloud
        await db.execute('CREATE TABLE uploaded_attachments (path TEXT PRIMARY KEY)');

        // Index for performance
        await db.execute('CREATE INDEX idx_notes_folder ON notes(folder_id)');
        await db.execute('CREATE INDEX idx_notes_pinned ON notes(is_pinned)');
        await db.execute('CREATE INDEX idx_notes_deleted ON notes(is_deleted)');
        await db.execute('CREATE INDEX idx_notes_updated ON notes(updated_at)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _upgradeToV2(db);
      },
    );
  }

  /// Version 2 adds the cloud revisions, the queue retry state and the uploaded attachments. The queue keeps one item
  /// per entity: the newest change takes the position of the oldest queued item of that entity.
  static Future<void> _upgradeToV2(Database db) async {
    await db.execute('ALTER TABLE folders ADD COLUMN cloud_revision INTEGER');
    await db.execute('ALTER TABLE notes ADD COLUMN cloud_revision INTEGER');
    await db.execute('ALTER TABLE sync_queue ADD COLUMN base_revision INTEGER');
    await db.execute('ALTER TABLE sync_queue ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE sync_queue ADD COLUMN set_aside INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE sync_queue ADD COLUMN last_error TEXT');
    await db.execute('''
      UPDATE sync_queue SET
        action = (SELECT newest.action FROM sync_queue newest
          WHERE newest.entity_type = sync_queue.entity_type AND newest.entity_id = sync_queue.entity_id
          ORDER BY newest.id DESC LIMIT 1),
        payload = (SELECT newest.payload FROM sync_queue newest
          WHERE newest.entity_type = sync_queue.entity_type AND newest.entity_id = sync_queue.entity_id
          ORDER BY newest.id DESC LIMIT 1),
        created_at = (SELECT newest.created_at FROM sync_queue newest
          WHERE newest.entity_type = sync_queue.entity_type AND newest.entity_id = sync_queue.entity_id
          ORDER BY newest.id DESC LIMIT 1)
      WHERE id IN (SELECT MIN(id) FROM sync_queue GROUP BY entity_type, entity_id)
    ''');
    await db.execute(
      'DELETE FROM sync_queue WHERE id NOT IN (SELECT MIN(id) FROM sync_queue GROUP BY entity_type, entity_id)',
    );
    await db.execute('CREATE UNIQUE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id)');
    await db.execute('CREATE TABLE uploaded_attachments (path TEXT PRIMARY KEY)');
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

  /// Notes that still record a written file, other than [exceptNoteId], newest first.
  /// The paths are not compared here: whether two of them name the same file is decided
  /// on disk by the caller, because case-insensitive file systems map different spellings
  /// of a path to one file.
  Future<List<Note>> getNotesWithWrittenFile({String? exceptNoteId}) async {
    final results = await db.query(
      'notes',
      where: exceptNoteId == null ? 'file_path IS NOT NULL' : 'file_path IS NOT NULL AND id != ?',
      whereArgs: [?exceptNoteId],
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
    /// Tells whether a protected note is unlocked for this session. A protected note still locked
    /// is searched by title and tags only, so its hidden text never shows up.
    bool Function(String noteId)? isUnlocked,
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
      if (title.contains(q)) return true;
      final note = Note.fromMap(m);
      // A protected note still locked keeps its text hidden: only its title and tags are searched.
      if (note.isLocked && !(isUnlocked?.call(note.id) ?? false)) {
        return note.storedTags.any((tag) => tag.contains(q));
      }
      final content = (m['content'] as String? ?? '').toLowerCase();
      return content.contains(q);
    });
    final notes = matching.map((m) => Note.fromMap(m)).toList();
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  /// Removes the note row only. Its queued saves stay in the queue and are sent before the queued delete.
  Future<void> deleteNoteRow(String noteId) async {
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  /// Removes the note row of a note removed by a sync run (discarded welcome note, note deleted
  /// in the cloud). A note this device had synced takes its queued saves with it: they are discarded
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
    await deleteNoteRow(noteId);
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

  Future<Folder?> getFolderById(String folderId) async {
    final results = await db.query('folders', where: 'id = ?', whereArgs: [folderId], limit: 1);
    return results.isEmpty ? null : Folder.fromMap(results.first);
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

  /// The tag list of the notes outside the trash: each note's stored tags plus the #tags written in its content, counted
  /// once per note. A protected note still locked keeps its text hidden, so only its stored tags count.
  Future<List<Tag>> getAllTags({bool Function(String noteId)? isUnlocked}) async {
    final results = await db.query('notes', where: 'is_deleted = 0');
    final tagCountMap = <String, int>{};

    for (final note in results.map(Note.fromMap)) {
      final hidden = note.isLocked && !(isUnlocked?.call(note.id) ?? false);
      final noteTags = {...note.storedTags, if (!hidden) ...Note.extractTagsFromContent(note.content)};
      for (final cleanTag in noteTags) {
        tagCountMap[cleanTag] = (tagCountMap[cleanTag] ?? 0) + 1;
      }
    }

    final list = tagCountMap.entries
        .map((e) => Tag(name: e.key, count: e.value))
        .toList();
    list.sort((a, b) => Note.compareTags(a.name, b.name));
    return list;
  }

  // --- SYNC QUEUE OPERATIONS ---

  /// Queues a change of a note or folder. An entity has at most one queued item: a new change takes its place, keeping
  /// its position in the queue and its base revision (the cloud revision the device last saw of it), with the new entry
  /// time, no rejections and not set aside. A delete takes the place of a queued save the same way.
  Future<void> queueSyncAction({
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'sync_queue',
        columns: ['id'],
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [entityType, entityId],
        orderBy: 'id ASC',
      );
      if (existing.isEmpty) {
        final owner = await txn.query(
          entityType == 'folder' ? 'folders' : 'notes',
          columns: ['cloud_revision'],
          where: 'id = ?',
          whereArgs: [entityId],
          limit: 1,
        );
        await txn.insert('sync_queue', {
          'entity_type': entityType,
          'entity_id': entityId,
          'action': action,
          'payload': payload,
          'created_at': now,
          'base_revision': owner.isEmpty ? null : owner.single['cloud_revision'],
        });
        return;
      }
      final keptId = existing.first['id'] as int;
      await txn.update(
        'sync_queue',
        {
          'action': action,
          'payload': payload,
          'created_at': now,
          'attempts': 0,
          'set_aside': 0,
          'last_error': null,
        },
        where: 'id = ?',
        whereArgs: [keptId],
      );
      for (final row in existing.skip(1)) {
        await txn.delete('sync_queue', where: 'id = ?', whereArgs: [row['id']]);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  /// Removes a queued item once it is sent. Removed only while it still is the item that was sent: a change queued
  /// while its upload was in flight replaced it and stays queued.
  Future<void> removeSyncActionIfUnchanged(Map<String, dynamic> sent) async {
    await db.delete(
      'sync_queue',
      where: 'id = ? AND action = ? AND payload = ? AND created_at = ?',
      whereArgs: [sent['id'], sent['action'], sent['payload'], sent['created_at']],
    );
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

  /// Removes the queued deletes of notes this device had synced and then removed for good: their rows are gone. Only a
  /// note the cloud has seen has a base revision, which tells them apart from notes never synced (their deletes stay).
  /// Returns the ids of the notes whose queued delete was removed.
  Future<List<String>> removeQueuedDeletesOfPurgedSyncedNotes() async {
    const where = "entity_type = 'note' AND action = 'delete' "
        'AND base_revision IS NOT NULL AND entity_id NOT IN (SELECT id FROM notes)';
    final rows = await db.rawQuery('SELECT entity_id FROM sync_queue WHERE $where');
    await db.rawDelete('DELETE FROM sync_queue WHERE $where');
    return [for (final row in rows) row['entity_id'] as String];
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

  /// Ids of the notes whose queued change is set aside: the sync skips them until the user decides.
  Future<Set<String>> getSetAsideNoteIds() async {
    final rows = await db.query(
      'sync_queue',
      columns: ['entity_id'],
      where: 'entity_type = ? AND set_aside = 1',
      whereArgs: ['note'],
    );
    return rows.map((row) => row['entity_id'] as String).toSet();
  }

  /// The queued changes set aside by the sync, oldest first, with their last refusal.
  Future<List<Map<String, dynamic>>> getSetAsideSyncActions() async {
    return db.query('sync_queue', where: 'set_aside = 1', orderBy: 'id ASC');
  }

  /// Rejections in a row after which a queued change is set aside (Model: pending-change, Set aside).
  static const int rejectionsBeforeSetAside = 3;

  /// Counts a rejection of the queued change [sent] with the message the cloud gave; the third in a row sets it aside.
  /// Counted only while [sent] is still the queued item: a change queued while its upload was in flight is not.
  Future<void> recordRejectedSyncAction(Map<String, dynamic> sent, String message) async {
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1, last_error = ?, '
      'set_aside = CASE WHEN attempts + 1 >= ? THEN 1 ELSE set_aside END '
      'WHERE id = ? AND action = ? AND payload = ? AND created_at = ?',
      [message, rejectionsBeforeSetAside, sent['id'], sent['action'], sent['payload'], sent['created_at']],
    );
  }

  /// Puts a set-aside change back in the queue at its place, with its rejections cleared. False when it is not set aside.
  Future<bool> retrySetAsideSyncAction(String entityType, String entityId) async {
    final changed = await db.update(
      'sync_queue',
      {'attempts': 0, 'set_aside': 0, 'last_error': null},
      where: 'entity_type = ? AND entity_id = ? AND set_aside = 1',
      whereArgs: [entityType, entityId],
    );
    return changed > 0;
  }

  /// Removes a set-aside change, which is then discarded unsent. False when it is not set aside.
  Future<bool> removeSetAsideSyncAction(String entityType, String entityId) async {
    final removed = await db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ? AND set_aside = 1',
      whereArgs: [entityType, entityId],
    );
    return removed > 0;
  }

  // --- CLOUD STATE ---

  /// Vault paths of the attachments the cloud has, as this device knows them (uploaded or downloaded here).
  Future<Set<String>> getCloudAttachmentPaths() async {
    final rows = await db.query('uploaded_attachments', columns: ['path']);
    return rows.map((row) => row['path'] as String).toSet();
  }

  /// Records that the cloud has the attachment at [path].
  Future<void> addCloudAttachment(String path) async {
    await db.insert('uploaded_attachments', {'path': path}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Forgets the cloud state of the previous account: the cloud revisions of notes and folders, and the attachments the
  /// cloud had. The next sync run is then a full check.
  Future<void> forgetCloudState() async {
    await db.transaction((txn) async {
      await txn.update('notes', {'cloud_revision': null});
      await txn.update('folders', {'cloud_revision': null});
      await txn.delete('uploaded_attachments');
    });
  }
}
