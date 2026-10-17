import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:open_notes/core/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a version 1 database with notes, folders and queue opens as version 2 without losing data', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = await Directory.systemTemp.createTemp('database_upgrade_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final path = p.join(tempDir.path, 'opennotes.db');

    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE folders (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, parent_id TEXT,
              icon TEXT NOT NULL DEFAULT 'folder', is_system INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL, updated_at TEXT NOT NULL)
          ''');
          await db.execute('''
            CREATE TABLE notes (
              id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL,
              folder_id TEXT NOT NULL DEFAULT 'notes', tags TEXT NOT NULL DEFAULT '[]',
              is_pinned INTEGER NOT NULL DEFAULT 0, is_locked INTEGER NOT NULL DEFAULT 0,
              is_deleted INTEGER NOT NULL DEFAULT 0, deleted_at TEXT,
              created_at TEXT NOT NULL, updated_at TEXT NOT NULL, synced_at TEXT, file_path TEXT)
          ''');
          await db.execute('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
              action TEXT NOT NULL, payload TEXT NOT NULL, created_at TEXT NOT NULL)
          ''');
          await db.insert('folders', {
            'id': 'work', 'name': 'Work', 'parent_id': null, 'icon': 'folder', 'is_system': 0,
            'created_at': '2026-01-01T10:00:00', 'updated_at': '2026-01-01T10:00:00',
          });
          await db.insert('notes', {
            'id': 'n1', 'title': 'Old title', 'content': 'text', 'folder_id': 'work', 'tags': '[]',
            'created_at': '2026-01-01T10:00:00', 'updated_at': '2026-01-02T10:00:00',
            'synced_at': '2026-01-01T11:00:00',
          });
          await db.insert('notes', {
            'id': 'n2', 'title': 'Trashed', 'content': '', 'folder_id': 'notes', 'tags': '[]',
            'is_deleted': 1, 'created_at': '2026-01-01T10:00:00', 'updated_at': '2026-01-01T10:00:00',
          });
          // n1 queued three times: the newest save must take the place of the oldest queued item.
          for (final row in [
            {'entity_type': 'note', 'entity_id': 'n1', 'action': 'upsert', 'payload': 'first', 'created_at': 't1'},
            {'entity_type': 'folder', 'entity_id': 'work', 'action': 'upsert', 'payload': 'folder', 'created_at': 't2'},
            {'entity_type': 'note', 'entity_id': 'n2', 'action': 'delete', 'payload': '{"id":"n2"}', 'created_at': 't3'},
            {'entity_type': 'note', 'entity_id': 'n1', 'action': 'upsert', 'payload': 'second', 'created_at': 't4'},
            {'entity_type': 'note', 'entity_id': 'n1', 'action': 'delete', 'payload': 'newest', 'created_at': 't5'},
          ]) {
            await db.insert('sync_queue', row);
          }
        },
      ),
    );
    await v1.close();

    final service = DatabaseService();
    await service.init(databasePath: path);
    final db = service.db;

    expect(await db.getVersion(), 2);

    final notes = await db.query('notes', orderBy: 'id');
    expect(notes.map((n) => n['id']), ['n1', 'n2']);
    expect(notes.first['title'], 'Old title');
    expect(notes.first['synced_at'], '2026-01-01T11:00:00');
    expect(notes.first['folder_id'], 'work');
    expect(notes.last['is_deleted'], 1);
    expect(notes.map((n) => n['cloud_revision']), [null, null]);

    final folders = await db.query('folders');
    expect(folders.single['name'], 'Work');
    expect(folders.single['cloud_revision'], isNull);

    final queue = await db.query('sync_queue', orderBy: 'id ASC');
    expect(queue.length, 3);
    expect(queue[0]['entity_id'], 'n1');
    expect(queue[0]['action'], 'delete');
    expect(queue[0]['payload'], 'newest');
    expect(queue[0]['created_at'], 't5');
    expect(queue[0]['base_revision'], isNull);
    expect(queue[0]['attempts'], 0);
    expect(queue[0]['set_aside'], 0);
    expect(queue[0]['last_error'], isNull);
    expect(queue[1]['entity_type'], 'folder');
    expect(queue[2]['entity_id'], 'n2');
    expect(queue[2]['action'], 'delete');

    expect(await db.query('uploaded_attachments'), isEmpty);

    // The unique index on (entity_type, entity_id) refuses a second queue item for the same entity.
    await expectLater(
      db.insert('sync_queue', {
        'entity_type': 'note', 'entity_id': 'n1', 'action': 'upsert', 'payload': 'x', 'created_at': 't6',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
