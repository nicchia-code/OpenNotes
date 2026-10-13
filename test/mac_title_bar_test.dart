import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/shell/mac_title_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;
  late VaultService vault;
  late NotesProvider provider;
  late Directory tempDir;

  setUp(() async {
    db = DatabaseService();
    await db.init(inMemory: true);
    tempDir = await Directory.systemTemp.createTemp('mac_title_bar_test_');
    vault = VaultService();
    await vault.init(customPath: tempDir.path);
    provider = NotesProvider(
      dbService: db,
      vaultService: vault,
      syncService: SyncService(db, vault),
    );
    await provider.init();
  });

  tearDown(() async {
    provider.dispose();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets(
    'draws close, minimize and maximize buttons only on Linux and Windows',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: MacTitleBar(
                isSidebarVisible: true,
                onToggleSidebar: () {},
              ),
            ),
          ),
        ),
      );

      final drawsControls = Platform.isLinux || Platform.isWindows;
      expect(find.byTooltip('Chiudi'), drawsControls ? findsOneWidget : findsNothing);
      expect(
        find.byTooltip('Riduci a icona'),
        drawsControls ? findsOneWidget : findsNothing,
      );
      expect(
        find.byTooltip('Ingrandisci'),
        drawsControls ? findsOneWidget : findsNothing,
      );
    },
  );

  testWidgets(
    'double-click on the top bar toggles the maximized state on desktop',
    skip: !(Platform.isLinux || Platform.isWindows || Platform.isMacOS),
    (tester) async {
      final calls = <String>[];
      var maximized = false;
      const channel = MethodChannel('window_manager');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'isMaximized') return maximized;
        if (call.method == 'maximize') maximized = true;
        if (call.method == 'unmaximize') maximized = false;
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: MacTitleBar(
                isSidebarVisible: true,
                onToggleSidebar: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MacTitleBar));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(MacTitleBar));
      await tester.pumpAndSettle();
      expect(calls, contains('maximize'));
      expect(maximized, isTrue);

      calls.clear();
      await tester.tap(find.byType(MacTitleBar));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(MacTitleBar));
      await tester.pumpAndSettle();
      expect(calls, contains('unmaximize'));
      expect(maximized, isFalse);
    },
  );

  testWidgets(
    'the red close button writes the waiting edit before closing the window',
    skip: !(Platform.isLinux || Platform.isWindows),
    (tester) async {
      final closedWith = <String?>[];
      const channel = MethodChannel('window_manager');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        // Reads the stored note at the moment the window is asked to close
        if (call.method == 'close') {
          closedWith.add((await db.getNoteById('a'))?.content);
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: MacTitleBar(
                isSidebarVisible: true,
                onToggleSidebar: () {},
              ),
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        final now = DateTime.now();
        await db.upsertNote(
          Note(id: 'a', title: 'A', content: 'A', createdAt: now, updatedAt: now),
        );
        // An edit only takes effect on a note in the loaded list: load it first.
        await provider.refreshNotes();
        provider.updateNoteContent('a', 'A edited');
      });
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Chiudi'));
        // The close runs after the real async write: wait for it without a fixed delay
        for (var i = 0; i < 500 && closedWith.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });

      expect(closedWith, ['A edited']);
    },
  );
}
