import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/security_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/shell/adaptive_app_shell.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  testWidgets(
    'desktop editor column shows a remote version of the open note',
    (tester) async {
      // Below 960px the sidebar collapses, leaving notes list and editor.
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late DatabaseService db;
      late VaultService vault;
      late SyncService sync;
      late NotesProvider provider;
      late Directory tempDir;
      final note = Note(
        id: 'desktop-open-note',
        title: 'Nota',
        content: '# Nota\nTesto originale',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        db = DatabaseService();
        await db.init(inMemory: true);
        tempDir = await Directory.systemTemp.createTemp('desktop_shell_test_');
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
          child: const MaterialApp(
            home: Material(child: AdaptiveAppShell()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      bool editorShows(String text) => tester
          .widgetList<EditableText>(find.byType(EditableText))
          .any((e) => e.controller.text.contains(text));

      expect(editorShows('Testo originale'), isTrue);

      // A remote change reaches the local data and the list refreshes, as the
      // sync service does when it applies a cloud note.
      await tester.runAsync(() async {
        await db.upsertNote(
          note.copyWith(
            content: '# Nota\nTesto remoto unico',
            updatedAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
        );
        await provider.refreshNotes();
      });
      await tester.pumpAndSettle();

      expect(editorShows('Testo remoto unico'), isTrue);
      expect(editorShows('Testo originale'), isFalse);

      provider.dispose();
      await tester.runAsync(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
    },
  );

  testWidgets('desktop toolbar offers protection for a trashed note', (
    tester,
  ) async {
    // Below 960px the sidebar collapses, as in the test above.
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late DatabaseService db;
    late VaultService vault;
    late SyncService sync;
    late NotesProvider provider;
    late Directory tempDir;
    final note = Note(
      id: 'desktop-trashed-note',
      title: 'Nel cestino',
      content: '',
      isDeleted: true,
      deletedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.runAsync(() async {
      db = DatabaseService();
      await db.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('desktop_trash_test_');
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
      provider.selectFolder(Folder.trashId);
      await provider.refreshNotes();
      provider.selectNote(note.id);
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
        child: const MaterialApp(
          home: Material(child: AdaptiveAppShell()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Proteggi con Lucchetto'), findsOneWidget);

    provider.dispose();
    await tester.runAsync(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
  });

  testWidgets('desktop search field keeps the filter text when the sidebar toggles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The sidebar row overflows with the test font; that layout issue is not under test.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    late DatabaseService db;
    late VaultService vault;
    late SyncService sync;
    late NotesProvider provider;
    late Directory tempDir;
    final note = Note(
      id: 'search-note',
      title: 'Ricerca',
      content: 'Contenuto da cercare',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.runAsync(() async {
      db = DatabaseService();
      await db.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('desktop_search_test_');
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
        child: const MaterialApp(
          home: Material(child: AdaptiveAppShell()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(CupertinoSearchTextField), 'Contenuto');
    // The search refresh reads the database: let it finish in real time, outside the fake clock.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(provider.searchQuery, 'Contenuto');

    String fieldText() => tester
        .widget<CupertinoSearchTextField>(find.byType(CupertinoSearchTextField))
        .controller!
        .text;

    await tester.tap(find.byTooltip('Nascondi barra laterale'));
    await tester.pumpAndSettle();
    expect(fieldText(), 'Contenuto');

    await tester.tap(find.byTooltip('Mostra barra laterale'));
    await tester.pumpAndSettle();
    expect(fieldText(), 'Contenuto');
    expect(provider.searchQuery, 'Contenuto');

    provider.dispose();
    await tester.runAsync(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
  });

  testWidgets('desktop search field shows the active query when the layout switches to desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The sidebar row overflows with the test font; that layout issue is not under test.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    late DatabaseService db;
    late VaultService vault;
    late SyncService sync;
    late NotesProvider provider;
    late Directory tempDir;
    final note = Note(
      id: 'search-note',
      title: 'Ricerca',
      content: 'Contenuto da cercare',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.runAsync(() async {
      db = DatabaseService();
      await db.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('desktop_search_mount_test_');
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
      // The search was made in the mobile layout, before the desktop shell is mounted.
      provider.setSearchQuery('Contenuto');
      await provider.refreshNotes();
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
        child: const MaterialApp(
          home: Material(child: AdaptiveAppShell()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(provider.searchQuery, 'Contenuto');
    expect(
      tester
          .widget<CupertinoSearchTextField>(find.byType(CupertinoSearchTextField))
          .controller!
          .text,
      'Contenuto',
    );

    provider.dispose();
    await tester.runAsync(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });
  });
}
