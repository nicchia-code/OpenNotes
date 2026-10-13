import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/security_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/editor/rich_text_editing_controller.dart';
import 'package:open_notes/ui/mobile/mobile_note_editor_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  testWidgets(
    'mobile editor keeps the last received version after the note leaves the list',
    (tester) async {
      late DatabaseService db;
      late VaultService vault;
      late SyncService sync;
      late NotesProvider provider;
      late Directory tempDir;
      final note = Note(
        id: 'mobile-stale-note',
        title: 'Nota',
        content: '# Nota\nTesto originale',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        db = DatabaseService();
        await db.init(inMemory: true);
        tempDir = await Directory.systemTemp.createTemp('mobile_editor_test_');
        vault = VaultService();
        await vault.init(customPath: tempDir.path);
        sync = SyncService(db, vault);
        provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        await db.upsertNote(note);
        await provider.init();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: SecurityService()),
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: Material(child: MobileNoteEditorScreen(note: note)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Edit in the session, then wait for the debounced save to complete.
      await tester.runAsync(() async {
        provider.updateNoteContent(
          note.id,
          '# Nota\nTesto modificato in sessione',
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await tester.pumpAndSettle();

      // Trashing the note removes it from the current list.
      await tester.runAsync(() => provider.moveToTrash(note.id));
      await tester.pumpAndSettle();

      final ctrl =
          tester.widget<TextField>(find.byType(TextField)).controller
              as RichTextEditingController;
      expect(ctrl.text, contains('Testo modificato in sessione'));
      expect(ctrl.text, isNot(contains('Testo originale')));

      provider.dispose();
      await tester.runAsync(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
    },
  );

  testWidgets(
    'mobile editor stays open when its note leaves the list and keeps the edit',
    (tester) async {
      late DatabaseService db;
      late VaultService vault;
      late SyncService sync;
      late NotesProvider provider;
      late Directory tempDir;
      final note = Note(
        id: 'mobile-closing-note',
        title: 'Nota',
        content: '# Nota\nTesto originale',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        db = DatabaseService();
        await db.init(inMemory: true);
        tempDir = await Directory.systemTemp.createTemp('mobile_editor_close_');
        vault = VaultService();
        await vault.init(customPath: tempDir.path);
        sync = SyncService(db, vault);
        provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        await db.upsertNote(note);
        await provider.init();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: SecurityService()),
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Material(
                        child: MobileNoteEditorScreen(note: note),
                      ),
                    ),
                  ),
                  child: const Text('Apri'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();
      expect(find.byType(MobileNoteEditorScreen), findsOneWidget);

      // Edit in the session, then wait for the debounced save to complete.
      await tester.runAsync(() async {
        provider.updateNoteContent(
          note.id,
          '# Nota\nTesto modificato in sessione',
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await tester.pumpAndSettle();

      // Trashing the note removes it from the current list: the editor stays open.
      await tester.runAsync(() => provider.moveToTrash(note.id));
      await tester.pumpAndSettle();

      expect(find.byType(MobileNoteEditorScreen), findsOneWidget);
      final saved = await tester.runAsync(() => db.getNoteById(note.id));
      expect(saved!.content, contains('Testo modificato in sessione'));

      provider.dispose();
      await tester.runAsync(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
    },
  );


  testWidgets(
    'lock button asks for the PIN to unlock a note that left the list',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      late DatabaseService db;
      late VaultService vault;
      late SyncService sync;
      late NotesProvider provider;
      late SecurityService security;
      late Directory tempDir;
      final note = Note(
        id: 'mobile-lock-stale-note',
        title: 'Nota',
        content: '# Nota\nTesto',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        db = DatabaseService();
        await db.init(inMemory: true);
        tempDir = await Directory.systemTemp.createTemp('mobile_editor_lock_');
        vault = VaultService();
        await vault.init(customPath: tempDir.path);
        sync = SyncService(db, vault);
        security = SecurityService();
        await security.init();
        await security.setMasterPin('1234');
        provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        await db.upsertNote(note);
        await provider.init();
        // The note is protected after the editor was opened from the list.
        await provider.toggleLock(note.id);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: Material(child: MobileNoteEditorScreen(note: note)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trashing removes the note from the list; the editor keeps its last version.
      await tester.runAsync(() => provider.moveToTrash(note.id));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.lock_fill));
      await tester.pumpAndSettle();

      // Unlocking must ask for the PIN instead of removing the lock silently.
      expect(find.text('Nota Protetta'), findsOneWidget);
      final stillLocked = await tester.runAsync(() => db.getNoteById(note.id));
      expect(stillLocked?.isLocked, isTrue);

      provider.dispose();
      await tester.runAsync(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
    },
  );

  testWidgets(
    'protected editor stays on the placeholder after the note is trashed',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      late DatabaseService db;
      late VaultService vault;
      late SyncService sync;
      late NotesProvider provider;
      late SecurityService security;
      late Directory tempDir;
      final note = Note(
        id: 'mobile-protected-trash-note',
        title: 'Nota',
        content: '# Nota\nTesto',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        db = DatabaseService();
        await db.init(inMemory: true);
        tempDir = await Directory.systemTemp.createTemp(
          'mobile_editor_protected_trash_',
        );
        vault = VaultService();
        await vault.init(customPath: tempDir.path);
        sync = SyncService(db, vault);
        security = SecurityService();
        await security.init();
        await security.setMasterPin('1234');
        provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        await db.upsertNote(note);
        await provider.init();
        await provider.toggleLock(note.id);
      });
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            // A Scaffold above the editor: trashing shows a snackbar.
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        Scaffold(body: MobileNoteEditorScreen(note: note)),
                  ),
                ),
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();
      expect(find.text('Questa nota è protetta'), findsOneWidget);

      // Trash from the more menu: the Model keeps a Protected editor open.
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis_circle));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Sposta nel cestino'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      final trashed = await tester.runAsync(() => db.getNoteById(note.id));
      expect(trashed?.isDeleted, isTrue);
      expect(find.byType(MobileNoteEditorScreen), findsOneWidget);
      expect(find.text('Questa nota è protetta'), findsOneWidget);

      provider.dispose();
      await tester.runAsync(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
    },
  );

  testWidgets('mobile editor hides the share button for a trashed note', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late DatabaseService db;
    late VaultService vault;
    late SyncService sync;
    late NotesProvider provider;
    late Directory tempDir;
    final note = Note(
      id: 'mobile-trashed-note',
      title: 'Nota',
      content: '# Nota\nTesto',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: true,
      deletedAt: DateTime.now(),
    );

    await tester.runAsync(() async {
      db = DatabaseService();
      await db.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('mobile_editor_trash_');
      vault = VaultService();
      await vault.init(customPath: tempDir.path);
      sync = SyncService(db, vault);
      provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: sync,
      );
      await db.upsertNote(note);
      await provider.init();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: db),
          Provider.value(value: vault),
          ChangeNotifierProvider.value(value: sync),
          ChangeNotifierProvider.value(value: SecurityService()),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          home: Material(child: MobileNoteEditorScreen(note: note)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A trashed note cannot be shared: the share button is not shown.
    expect(find.byIcon(CupertinoIcons.share), findsNothing);

    provider.dispose();
    await tester.runAsync(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
  });

  testWidgets('more menu duplicates the text typed but not yet saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late DatabaseService db;
    late VaultService vault;
    late SyncService sync;
    late NotesProvider provider;
    late Directory tempDir;
    final note = Note(
      id: 'mobile-menu-note',
      title: 'Nota',
      content: '# Nota\nTesto originale',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.runAsync(() async {
      db = DatabaseService();
      await db.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('mobile_menu_test_');
      vault = VaultService();
      await vault.init(customPath: tempDir.path);
      sync = SyncService(db, vault);
      provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: sync,
      );
      await db.upsertNote(note);
      await provider.init();
    });
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: db),
          Provider.value(value: vault),
          ChangeNotifierProvider.value(value: sync),
          ChangeNotifierProvider.value(value: SecurityService()),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          // Material around the whole navigator: the duplicate opens a second editor route.
          builder: (context, child) => Material(child: child),
          home: MobileNoteEditorScreen(note: note),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Type, then open the more menu before the 400 ms save wait is over.
    await tester.runAsync(() async {
      provider.updateNoteContent(note.id, '# Nota\nTesto appena digitato');
    });
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis_circle));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Duplica'));
      // The duplicate runs database and file I/O in real time.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    final notes = await tester.runAsync(() => db.getNotes()) ?? [];
    final copy = notes.firstWhere((n) => n.id != note.id);
    expect(copy.content, contains('Testo appena digitato'));
    expect(copy.content, isNot(contains('Testo originale')));

    provider.dispose();
    await tester.runAsync(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
  });
}
