import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a full check applies a folder deletion placeholder as a delete made elsewhere', () async {
    const userId = '55555555-5555-4555-8555-555555555555';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);

    // No last revision: the run is a full check. The local folder predates revisions, so it has no cloud revision.
    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_full_folder_placeholder_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);

    final created = DateTime.utc(2026, 10, 1, 8);
    final deletedAt = DateTime.utc(2026, 10, 1, 9);
    final localEditedAt = DateTime.utc(2026, 10, 1, 10);
    cloud.putFolder({
      'id': 'gone-folder',
      'user_id': userId,
      'name': 'Eliminata altrove',
      'parent_id': null,
      'icon': 'folder',
      'is_system': false,
      'created_at': created.toIso8601String(),
      'updated_at': deletedAt.toIso8601String(),
      'purged_at': deletedAt.toIso8601String(),
    });

    await dbService.upsertFolder(Folder(
      id: 'gone-folder',
      name: 'Eliminata altrove',
      createdAt: created,
      updatedAt: localEditedAt,
    ));
    cloud.putNote(FakeSyncCloud.noteRow(userId, 'gone-note', 'Nota cestinata nella cartella', created)
      ..['folder_id'] = 'gone-folder'
      ..['is_deleted'] = true);
    await dbService.upsertNote(Note(
      id: 'gone-note',
      title: 'Nota cestinata nella cartella',
      content: '',
      folderId: 'gone-folder',
      isDeleted: true,
      createdAt: created,
      updatedAt: created,
    ).copyWith(syncedAt: created));

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await syncService.syncNow();

    final folderIds = (await dbService.getFolders()).map((f) => f.id);
    expect(folderIds, isNot(contains('gone-folder')), reason: 'the placeholder deletes the local folder');
    expect((await dbService.getNoteById('gone-note'))!.folderId, Folder.defaultNotesId,
        reason: 'the trashed note moves to Notes');
    expect(await dbService.getPendingSyncActions(), isEmpty, reason: 'nothing is queued, the placeholder is never saved');
    expect(cloud.folders['gone-folder']!['purged_at'], isNotNull, reason: 'the placeholder stays on the cloud');
  });
}
