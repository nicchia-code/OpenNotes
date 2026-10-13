import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/security_service.dart';
import 'package:open_notes/ui/security/lock_note_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('master PIN length counts characters, not UTF-16 code units', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final security = SecurityService();
    await security.init();

    late BuildContext appContext;
    await tester.pumpWidget(CupertinoApp(
      home: Builder(builder: (context) {
        appContext = context;
        return const SizedBox();
      }),
    ));

    final result = LockNoteDialog.showSetPinDialog(appContext, security);
    await tester.pumpAndSettle();
    final fields = find.byType(CupertinoTextField);

    // Three emoji: 3 characters but 6 UTF-16 code units. Must be rejected.
    await tester.enterText(fields.at(0), '😀😀😀');
    await tester.enterText(fields.at(1), '😀😀😀');
    await tester.tap(find.text('Imposta PIN'));
    await tester.pumpAndSettle();
    expect(find.text('Il PIN deve avere almeno 4 cifre.'), findsOneWidget);
    expect(security.hasMasterPin, isFalse);

    // Four emoji: 4 characters, 8 code units. Must be accepted and saved.
    await tester.enterText(fields.at(0), '😀😀😀😀');
    await tester.enterText(fields.at(1), '😀😀😀😀');
    await tester.tap(find.text('Imposta PIN'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(security.hasMasterPin, isTrue);
    expect(await security.verifyPin('😀😀😀😀'), isTrue);
  });
}
