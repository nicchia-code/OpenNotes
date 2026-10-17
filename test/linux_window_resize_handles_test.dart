import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/ui/shell/linux_window_resize_handles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const windowChannel = MethodChannel('window_manager');
  const tiledChannel = MethodChannel('opennotes/window');

  late List<MethodCall> calls;

  void mockWindowState({required bool maximized, required bool tiled}) {
    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(windowChannel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'isMaximized' => maximized,
        'isFullScreen' => false,
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(tiledChannel, (call) async => tiled);
  }

  Future<void> pumpHandles(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LinuxWindowResizeHandles(child: SizedBox.expand()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pressAt(WidgetTester tester, Offset position) async {
    final gesture = await tester.startGesture(
      position,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  List<MethodCall> resizeCalls() =>
      calls.where((call) => call.method == 'startResizing').toList();

  setUp(() => calls = []);

  tearDown(() {
    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(windowChannel, null);
    messenger.setMockMethodCallHandler(tiledChannel, null);
  });

  testWidgets(
    'a press on the left edge starts the native resize from that edge',
    skip: !Platform.isLinux,
    (tester) async {
      mockWindowState(maximized: false, tiled: false);
      await pumpHandles(tester);

      await pressAt(tester, const Offset(2, 300));

      expect(resizeCalls(), hasLength(1));
      expect(resizeCalls().single.arguments['resizeEdge'], 'left');
    },
  );

  testWidgets(
    'a press on the top-left corner starts a diagonal resize',
    skip: !Platform.isLinux,
    (tester) async {
      mockWindowState(maximized: false, tiled: false);
      await pumpHandles(tester);

      await pressAt(tester, const Offset(2, 2));

      expect(resizeCalls(), hasLength(1));
      expect(resizeCalls().single.arguments['resizeEdge'], 'topLeft');
    },
  );

  testWidgets(
    'maximized or tiled window has no resize strips',
    skip: !Platform.isLinux,
    (tester) async {
      mockWindowState(maximized: true, tiled: false);
      await pumpHandles(tester);
      await pressAt(tester, const Offset(2, 300));
      expect(resizeCalls(), isEmpty);

      mockWindowState(maximized: false, tiled: true);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpHandles(tester);
      await pressAt(tester, const Offset(2, 300));
      expect(resizeCalls(), isEmpty);
    },
  );
}
