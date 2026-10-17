import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_log.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an attachment the storage refuses does not stop its note, and the next run uploads it again', () async {
    const userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const attachment = 'attachments/disegno.png';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_attachment_retry_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncLog = SyncLog(File('${tempDir.path}/sync_log.txt'));
    final syncService = SyncService(dbService, vaultService, log: syncLog);
    addTearDown(syncService.dispose);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);

    // A note with a drawing on this device, saved while the storage refuses the first upload.
    final file = vaultService.resolveAttachment(attachment);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(const [1, 2, 3]);
    cloud.storageUploadsRefused = 1;
    final now = DateTime.now();
    final note = Note(
      id: 'with-drawing',
      title: 'Con disegno',
      content: '[{"type":"image","text":"$attachment"}]',
      createdAt: now,
      updatedAt: now,
    );
    await dbService.upsertNote(note);
    await syncService.notifyNoteChanged(note);
    await waitUntil(() => !syncService.isSyncing);

    expect(cloud.notes.containsKey('with-drawing'), isTrue, reason: 'the note is sent without its refused drawing');
    expect(syncService.lastFailure, isNull, reason: 'a refused attachment does not fail the run');
    expect((await dbService.getNoteById('with-drawing'))!.syncedAt, isNotNull);
    expect(cloud.storageUploads, hasLength(1));
    expect(await dbService.getCloudAttachmentPaths(), isEmpty, reason: 'the drawing is not on the cloud yet');
    expect(await syncLog.read(), contains('[attachmentUpload] $attachment:'), reason: 'the refused upload is in the app log');

    // The next run uploads the drawing again, and records it as on the cloud.
    await syncService.syncNow();
    expect(cloud.storageUploads, hasLength(2), reason: 'the refused upload is tried again by the next run');
    expect(await dbService.getCloudAttachmentPaths(), contains(attachment));

    // Once the cloud has it, no later run uploads it again.
    await syncService.syncNow();
    expect(cloud.storageUploads, hasLength(2));
  });
}
