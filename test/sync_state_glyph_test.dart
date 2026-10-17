import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/ui/sync/sync_state_glyph.dart';

void main() {
  Future<void> pump(WidgetTester tester, SyncRunState state) => tester.pumpWidget(
        CupertinoApp(
          home: Center(child: SyncStateGlyph(state: state, color: CupertinoColors.black)),
        ),
      );

  testWidgets('each sync state draws a cloud with its own badge from CupertinoIcons', (tester) async {
    await pump(tester, SyncRunState.idle);
    expect(find.byIcon(CupertinoIcons.cloud), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: SyncStateGlyph(state: SyncRunState.idle, color: CupertinoColors.black, setAside: true),
        ),
      ),
    );
    expect(find.byIcon(CupertinoIcons.exclamationmark), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsNothing);
    await pump(tester, SyncRunState.waitingToRetry);
    expect(find.byIcon(CupertinoIcons.cloud), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.exclamationmark), findsOneWidget);

    await pump(tester, SyncRunState.offline);
    expect(find.byIcon(CupertinoIcons.cloud), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.slash_circle_fill), findsOneWidget);
  });

  testWidgets('a running sync shows a spinner instead of the cloud', (tester) async {
    await pump(tester, SyncRunState.running);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.cloud), findsNothing);
  });
}
