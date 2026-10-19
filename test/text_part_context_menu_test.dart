import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/ui/editor/clipboard_image_reader.dart';
import 'package:open_notes/ui/editor/text_part_context_menu.dart';

final _image = ClipboardImage(
  bytes: Uint8List.fromList([1, 2, 3]),
  extension: 'png',
);

void _mockClipboardText(String? text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') {
      return text == null ? null : <String, dynamic>{'text': text};
    }
    return null;
  });
}

Future<void> _pumpTextField(
  WidgetTester tester,
  TextEditingController controller, {
  required void Function(ClipboardImage image) onPasteImage,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: TextField(
            controller: controller,
            contextMenuBuilder: (context, state) => TextPartContextMenu(
              editableTextState: state,
              onPasteImage: onPasteImage,
              readImage: () async => _image,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Focuses the field, selects its text and shows the context menu.
Future<void> _openContextMenu(
  WidgetTester tester,
  TextEditingController controller,
) async {
  await tester.tap(find.byType(TextField));
  await tester.pump();
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );
  await tester.pump();
  tester
      .state<EditableTextState>(find.byType(EditableText))
      .showToolbar();
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'clipboard with only an image: the menu offers Incolla, which pastes '
    'the image',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      _mockClipboardText(null);
      final controller = TextEditingController(text: 'testo');
      ClipboardImage? pasted;
      await _pumpTextField(
        tester,
        controller,
        onPasteImage: (image) => pasted = image,
      );

      await _openContextMenu(tester, controller);

      expect(find.text('Incolla'), findsOneWidget);
      await tester.tap(find.text('Incolla'));
      await tester.pumpAndSettle();
      expect(pasted, same(_image));
    },
  );

  testWidgets(
    'clipboard with text and an image: the menu keeps the text paste item '
    'only',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      _mockClipboardText('testo');
      final controller = TextEditingController(text: 'testo');
      ClipboardImage? pasted;
      await _pumpTextField(
        tester,
        controller,
        onPasteImage: (image) => pasted = image,
      );

      await _openContextMenu(tester, controller);

      expect(find.text('Incolla'), findsOneWidget);
      expect(pasted, isNull);
    },
  );
}
