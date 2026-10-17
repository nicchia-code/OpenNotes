import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sync_cloud.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a timeout while an attachment uploads fails the run instead of being logged', () async {
    const userId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    const attachment = 'attachments/schizzo.png';
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final cloud = FakeSyncCloud(server);

    SharedPreferences.setMockInitialValues(signedInPreferences(userId));
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final tempDir = await Directory.systemTemp.createTemp('sync_attachment_timeout_vault_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
    final vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);
    final syncService = SyncService(
      dbService,
      vaultService,
      requestTimeout: const Duration(milliseconds: 300),
    );
    addTearDown(syncService.dispose);

    await syncService.initializeSupabase('http://127.0.0.1:${server.port}', 'test-anon-key');
    await waitUntil(() => cloud.noteReads.isNotEmpty && !syncService.isSyncing);
    await waitUntil(() => !syncService.isSyncing);
    expect(syncService.lastFailure, isNull);

    // A note with a drawing on this device; the storage takes the upload and never answers it.
    final file = vaultService.resolveAttachment(attachment);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(const [1, 2, 3]);
    cloud.hangNextStorageUpload = true;
    final now = DateTime.now();
    final note = Note(
      id: 'slow-drawing',
      title: 'Disegno lento',
      content: '[{"type":"image","text":"$attachment"}]',
      createdAt: now,
      updatedAt: now,
    );
    await dbService.upsertNote(note);
    await syncService.notifyNoteChanged(note);
    await waitUntil(() => !syncService.isSyncing);

    expect(syncService.lastFailure, SyncErrorCategory.timeout, reason: 'the run fails at the timeout of the upload');
    expect(cloud.notes.containsKey('slow-drawing'), isFalse, reason: 'the note waits for the next run');
    expect((await dbService.getNoteById('slow-drawing'))!.syncedAt, isNull);
  });
}
