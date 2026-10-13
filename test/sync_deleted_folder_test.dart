import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a cloud note whose folder is gone locally stays in Notes after download', () async {
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_deleted_folder_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    final remoteNote = Note(
      id: 'orphan-note',
      title: 'Nota dalla cartella eliminata',
      content: '',
      folderId: 'deleted-folder',
      createdAt: DateTime.utc(2026, 10, 1, 9),
      updatedAt: DateTime.utc(2026, 10, 2, 9),
    );

    await syncService.applyRemoteNote(remoteNote);

    final stored = await dbService.getNoteById('orphan-note');
    expect(stored!.folderId, Folder.defaultNotesId);
    expect(stored.updatedAt.isAtSameMomentAs(remoteNote.updatedAt), isTrue);
  });

  test('a cloud note whose folder exists locally keeps that folder', () async {
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_existing_folder_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    final now = DateTime.utc(2026, 10, 1, 9);
    await dbService.upsertFolder(Folder(id: 'kept-folder', name: 'Lavoro', createdAt: now, updatedAt: now));
    await syncService.applyRemoteNote(Note(
      id: 'kept-note',
      title: 'Nota in cartella esistente',
      content: '',
      folderId: 'kept-folder',
      createdAt: now,
      updatedAt: now,
    ));

    final stored = await dbService.getNoteById('kept-note');
    expect(stored!.folderId, 'kept-folder');
  });
}
