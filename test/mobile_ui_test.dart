import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/ui/mobile/mobile_keyboard_accessory_bar.dart';

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
  });
}
