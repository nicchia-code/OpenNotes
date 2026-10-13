import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/notes_list/note_action_menu.dart';
import 'package:open_notes/core/services/security_service.dart';
import 'package:open_notes/ui/notes_list/note_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;
  late VaultService vault;
  late SyncService sync;
  late NotesProvider provider;
  late Directory tempDir;

  setUp(() async {
    db = DatabaseService();
    await db.init(inMemory: true);
    tempDir = await Directory.systemTemp.createTemp('note_actions_test_');
    vault = VaultService();
    await vault.init(customPath: tempDir.path);
    sync = SyncService(db, vault);
    provider = NotesProvider(
      dbService: db,
      vaultService: vault,
      syncService: sync,
    );
    await provider.init();
  });

  tearDown(() async {
    provider.dispose();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('menu actions depend on active versus trashed note state', () {
    final active = Note(
      id: 'active',
      title: 'Attiva',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final deleted = active.copyWith(isDeleted: true);
    expect(NoteActionMenu.actionsFor(active), [
      NoteMenuAction.pin,
      NoteMenuAction.lock,
      NoteMenuAction.duplicate,
      NoteMenuAction.move,
      NoteMenuAction.share,
      NoteMenuAction.export,
      NoteMenuAction.trash,
    ]);
    expect(NoteActionMenu.actionsFor(deleted), [
      NoteMenuAction.restore,
      NoteMenuAction.move,
      NoteMenuAction.lock,
      NoteMenuAction.permanentlyDelete,
    ]);
  });

  test('notes list long-press menu leaves out trashing and permanent deletion', () {
    final active = Note(
      id: 'list-active',
      title: 'Attiva',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final deleted = active.copyWith(isDeleted: true);
    expect(NoteActionMenu.actionsFor(active, fromList: true), isNot(contains(NoteMenuAction.trash)));
    expect(NoteActionMenu.actionsFor(active, fromList: true), contains(NoteMenuAction.duplicate));
    expect(NoteActionMenu.actionsFor(deleted, fromList: true), [
      NoteMenuAction.restore,
      NoteMenuAction.move,
      NoteMenuAction.lock,
    ]);
  });

  testWidgets('desktop action popup presents active-note actions', (
    tester,
  ) async {
    NoteMenuAction? selected;
    final note = Note(
      id: 'active-menu',
      title: 'Nota attiva',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => NoteActionMenu.showMaterial(
                context: context,
                position: const Offset(100, 100),
                note: note,
                onSelected: (action) => selected = action,
              ),
              child: const Text('Apri'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('Duplica'), findsOneWidget);
    expect(find.text('Sposta in…'), findsOneWidget);
    expect(find.text('Sposta nel cestino'), findsOneWidget);
    await tester.tap(find.text('Duplica'));
    await tester.pumpAndSettle();
    expect(selected, NoteMenuAction.duplicate);
  });

  testWidgets('desktop action popup presents trash-note actions only', (
    tester,
  ) async {
    final note = Note(
      id: 'trash-menu',
      title: 'Nota eliminata',
      content: '',
      isDeleted: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => NoteActionMenu.showMaterial(
                context: context,
                position: const Offset(100, 100),
                note: note,
                onSelected: (_) {},
              ),
              child: const Text('Apri cestino'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri cestino'));
    await tester.pumpAndSettle();
    expect(find.text('Ripristina nota'), findsOneWidget);
    expect(find.text('Proteggi nota'), findsOneWidget);
    expect(find.text('Elimina definitivamente'), findsOneWidget);
    expect(find.text('Fissa nota'), findsNothing);
    expect(find.text('Duplica'), findsNothing);
  });

  testWidgets('cancelled unlock on duplicate opens the original note', (
    tester,
  ) async {
    // The test font is wider than the real one, so the PIN dialog's Row overflows.
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) {
        onError?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = onError);
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final security = SecurityService();
    final note = Note(
      id: 'locked-original',
      title: 'Protetta',
      content: '',
      isLocked: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    Note? opened;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: security),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => NoteActions.showMobile(
                  context,
                  note,
                  onOpenAfterDuplicate: (n) => opened = n,
                ),
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      ),
    );
    provider.selectNote('some-other-note');
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplica'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(opened?.id, note.id);
  });

  testWidgets('permanent deletion asks for confirmation before the PIN', (
    tester,
  ) async {
    final security = SecurityService();
    final note = Note(
      id: 'locked-trash',
      title: 'Protetta nel cestino',
      content: '',
      isLocked: true,
      isDeleted: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    bool? result;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: security),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await NoteActions.confirmPermanentDelete(
                    context,
                    note,
                  );
                },
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare definitivamente la nota?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  test(
    'duplicate preserves content and tags while copying lock state without pinning',
    () async {
      final note = Note(
        id: 'original',
        title: 'Promemoria',
        content: '# Promemoria\n\nContenuto #lavoro',
        folderId: 'notes',
        tags: const ['lavoro'],
        isPinned: true,
        isLocked: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.upsertNote(note);

      final copy = await provider.duplicateNote(note.id);

      expect(copy, isNotNull);
      expect(copy!.id, isNot(note.id));
      expect(copy.title, 'Promemoria (copia)');
      expect(copy.content, '# Promemoria (copia)\n\nContenuto #lavoro');
      expect(copy.folderId, note.folderId);
      expect(copy.tags, note.tags);
      expect(copy.isPinned, isFalse);
      expect(copy.isLocked, isTrue);
      expect(provider.selectedNoteId, copy.id);
      final lavoro = provider.tags.singleWhere((tag) => tag.name == 'lavoro');
      expect(lavoro.count, 2);
    },
  );

  test('duplicate clears an active search so the copy is listed and selected', () async {
    final note = Note(
      id: 'searched',
      title: 'Promemoria',
      content: '# Promemoria\n\nContenuto',
      folderId: 'notes',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.upsertNote(note);
    provider.setSearchQuery('zzz-nessun-risultato');
    await provider.refreshNotes();
    expect(provider.notes, isEmpty);

    final copy = await provider.duplicateNote(note.id);

    expect(copy, isNotNull);
    expect(provider.searchQuery, isEmpty);
    expect(provider.notes.map((n) => n.id), contains(copy!.id));
    expect(provider.selectedNoteId, copy.id);
    expect(provider.selectedNote, isNotNull);
  });

  test(
    'duplicate keeps plain text that looks like a JSON list of non-objects',
    () async {
      final note = Note(
        id: 'json-like',
        title: 'Lista',
        content: '[1, 2]\nTesto originale',
        folderId: 'notes',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.upsertNote(note);

      final copy = await provider.duplicateNote(note.id);

      expect(copy, isNotNull);
      expect(copy!.content, '# Lista (copia)\n[1, 2]\nTesto originale');
    },
  );

  test(
    'moving trashed note changes folder and clears deletion timestamp',
    () async {
      final note = Note(
        id: 'trashed',
        title: 'Cestino',
        content: '',
        isDeleted: true,
        deletedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.upsertNote(note);

      await provider.moveNoteToFolder(note.id, 'notes');

      final moved = await db.getNoteById(note.id);
      expect(moved!.folderId, 'notes');
      expect(moved.isDeleted, isFalse);
      expect(moved.deletedAt, isNull);
    },
  );

  test('locking a trashed note keeps it in the trash and updates its date', () async {
    final note = Note(
      id: 'trashed-lock',
      title: 'Cestino protetto',
      content: '',
      folderId: 'notes',
      isDeleted: true,
      deletedAt: DateTime(2020),
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );
    await db.upsertNote(note);

    await provider.toggleLock(note.id);

    final locked = await db.getNoteById(note.id);
    expect(locked!.isLocked, isTrue);
    expect(locked.isDeleted, isTrue);
    expect(locked.folderId, 'notes');
    expect(locked.deletedAt, DateTime(2020));
    expect(locked.updatedAt.isAfter(DateTime(2020)), isTrue);
  });

  test('menu of a restored note offers no permanent deletion', () async {
    final note = Note(
      id: 'restored',
      title: 'Ripristinata',
      content: '',
      isDeleted: true,
      deletedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.upsertNote(note);
    await provider.restoreFromTrash(note.id);

    final current = await provider.fetchNote(note.id);
    expect(NoteActionMenu.actionsFor(current!), isNot(contains(NoteMenuAction.permanentlyDelete)));
  });

  test(
    'permanent deletion queues cloud deletion when note has no vault file',
    () async {
      final note = Note(
        id: 'no-file',
        title: 'Senza file',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.upsertNote(note);

      await provider.permanentlyDeleteNote(note.id);

      expect(await db.getNoteById(note.id), isNull);
      final actions = await db.getPendingSyncActions();
      expect(
        actions.where(
          (action) =>
              action['entity_id'] == note.id && action['action'] == 'delete',
        ),
        hasLength(1),
      );
    },
  );


  test('export message uses the file name returned by the save dialog', () {
    expect(
      NoteActions.savedFileName(Uri.file('/home/u/Documenti/Mia nota.md')),
      'Mia nota.md',
    );
    expect(
      NoteActions.savedFileName(
        Uri.parse('content://x/document/primary%3ADownload%2FAltra.md'),
      ),
      'Altra.md',
    );
    expect(
      NoteActions.savedFileName(Uri.parse('content://x/document/1234')),
      isNull,
    );
    expect(
      NoteActions.savedFileName(Uri.file('/home/u/Documenti/Diario.txt')),
      'Diario.txt',
    );
    expect(
      NoteActions.savedFileName(Uri.file('/home/u/Documenti/Idee')),
      isNull,
    );
  });

  testWidgets('failed export shows an error and creates no file', (tester) async {
    final original = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _FailingSavePicker();
    addTearDown(() => FilePickerPlatform.instance = original);
    final note = Note(
      id: 'export-fail',
      title: 'Esportata',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: SecurityService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => NoteActions.handle(
                  context,
                  note,
                  NoteMenuAction.export,
                ),
                child: const Text('Esporta'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Esporta'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Nota non esportata: impossibile scrivere il file nella posizione scelta.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('failed share shows an error and returns to idle', (tester) async {
    final original = SharePlatform.instance;
    SharePlatform.instance = _FailingSharePlatform();
    addTearDown(() => SharePlatform.instance = original);
    final note = Note(
      id: 'share-fail',
      title: 'Condivisa',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: SecurityService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => NoteActions.handle(
                  context,
                  note,
                  NoteMenuAction.share,
                ),
                child: const Text('Condividi'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Condividi'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Nota non condivisa: impossibile aprire il foglio di condivisione.',
      ),
      findsOneWidget,
    );
  });

}

class _FailingSavePicker extends FilePickerPlatform {
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    throw const FileSystemException('Cannot create file', '/read-only/Esportata.md');
  }
}

class _FailingSharePlatform extends SharePlatform {
  @override
  Future<ShareResult> share(ShareParams params) {
    throw StateError('Cannot open share sheet');
  }
}
