import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deleting a folder drops its queued rename and sends only the delete', () async {
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_folder_delete_drops_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(dbService, vaultService);

    final now = DateTime.utc(2026, 10, 1, 9);
    final folder = Folder(id: 'renamed-then-deleted', name: 'Nuovo nome', createdAt: now, updatedAt: now);
    await syncService.notifyFolderChanged(folder);
    expect(await dbService.hasPendingSyncAction(entityType: 'folder', entityId: folder.id, action: 'upsert'), isTrue);

    await syncService.notifyFolderChanged(folder, isDelete: true);

    expect(await dbService.hasPendingSyncAction(entityType: 'folder', entityId: folder.id, action: 'upsert'), isFalse);
    expect(await dbService.hasPendingSyncAction(entityType: 'folder', entityId: folder.id, action: 'delete'), isTrue);
  });
}
