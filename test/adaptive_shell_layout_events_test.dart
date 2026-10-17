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
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  testWidgets(
    'layout emits SWITCHED_TO_MOBILE and SWITCHED_TO_DESKTOP only when crossing 680 px',
    (tester) async {
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

      final events = <DesktopLayoutEvent>[];

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
            home: Material(
              child: AdaptiveAppShell(onLayoutEvent: events.add),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starting on desktop: no switch has happened yet.
      expect(events, isEmpty);

      // 679 px is below the threshold: the mobile navigation is announced.
      tester.view.physicalSize = const Size(679, 900);
      await tester.pumpAndSettle();
      expect(events, [DesktopLayoutEvent.switchedToMobile]);

      // Still mobile: no new event.
      tester.view.physicalSize = const Size(600, 900);
      await tester.pumpAndSettle();
      expect(events, [DesktopLayoutEvent.switchedToMobile]);

      // 680 px is the first desktop width: the desktop return is announced.
      tester.view.physicalSize = const Size(680, 900);
      await tester.pumpAndSettle();
      expect(events, [
        DesktopLayoutEvent.switchedToMobile,
        DesktopLayoutEvent.switchedToDesktop,
      ]);

      // Staying on desktop while resizing: no new event.
      tester.view.physicalSize = const Size(800, 900);
      await tester.pumpAndSettle();
      expect(events, [
        DesktopLayoutEvent.switchedToMobile,
        DesktopLayoutEvent.switchedToDesktop,
      ]);

      await tester.runAsync(() => tempDir.delete(recursive: true));
    },
  );
}
