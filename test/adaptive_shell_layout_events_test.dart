import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/security_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/shell/adaptive_app_shell.dart';
import 'package:open_notes/ui/mobile/mobile_folders_screen.dart';
import 'package:open_notes/ui/mobile/mobile_notes_list_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  testWidgets('mobile navigation starts a fresh stack on each switch to mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late DatabaseService db;
    late VaultService vault;
    late SyncService sync;
    late NotesProvider provider;
    late Directory tempDir;

    await tester.runAsync(() async {
      db = DatabaseService();
      await db.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('layout_events_test_');
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: db),
          Provider.value(value: vault),
          ChangeNotifierProvider.value(value: sync),
          ChangeNotifierProvider.value(value: SecurityService()),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(home: Material(child: AdaptiveAppShell())),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(MobileNotesListScreen, skipOffstage: false),
      findsNothing,
    );

    // 679 px is below the threshold: the mobile stack starts with the notes list, folders below.
    tester.view.physicalSize = const Size(679, 900);
    await tester.pumpAndSettle();
    expect(find.byType(MobileNotesListScreen), findsOneWidget);
    expect(
      find.byType(MobileFoldersScreen, skipOffstage: false),
      findsOneWidget,
    );

    // The user goes deeper into the stack; a marker route stands in for the notes list.
    final navigator = tester.state<NavigatorState>(
      find
          .descendant(
            of: find.byType(AdaptiveAppShell),
            matching: find.byType(Navigator),
          )
          .first,
    );
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const Text('marker')),
    );
    await tester.pumpAndSettle();
    expect(find.text('marker'), findsOneWidget);

    // Still mobile while resizing: the stack is kept.
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();
    expect(find.text('marker'), findsOneWidget);

    // 680 px is the desktop width: the mobile stack is discarded.
    tester.view.physicalSize = const Size(680, 900);
    await tester.pumpAndSettle();
    expect(
      find.byType(MobileNotesListScreen, skipOffstage: false),
      findsNothing,
    );
    expect(find.text('marker'), findsNothing);

    // Mobile again after several width changes: a fresh stack starts from the notes list.
    tester.view.physicalSize = const Size(679, 900);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 900);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(679, 900);
    await tester.pumpAndSettle();
    expect(find.byType(MobileNotesListScreen), findsOneWidget);
    expect(find.text('marker'), findsNothing);
    await tester.runAsync(() => tempDir.delete(recursive: true));
  });
}
