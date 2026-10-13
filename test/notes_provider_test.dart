import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late VaultService vaultService;
  late SyncService syncService;
  late Directory tempDir;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.init(inMemory: true);

    tempDir = await Directory.systemTemp.createTemp('notes_provider_test_');
    vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    syncService = SyncService(dbService, vaultService);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('note list is reloaded after a debounced note save', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'older',
      title: 'Older',
      content: 'Older #work',
      tags: const ['work'],
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ));
    await dbService.upsertNote(Note(
      id: 'newer',
      title: 'Newer',
      content: 'Newer #work',
      tags: const ['work'],
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    expect(provider.notes.map((n) => n.id), ['newer', 'older']);

    // Editing the older note moves it to the top of the list
    provider.updateNoteContent('older', 'Older edited #work');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(provider.notes.map((n) => n.id), ['older', 'newer']);

    // Removing the tag from the note drops it from the tag filter
    provider.selectTag('work');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.notes.map((n) => n.id), ['older', 'newer']);

    provider.updateNoteContent('older', 'Older without tag');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(provider.notes.map((n) => n.id), ['newer']);

    provider.dispose();
  });

  test('tapping the only selected tag from Folders keeps the filter', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'tagged',
      title: 'Tagged',
      content: 'Tagged #work',
      tags: const ['work'],
      createdAt: now,
      updatedAt: now,
    ));
    await dbService.upsertNote(Note(
      id: 'plain',
      title: 'Plain',
      content: 'Plain',
      tags: const [],
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.selectTag('work', toggleOff: false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.selectedTags, {'work'});
    expect(provider.notes.map((n) => n.id), ['tagged']);

    // Sidebar behaviour is unchanged: tapping the only selected tag clears it
    provider.selectTag('work');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.selectedTags, isEmpty);
    expect(provider.notes.map((n) => n.id), ['tagged', 'plain']);

    provider.dispose();
  });

  test('pending save keeps changes made during the wait', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.updateNoteContent('a', 'A edited');
    await provider.togglePin('a');
    await provider.moveToTrash('a');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final a = await dbService.getNoteById('a');
    expect(a!.content, 'A edited');
    expect(a.isPinned, isTrue);
    expect(a.isDeleted, isTrue);

    provider.dispose();
  });

  test('editing another note within 400 ms writes the waiting version of the first', () async {
    final now = DateTime.now();
    for (final id in ['a', 'b']) {
      await dbService.upsertNote(Note(
        id: id,
        title: id.toUpperCase(),
        content: id.toUpperCase(),
        createdAt: now,
        updatedAt: now,
      ));
    }

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.updateNoteContent('a', 'A edited');
    provider.updateNoteContent('b', 'B edited');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect((await dbService.getNoteById('a'))!.content, 'A edited');
    expect((await dbService.getNoteById('b'))!.content, 'B edited');

    provider.dispose();
  });

  test('leaving the foreground writes the waiting version at once', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.updateNoteContent('a', 'A edited');
    await provider.flushOnAppLeavingForeground();

    final a = await dbService.getNoteById('a');
    expect(a!.content, 'A edited');

    provider.dispose();
  });

  test('an edit to a note outside the loaded list is neither waited for nor written', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    provider.updateNoteContent('a', 'A edited');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect((await dbService.getNoteById('a'))!.content, 'A');
    expect(provider.contentSaveFailed, isFalse);

    provider.dispose();
  });

  test('the list shows a version delivered while its write runs', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.updateNoteContent('a', 'A first');
    final write = provider.flushOnAppLeavingForeground();
    provider.updateNoteContent('a', 'A second');
    await write;

    expect(provider.notes.firstWhere((n) => n.id == 'a').content, 'A second');

    provider.dispose();
  });

  test('disposing the provider does not drop the waiting version', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.updateNoteContent('a', 'A edited');
    provider.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final a = await dbService.getNoteById('a');
    expect(a!.content, 'A edited');
  });

  test('pin, trash, restore and move write the waiting text before changing the state', () async {
    final now = DateTime.now();
    for (final id in ['pin', 'trash', 'move', 'restore']) {
      await dbService.upsertNote(Note(
        id: id,
        title: id,
        content: '$id old',
        folderId: 'work',
        isDeleted: id == 'restore',
        deletedAt: id == 'restore' ? now : null,
        createdAt: now,
        updatedAt: now,
      ));
    }

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.updateNoteContent('pin', 'pin new');
    await provider.togglePin('pin');
    provider.updateNoteContent('trash', 'trash new');
    await provider.moveToTrash('trash');
    provider.updateNoteContent('move', 'move new');
    await provider.moveNoteToFolder('move', 'other');
    // An edit is taken only for a note in the loaded list: the trash view lists the note to restore.
    provider.selectFolder(Folder.trashId);
    await provider.refreshNotes();
    provider.updateNoteContent('restore', 'restore new');
    await provider.restoreFromTrash('restore');

    // Checked at once, before the 400 ms wait of the content save could run.
    final pin = await dbService.getNoteById('pin');
    expect(pin!.content, 'pin new');
    expect(pin.isPinned, isTrue);

    final trash = await dbService.getNoteById('trash');
    expect(trash!.content, 'trash new');
    expect(trash.isDeleted, isTrue);

    final restore = await dbService.getNoteById('restore');
    expect(restore!.content, 'restore new');
    expect(restore.isDeleted, isFalse);

    final move = await dbService.getNoteById('move');
    expect(move!.content, 'move new');
    expect(move.folderId, 'other');

    provider.dispose();
  });

  test('a state change waits for a content write that is already running', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    provider.updateNoteContent('a', 'A first');
    final write = provider.flushOnAppLeavingForeground();
    await provider.togglePin('a');
    await write;

    final a = await dbService.getNoteById('a');
    expect(a!.content, 'A first');
    expect(a.isPinned, isTrue);

    provider.dispose();
  });

  test('deleting a note again in the trash refreshes its trash date only', () async {
    final old = DateTime(2020, 1, 1);
    await dbService.upsertNote(Note(
      id: 't',
      title: 'Trashed',
      content: 'Trashed',
      folderId: 'work',
      isPinned: true,
      isDeleted: true,
      deletedAt: old,
      createdAt: old,
      updatedAt: old,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    provider.selectFolder(Folder.trashId);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.notes.map((n) => n.id), contains('t'));

    await provider.moveToTrash('t');

    final t = await dbService.getNoteById('t');
    expect(t!.isDeleted, isTrue);
    expect(t.folderId, 'work');
    expect(t.isPinned, isTrue);
    expect(t.deletedAt!.isAfter(old), isTrue);
    expect(t.updatedAt.isAfter(old), isTrue);

    provider.dispose();
  });

  test('trashing the selected note selects its neighbour without ever selecting another note', () async {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      final id = 'n$i';
      await dbService.upsertNote(Note(
        id: id,
        title: id,
        content: id,
        createdAt: now,
        updatedAt: now.subtract(Duration(minutes: i)),
      ));
    }

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    provider.selectNote('n1');
    final ids = provider.notes.map((n) => n.id).toList();
    final index = ids.indexOf('n1');
    final expected = index + 1 < ids.length ? ids[index + 1] : ids[index - 1];

    final seen = <String?>[];
    provider.addListener(() => seen.add(provider.selectedNoteId));
    await provider.moveToTrash('n1');

    expect(provider.selectedNoteId, expected);
    expect(seen, isNotEmpty);
    expect(seen, everyElement(expected));

    provider.dispose();
  });

  test('trashing the selected note falls back to the previous note when its next neighbour vanishes mid-move', () async {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      await dbService.upsertNote(Note(
        id: 'n$i',
        title: 'n$i',
        content: 'n$i',
        createdAt: now,
        updatedAt: now.subtract(Duration(minutes: i)),
      ));
    }

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    provider.selectNote('n1');

    final move = provider.moveToTrash('n1');
    // The selection is set to the next neighbour before the file write starts.
    while (provider.selectedNoteId != 'n2') {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    // A remote change removes the next neighbour while the move is in progress, then the list reloads.
    await dbService.db.delete('notes', where: 'id = ?', whereArgs: ['n2']);
    await provider.refreshNotes();
    expect(await move, isTrue);

    expect(provider.notes.map((n) => n.id), ['n0']);
    expect(provider.selectedNoteId, 'n0');

    provider.dispose();
  });

  test('deleting one of two notes sharing a file keeps the other copy', () async {
    final now = DateTime(2024, 1, 1);
    final a = Note(id: 'a', title: 'Nuova nota', content: 'A', createdAt: now, updatedAt: now);
    final shared = await vaultService.saveNote(a);
    await dbService.upsertNote(a.copyWith(filePath: shared));
    final b = Note(id: 'b', title: 'Nuova nota', content: 'B', createdAt: now, updatedAt: now);
    await dbService.upsertNote(b.copyWith(filePath: await vaultService.saveNote(b)));
    final sharedFile = File(shared);
    await sharedFile.writeAsString(VaultService.serializeNoteToMarkdown(a));
    expect(await sharedFile.exists(), isTrue);

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    await provider.permanentlyDeleteNote('a');
    expect(await sharedFile.exists(), isTrue);
    final kept = await sharedFile.readAsString();
    expect(kept, contains('B'));
    expect(kept, isNot(contains('A')));

    await provider.permanentlyDeleteNote('b');
    expect(await sharedFile.exists(), isFalse);

    provider.dispose();
  });

  test('a file shared by three notes keeps the most recently edited remaining one', () async {
    final old = DateTime(2024, 1, 1);
    final a = Note(id: 'a', title: 'Nuova nota', content: 'versione A', createdAt: old, updatedAt: old);
    final shared = await vaultService.saveNote(a);
    await dbService.upsertNote(a.copyWith(filePath: shared));
    final b = Note(id: 'b', title: 'Nuova nota', content: 'versione B', createdAt: old, updatedAt: DateTime(2024, 3, 1));
    await dbService.upsertNote(b.copyWith(filePath: shared));
    final c = Note(id: 'c', title: 'Nuova nota', content: 'versione C', createdAt: old, updatedAt: DateTime(2024, 2, 1));
    await dbService.upsertNote(c.copyWith(filePath: shared));

    await vaultService.deleteNoteFileIfUnused(dbService, shared, exceptNoteId: 'a');
    final kept = await File(shared).readAsString();
    expect(kept, contains('versione B'));
    expect(kept, isNot(contains('versione C')));
  });

  test('the file of a note being deleted is not counted as used by it', () async {
    final now = DateTime(2024, 1, 1);
    final a = Note(id: 'a', title: 'Nuova nota', content: 'A', createdAt: now, updatedAt: now);
    final path = await vaultService.saveNote(a);
    await dbService.upsertNote(a.copyWith(filePath: path));

    await vaultService.deleteNoteFileIfUnused(dbService, path, exceptNoteId: 'a');
    expect(await File(path).exists(), isFalse);
    expect(await dbService.getNoteById('a'), isNotNull);
  });

  test('emptying trash removes a file shared by trashed notes with the last one', () async {
    final now = DateTime(2024, 1, 1);
    final a = Note(id: 'a', title: 'Nuova nota', content: 'A', createdAt: now, updatedAt: now, isDeleted: true);
    final shared = await vaultService.saveNote(a);
    await dbService.upsertNote(a.copyWith(filePath: shared));
    final b = Note(id: 'b', title: 'Nuova nota', content: 'B', createdAt: now, updatedAt: now, isDeleted: true);
    await dbService.upsertNote(b.copyWith(filePath: shared));
    final sharedFile = File(shared);
    expect(await sharedFile.exists(), isTrue);

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    await provider.emptyTrash();
    expect(await dbService.getNoteById('a'), isNull);
    expect(await dbService.getNoteById('b'), isNull);
    expect(await sharedFile.exists(), isFalse);

    provider.dispose();
  });

  test('the trash check counts protected notes hidden by the active filter', () async {
    final now = DateTime(2024, 1, 1);
    final shown = Note(id: 'a', title: 'Nuova nota', content: 'alpha', createdAt: now, updatedAt: now, isDeleted: true);
    await dbService.upsertNote(shown);
    final hidden = Note(id: 'b', title: 'Nuova nota', content: 'beta', createdAt: now, updatedAt: now, isDeleted: true, isLocked: true);
    await dbService.upsertNote(hidden);

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    provider.selectFolder(Folder.trashId);
    provider.setSearchQuery('alpha');
    await provider.refreshNotes();

    expect(provider.notes.map((n) => n.id), ['a']);
    expect(await provider.trashHasProtectedNote(), isTrue);

    provider.dispose();
  });

  test('a note removed from the cloud keeps the file another note still uses', () async {
    final now = DateTime(2024, 1, 1);
    final a = Note(id: 'a', title: 'Nuova nota', content: 'A', createdAt: now, updatedAt: now);
    final shared = await vaultService.saveNote(a);
    await dbService.upsertNote(a.copyWith(filePath: shared));
    final b = Note(id: 'b', title: 'Nuova nota', content: 'B', createdAt: now, updatedAt: now);
    await dbService.upsertNote(b.copyWith(filePath: shared));
    final sharedFile = File(shared);

    PostgresChangePayload deleted(String id) => PostgresChangePayload(
          schema: 'public',
          table: 'notes',
          commitTimestamp: now,
          eventType: PostgresChangeEvent.delete,
          newRecord: const {},
          oldRecord: {'id': id},
          errors: null,
        );

    await syncService.handleRemoteNoteChange(deleted('a'));
    expect(await dbService.getNoteById('a'), isNull);
    expect(await sharedFile.exists(), isTrue);

    await syncService.handleRemoteNoteChange(deleted('b'));
    expect(await sharedFile.exists(), isFalse);
  });

  test('new note outside a folder selection goes to the Notes folder', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    provider.selectFolder(Folder.allNotesId);

    final note = (await provider.createNote())!;

    expect(note.folderId, Folder.defaultNotesId);
    provider.dispose();
  });

  test('creating and renaming a folder reloads the note list', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    final folder = await provider.createFolder('Lavoro');
    provider.selectFolder(folder.id);
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'in-folder',
      title: 'Dentro',
      content: 'Dentro',
      folderId: folder.id,
      createdAt: now,
      updatedAt: now,
    ));
    expect(provider.notes.map((n) => n.id), isNot(contains('in-folder')));

    await provider.createFolder('Altra');
    expect(provider.notes.map((n) => n.id), contains('in-folder'));
    expect(provider.getNoteCountForFolder(folder.id), 1);

    await dbService.upsertNote(Note(
      id: 'in-folder-2',
      title: 'Ancora',
      content: 'Ancora',
      folderId: folder.id,
      createdAt: now,
      updatedAt: now,
    ));
    await provider.renameFolder(folder.id, 'Lavori');
    expect(provider.notes.map((n) => n.id), containsAll(['in-folder', 'in-folder-2']));
    expect(provider.getNoteCountForFolder(folder.id), 2);

    provider.dispose();
  });

  test('a remote folder change reloads the folder list', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    expect(provider.folders.map((f) => f.id), isNot(contains('remote-folder')));

    await syncService.handleRemoteFolderChange(PostgresChangePayload(
      schema: 'public',
      table: 'folders',
      commitTimestamp: DateTime.utc(2026, 10, 1),
      eventType: PostgresChangeEvent.insert,
      newRecord: {
        'id': 'remote-folder',
        'name': 'Dal cloud',
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2026-10-01T00:00:00Z',
      },
      oldRecord: const {},
      errors: null,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.folders.map((f) => f.id), contains('remote-folder'));

    provider.dispose();
  });

  test('a remote change does not restore a folder whose delete is queued', () async {
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'remote-deleted', name: 'Eliminata', createdAt: now, updatedAt: now));
    await dbService.deleteFolder('remote-deleted');
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: 'remote-deleted',
      action: 'delete',
      payload: '{"id":"remote-deleted"}',
    );

    await syncService.handleRemoteFolderChange(PostgresChangePayload(
      schema: 'public',
      table: 'folders',
      commitTimestamp: DateTime.utc(2026, 10, 2),
      eventType: PostgresChangeEvent.update,
      newRecord: {
        'id': 'remote-deleted',
        'name': 'Modificata nel cloud',
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2026-10-02T00:00:00Z',
      },
      oldRecord: const {},
      errors: null,
    ));

    final folders = await dbService.getFolders();
    expect(folders.map((f) => f.id), isNot(contains('remote-deleted')));
  });

  test('a remote change made after a queued folder delete restores the folder and drops the delete', () async {
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'later-changed', name: 'Eliminata', createdAt: now, updatedAt: now));
    await dbService.deleteFolder('later-changed');
    await dbService.queueSyncAction(
      entityType: 'folder',
      entityId: 'later-changed',
      action: 'delete',
      payload: '{"id":"later-changed"}',
    );

    await syncService.handleRemoteFolderChange(PostgresChangePayload(
      schema: 'public',
      table: 'folders',
      commitTimestamp: DateTime.utc(2099, 1, 1),
      eventType: PostgresChangeEvent.update,
      newRecord: {
        'id': 'later-changed',
        'name': 'Modificata dopo',
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2099-01-01T00:00:00Z',
      },
      oldRecord: const {},
      errors: null,
    ));

    final folders = await dbService.getFolders();
    expect(folders.map((f) => f.id), contains('later-changed'));
    expect(await dbService.hasPendingSyncAction(entityType: 'folder', entityId: 'later-changed'), isFalse);
  });

  test('a remote change restores a folder whose delete was already sent', () async {
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'sent-deleted', name: 'Inviata', createdAt: now, updatedAt: now));
    await dbService.deleteFolder('sent-deleted');

    await syncService.handleRemoteFolderChange(PostgresChangePayload(
      schema: 'public',
      table: 'folders',
      commitTimestamp: DateTime.utc(2026, 10, 2),
      eventType: PostgresChangeEvent.update,
      newRecord: {
        'id': 'sent-deleted',
        'name': 'Modificata nel cloud',
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2026-10-02T00:00:00Z',
      },
      oldRecord: const {},
      errors: null,
    ));

    final folders = await dbService.getFolders();
    expect(folders.map((f) => f.id), contains('sent-deleted'));
  });

  test('a folder deleted from the cloud keeps the open view on it', () async {
    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'cloud-gone', name: 'Eliminata nel cloud', createdAt: now, updatedAt: now));
    await dbService.upsertNote(Note(
      id: 'cloud-note',
      title: 'Nella cartella',
      content: 'Nella cartella',
      folderId: 'cloud-gone',
      createdAt: now,
      updatedAt: now,
    ));
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    provider.selectFolder('cloud-gone');

    await syncService.handleRemoteFolderChange(PostgresChangePayload(
      schema: 'public',
      table: 'folders',
      commitTimestamp: DateTime.utc(2026, 10, 2),
      eventType: PostgresChangeEvent.delete,
      newRecord: const {},
      oldRecord: const {'id': 'cloud-gone'},
      errors: null,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.selectedFolderId, 'cloud-gone');
    expect(provider.notes, isEmpty);
    final moved = await dbService.getNotes(folderId: Folder.defaultNotesId, isDeleted: false);
    expect(moved.map((n) => n.id), contains('cloud-note'));

    provider.dispose();
  });

  test('a folder deleted here moves the open view to All notes', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    final folder = await provider.createFolder('Locale');
    provider.selectFolder(folder.id);

    await provider.deleteFolder(folder.id);
    expect(provider.selectedFolderId, Folder.allNotesId);

    provider.dispose();
  });

  test('tag list follows trash, restore and move of a note', () async {
    const tag = 'cestino-tag';
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'tagged-trash',
      title: 'Tagged',
      content: '#$tag Tagged',
      tags: const [tag],
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    expect(provider.tags.map((t) => t.name), contains(tag));

    await provider.moveToTrash('tagged-trash');
    expect(provider.tags.map((t) => t.name), isNot(contains(tag)));

    await provider.restoreFromTrash('tagged-trash');
    expect(provider.tags.singleWhere((t) => t.name == tag).count, 1);

    await provider.moveToTrash('tagged-trash');
    expect(provider.tags.map((t) => t.name), isNot(contains(tag)));

    await provider.moveNoteToFolder('tagged-trash', Folder.defaultNotesId);
    expect(provider.tags.singleWhere((t) => t.name == tag).count, 1);

    provider.dispose();
  });

  test('a failed note save keeps the text waiting and retries on the next delivery', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    // A vault path that is a file cannot be written
    await tempDir.delete(recursive: true);
    await File(tempDir.path).writeAsString('not a folder');
    provider.updateNoteContent('a', 'Testo nuovo');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(provider.contentSaveFailed, isTrue);
    expect((await dbService.getNoteById('a'))!.content, 'A');

    // Vault is writable again: the next delivery writes the waiting text
    await File(tempDir.path).delete();
    await Directory(tempDir.path).create();
    provider.updateNoteContent('a', 'Testo nuovo');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(provider.contentSaveFailed, isFalse);
    expect((await dbService.getNoteById('a'))!.content, 'Testo nuovo');

    provider.dispose();
  });

  test('export reads the text the editor still holds, not the saved copy', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();

    var deliveries = 0;
    void deliver() {
      deliveries++;
      provider.updateNoteContent('a', 'Testo nuovo');
    }

    provider.attachEditorDelivery(deliver);
    provider.deliverWaitingEdits();
    expect(deliveries, 1);
    expect(provider.notes.firstWhere((n) => n.id == 'a').content, 'Testo nuovo');

    // A detached editor is no longer asked for its text
    provider.detachEditorDelivery(deliver);
    provider.deliverWaitingEdits();
    expect(deliveries, 1);

    provider.dispose();
  });

  test('a trash move whose file cannot be written leaves the note as it was and warns', () async {
    final now = DateTime.now();
    await dbService.upsertNote(Note(
      id: 'a',
      title: 'A',
      content: 'A',
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    var warnings = 0;
    final subscription = provider.actionFailures.listen((_) => warnings++);

    // A vault path that is a file cannot be written
    await tempDir.delete(recursive: true);
    await File(tempDir.path).writeAsString('not a folder');
    expect(await provider.moveToTrash('a'), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect((await dbService.getNoteById('a'))!.isDeleted, isFalse);
    expect(await dbService.getPendingSyncActions(), isEmpty);
    expect(warnings, 1);

    // Vault is writable again: the file is written before the database changes
    await File(tempDir.path).delete();
    await Directory(tempDir.path).create();
    expect(await provider.moveToTrash('a'), isTrue);

    final trashed = await dbService.getNoteById('a');
    expect(trashed!.isDeleted, isTrue);
    expect(await File('${tempDir.path}/A.md').readAsString(), contains('deleted: true'));
    expect(warnings, 1);

    await subscription.cancel();
    provider.dispose();
  });

  test('a permanent delete whose file cannot be removed keeps the note in trash and queues nothing', () async {
    final now = DateTime.now();
    final sharedPath = '${tempDir.path}/shared.md';
    await Directory(sharedPath).create();
    await dbService.upsertNote(Note(
      id: 'trashed',
      title: 'Trashed',
      content: 'Trashed',
      isDeleted: true,
      deletedAt: now,
      filePath: sharedPath,
      createdAt: now,
      updatedAt: now,
    ));
    await dbService.upsertNote(Note(
      id: 'kept',
      title: 'Kept',
      content: 'Kept',
      filePath: sharedPath,
      createdAt: now,
      updatedAt: now,
    ));

    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    var warnings = 0;
    final subscription = provider.actionFailures.listen((_) => warnings++);

    // The other note still uses the file, so it must be rewritten: a directory cannot be
    expect(await provider.permanentlyDeleteNote('trashed'), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(await dbService.getNoteById('trashed'), isNotNull);
    expect(await dbService.getPendingSyncActions(), isEmpty);
    expect(warnings, 1);

    await subscription.cancel();
    provider.dispose();
  });
}
