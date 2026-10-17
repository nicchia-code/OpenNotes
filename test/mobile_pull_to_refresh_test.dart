import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/mobile/mobile_folders_screen.dart';
import 'package:open_notes/ui/mobile/mobile_notes_list_screen.dart';
import 'package:provider/provider.dart';

/// Stands in for a signed-in sync service: counts the full runs started by the refresh gesture.
/// While [runGate] is set, a run lasts until the gate completes.
class _RecordingSyncService extends SyncService {
  _RecordingSyncService(super.dbService, super.vaultService);

  int syncRuns = 0;
  Completer<void>? runGate;

  @override
  bool get isAuthenticated => true;

  @override
  Future<void> syncNow() {
    syncRuns++;
    return runGate?.future ?? Future<void>.value();
  }
}

void main() {
  group('Mobile pull to refresh', () {
    late DatabaseService dbService;
    late VaultService vaultService;
    late Directory tempDir;
    late NotesProvider provider;
    late _RecordingSyncService syncService;

    setUp(() async {
      dbService = DatabaseService();
      await dbService.init(inMemory: true);
      tempDir = await Directory.systemTemp.createTemp('mobile_pull_to_refresh_');
      vaultService = VaultService();
      await vaultService.init(customPath: tempDir.path);
      syncService = _RecordingSyncService(dbService, vaultService);
      provider = NotesProvider(
        dbService: dbService,
        vaultService: vaultService,
        syncService: syncService,
      );
      await provider.init();
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    Widget app(Widget home) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider<SyncService>.value(value: syncService),
        ],
        child: CupertinoApp(home: home),
      );
    }

    // The refresh spinner is part of a sliver that is offstage until it is pulled, so search offstage too.
    Finder spinner() => find.byType(CupertinoActivityIndicator, skipOffstage: false);

    testWidgets('pulling the folders screen starts one sync run and the spinner stays until it ends', (tester) async {
      await tester.pumpWidget(app(MobileFoldersScreen(onNewNote: _noop)));
      await tester.pump();
      expect(find.byType(CupertinoSliverRefreshControl, skipOffstage: false), findsOneWidget);

      syncService.runGate = Completer<void>();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(syncService.syncRuns, 1);
      expect(spinner(), findsWidgets, reason: 'the spinner stays while the run lasts');

      syncService.runGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(spinner(), findsNothing, reason: 'the spinner closes when the run ends');
    });

    testWidgets('pulling the notes list starts one sync run and the spinner stays until it ends', (tester) async {
      await tester.pumpWidget(
        app(
          Builder(
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
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CupertinoSliverRefreshControl, skipOffstage: false), findsOneWidget);

      syncService.runGate = Completer<void>();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(syncService.syncRuns, 1);
      expect(spinner(), findsWidgets, reason: 'the spinner stays while the run lasts');

      syncService.runGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(spinner(), findsNothing, reason: 'the spinner closes when the run ends');
    });
  });
}

void _noop() {}
