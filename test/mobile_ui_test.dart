import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/models/folder_model.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/mobile/mobile_folders_screen.dart';
import 'package:open_notes/ui/mobile/mobile_keyboard_accessory_bar.dart';
import 'package:open_notes/ui/mobile/mobile_notes_list_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('MobileKeyboardAccessoryBar tests', () {
    testWidgets('renders all accessory tools and triggers callbacks', (WidgetTester tester) async {
      bool checklistTapped = false;
      bool tableTapped = false;
      bool drawingTapped = false;
      bool photoTapped = false;
      bool dismissTapped = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: MobileKeyboardAccessoryBar(
              onChecklist: () => checklistTapped = true,
              onTable: () => tableTapped = true,
              onDrawing: () => drawingTapped = true,
              onPhoto: () => photoTapped = true,
              onDismissKeyboard: () => dismissTapped = true,
            ),
          ),
        ),
      );

      // Verify widgets rendered
      expect(find.byIcon(CupertinoIcons.checkmark_circle), findsOneWidget);
      expect(find.text('Aa'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.table), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.pencil_outline), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.camera), findsOneWidget);
      expect(find.text('Fine'), findsOneWidget);

      // Tap checklist
      await tester.tap(find.byIcon(CupertinoIcons.checkmark_circle));
      expect(checklistTapped, isTrue);

      // Tap table
      await tester.tap(find.byIcon(CupertinoIcons.table));
      expect(tableTapped, isTrue);

      // Tap drawing
      await tester.tap(find.byIcon(CupertinoIcons.pencil_outline));
      expect(drawingTapped, isTrue);

      // Tap photo
      await tester.tap(find.byIcon(CupertinoIcons.camera));
      expect(photoTapped, isTrue);

      // Tap Done
      await tester.tap(find.text('Fine'));
      expect(dismissTapped, isTrue);
    });

    testWidgets('the Aa menu offers checklist, quote and monospace styles', (WidgetTester tester) async {
      final styles = <BlockType>[];

      // The sheet with every style is taller than the default 800x600 test view
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: MobileKeyboardAccessoryBar(onSelectBlockType: styles.add),
          ),
        ),
      );

      for (final label in ['Checklist', 'Citazione', 'Monospazio']) {
        await tester.tap(find.text('Aa'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      expect(styles, [BlockType.checklist, BlockType.quote, BlockType.code]);
    });
  });

  group('Mobile new-note button in trash', () {
    late DatabaseService dbService;
    late VaultService vaultService;
    late Directory tempDir;
    late NotesProvider provider;

    setUp(() async {
      dbService = DatabaseService();
      await dbService.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('mobile_ui_test_');
      vaultService = VaultService();
      await vaultService.init(customPath: tempDir.path);
      provider = NotesProvider(
        dbService: dbService,
        vaultService: vaultService,
        syncService: SyncService(dbService, vaultService),
      );
      await provider.init();
      provider.selectFolder(Folder.trashId);
      await provider.refreshNotes();
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    testWidgets('notes list hides new-note button while trash is open', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: CupertinoApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).push(CupertinoPageRoute<void>(
                    builder: (_) => MobileNotesListScreen(onNewNote: _noop),
                  ));
                });
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.square_pencil), findsNothing);
    });

    testWidgets('swiping a trashed note in the list does not delete it', (tester) async {
      final note = (await tester.runAsync(() async {
        final created = (await provider.createNote(initialTitle: 'Nota nel cestino'))!;
        await provider.moveToTrash(created.id);
        await provider.refreshNotes();
        return created;
      }))!;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: CupertinoApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).push(CupertinoPageRoute<void>(
                    builder: (_) => MobileNotesListScreen(onNewNote: _noop),
                  ));
                });
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.text('Nota nel cestino'), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(await tester.runAsync(() => provider.fetchNote(note.id)), isNotNull);
      expect(find.text('Nota nel cestino'), findsOneWidget);
    });

    testWidgets('folders screen hides new-note button while trash is open', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: CupertinoApp(
            home: MobileFoldersScreen(onNewNote: _noop),
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.square_pencil), findsNothing);
    });

    testWidgets('reopened notes list shows the search still filtering it', (tester) async {
      await tester.runAsync(() async {
        await provider.createNote(initialTitle: 'Alfa');
        await provider.createNote(initialTitle: 'Beta');
        provider.selectFolder(Folder.defaultNotesId);
        provider.setSearchQuery('Alfa');
        await provider.refreshNotes();
      });
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: CupertinoApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).push(CupertinoPageRoute<void>(
                    builder: (_) => MobileNotesListScreen(onNewNote: _noop),
                  ));
                });
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<CupertinoSearchTextField>(find.byType(CupertinoSearchTextField));
      expect(field.controller!.text, 'Alfa');
      expect(find.text('Beta'), findsNothing);
    });
  });
}

void _noop() {}
