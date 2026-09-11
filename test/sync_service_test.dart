import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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

    tempDir = await Directory.systemTemp.createTemp('sync_test_vault_');
    vaultService = VaultService();
    await vaultService.init(customPath: tempDir.path);

    syncService = SyncService(dbService, vaultService);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('NotesProvider automatically refreshes when SyncService notifies updates', () async {
    final provider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: syncService,
    );
    await provider.init();
    expect(provider.notes, isEmpty);

    // Simulate an external/remote note being saved into dbService & notifying syncService
    final newNote = Note(
      id: 'cloud-note-1',
      title: 'Nota da Cloud',
      content: 'Contenuto sincronizzato',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncedAt: DateTime.now(),
    );
    await dbService.upsertNote(newNote);

    // SyncService fires notifyListeners (e.g. from realtime update or sync completion)
    syncService.notifyListeners();

    // Allow async microtasks in NotesProvider listener to finish
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(provider.notes.length, 1);
    expect(provider.notes.first.title, 'Nota da Cloud');
    expect(provider.selectedNoteId, 'cloud-note-1');

    provider.dispose();
  });

  test('SyncService queueing actions writes to SQLite sync_queue table', () async {
    final note = Note(
      id: 'local-note-1',
      title: 'Nota Locale',
      content: 'Test content',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await syncService.notifyNoteChanged(note);

    final pending = await dbService.getPendingSyncActions();
    expect(pending.length, 1);
    expect(pending.first['entity_type'], 'note');
    expect(pending.first['entity_id'], 'local-note-1');
    expect(pending.first['action'], 'upsert');
  });
}
