import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/ui/drawing/apple_pencil_canvas.dart';
import 'package:open_notes/ui/theme/apple_theme.dart';

void main() {
  testWidgets('exported drawing keeps white where the eraser passed', (tester) async {
    Uint8List? saved;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => ApplePencilCanvas(
                  onSave: (bytes) async {
                    saved = Uint8List.fromList(bytes);
                  },
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final canvas = find.byType(CustomPaint).last;
    final origin = tester.getTopLeft(canvas);
    // Screen pixels per image pixel: the canvas is fitted to the screen width.
    final scale = tester.getSize(canvas).width / 800;
    Offset at(double x, double y) => origin + Offset(x, y) * scale;

    // Black pen stroke across y = 300, from x = 50 to x = 350.
    await tester.dragFrom(at(50, 300), Offset(300, 0) * scale);
    await tester.pump();

    // Eraser over x = 150..250 on the same line.
    await tester.tap(find.byIcon(CupertinoIcons.bandage));
    await tester.pump();
    await tester.dragFrom(at(150, 300), Offset(100, 0) * scale);
    await tester.pump();

    // Pen stroke at the right edge of the image, reached by touch.
    await tester.tap(find.byIcon(CupertinoIcons.bandage));
    await tester.pump();
    await tester.dragFrom(at(700, 100), Offset(99, 0) * scale);
    await tester.pump();

    await tester.tap(find.text('Fine'));
    await tester.runAsync(() async {
      for (int i = 0; i < 100 && saved == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(saved, isNotNull);
    final pixels = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(saved!);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data!, frame.image.width, frame.image.height);
    });
    final (bytes, width, height) = pixels!;
    expect((width, height), (800, 600));

    final rgba = bytes.buffer.asUint8List();
    List<int> pixelAt(int x, int y) {
      final i = (y * width + x) * 4;
      return rgba.sublist(i, i + 4);
    }

    // Erased area: white and opaque, not transparent.
    expect(pixelAt(200, 300), [255, 255, 255, 255]);
    // Pen stroke outside the eraser: black.
    expect(pixelAt(300, 300).sublist(0, 3), [0, 0, 0]);
    // Pen stroke at the right edge: reached by touch and exported.
    expect(pixelAt(750, 100).sublist(0, 3), [0, 0, 0]);
    // Empty area: white.
    expect(pixelAt(500, 500), [255, 255, 255, 255]);
  });

  testWidgets('failed save keeps the canvas open and shows an error', (tester) async {
    var attempts = 0;
    var closed = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => Navigator.of(context)
                .push(
                  CupertinoPageRoute(
                    builder: (_) => ApplePencilCanvas(
                      onSave: (bytes) async {
                        attempts++;
                        throw StateError('disk full');
                      },
                    ),
                  ),
                )
                .then((_) => closed = true),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fine'));
    await tester.runAsync(() async {
      for (int i = 0; i < 100 && attempts == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(closed, isFalse);
    expect(find.text('Disegno non salvato'), findsOneWidget);
    expect(find.byType(ApplePencilCanvas), findsOneWidget);
  });

  testWidgets('failed save returns the canvas to the Pen tool', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: ApplePencilCanvas(
          onSave: (bytes) async {
            throw StateError('disk full');
          },
        ),
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.bandage));
    await tester.pump();
    expect(tester.widget<Icon>(find.byIcon(CupertinoIcons.bandage)).color, AppleTheme.accentYellow);

    await tester.tap(find.text('Fine'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Disegno non salvato'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(CupertinoIcons.bandage)).color, CupertinoColors.systemGrey);
  });

  testWidgets('on-screen canvas stays white where the eraser passed in dark theme', (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => RepaintBoundary(
                  key: boundaryKey,
                  child: ApplePencilCanvas(onSave: (_) async {}),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final canvas = find.byType(CustomPaint).last;
    final origin = tester.getTopLeft(canvas);
    final scale = tester.getSize(canvas).width / 800;
    Offset at(double x, double y) => origin + Offset(x, y) * scale;

    // Black pen stroke across y = 300, then the eraser over x = 150..250.
    await tester.dragFrom(at(50, 300), Offset(300, 0) * scale);
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.bandage));
    await tester.pump();
    await tester.dragFrom(at(150, 300), Offset(100, 0) * scale);
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    final boundaryOrigin = tester.getTopLeft(find.byKey(boundaryKey));
    final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
    final data = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
    final rgba = data.buffer.asUint8List();
    List<int> pixelAt(Offset screen) {
      final p = screen - boundaryOrigin;
      final i = (p.dy.round() * image.width + p.dx.round()) * 4;
      return rgba.sublist(i, i + 4);
    }

    // Erased area shows white, not the dark page background.
    expect(pixelAt(at(200, 300)), [255, 255, 255, 255]);
    // Pen stroke outside the eraser stays dark (edges are blended at this size).
    expect(pixelAt(at(300, 300))[0], lessThan(128));
  });

  testWidgets('tapping Fine twice during a save saves the drawing once', (tester) async {
    final saveCompleter = Completer<void>();
    var saveCalls = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => ApplePencilCanvas(
                  onSave: (bytes) {
                    saveCalls++;
                    return saveCompleter.future;
                  },
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The export encodes the image asynchronously in the real engine, so the
    // taps are followed by real time for it to reach onSave.
    await tester.tap(find.text('Fine'));
    await tester.tap(find.text('Fine'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    expect(saveCalls, 1);

    saveCompleter.complete();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(saveCalls, 1);
  });

  testWidgets('Annulla and system back do not close the canvas while saving', (tester) async {
    final saveCompleter = Completer<void>();

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => ApplePencilCanvas(onSave: (bytes) => saveCompleter.future),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fine'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ApplePencilCanvas), findsOneWidget);

    saveCompleter.complete();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.byType(ApplePencilCanvas), findsNothing);
  });

  testWidgets('short screen keeps the 4:3 canvas centred and on screen', (tester) async {
    tester.view.physicalSize = const Size(900, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(CupertinoApp(home: ApplePencilCanvas(onSave: (_) async {})));
    await tester.pumpAndSettle();

    final aspect = find.descendant(
      of: find.byType(ApplePencilCanvas),
      matching: find.byType(AspectRatio),
    );
    final rect = tester.getRect(aspect);
    // Shape stays 4:3.
    expect(rect.width / rect.height, closeTo(4 / 3, 0.01));
    // Height is the limit: narrower than the screen, centred, with margins on both sides.
    expect(rect.width, lessThan(900));
    expect(rect.center.dx, closeTo(450, 0.5));
    // Entirely on screen, so nothing needs scrolling.
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(400));
  });

  testWidgets('a single tap leaves a dot with the pen and erases one with the eraser', (tester) async {
    Uint8List? saved;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => ApplePencilCanvas(
                  onSave: (bytes) async {
                    saved = Uint8List.fromList(bytes);
                  },
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final canvas = find.byType(CustomPaint).last;
    final origin = tester.getTopLeft(canvas);
    final scale = tester.getSize(canvas).width / 800;
    Offset at(double x, double y) => origin + Offset(x, y) * scale;

    // Black stroke across y = 100, from x = 50 to x = 350.
    await tester.dragFrom(at(50, 100), Offset(300, 0) * scale);
    await tester.pump();
    // Pen tap alone at (500, 450).
    await tester.tapAt(at(500, 450));
    await tester.pump();
    // Eraser tap on the stroke at (200, 100).
    await tester.tap(find.byIcon(CupertinoIcons.bandage));
    await tester.pump();
    await tester.tapAt(at(200, 100));
    await tester.pump();

    await tester.tap(find.text('Fine'));
    await tester.runAsync(() async {
      for (int i = 0; i < 100 && saved == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(saved, isNotNull);
    final pixels = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(saved!);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data!, frame.image.width, frame.image.height);
    });
    final (bytes, width, height) = pixels!;
    final rgba = bytes.buffer.asUint8List();
    List<int> pixelAt(int x, int y) {
      final i = (y * width + x) * 4;
      return rgba.sublist(i, i + 4);
    }

    // Dot left by the pen tap: black.
    expect(pixelAt(500, 450).sublist(0, 3), [0, 0, 0]);
    // Stroke outside the eraser tap: still black.
    expect(pixelAt(300, 100).sublist(0, 3), [0, 0, 0]);
    // Eraser tap: the stroke is cleared to white at that point.
    expect(pixelAt(200, 100), [255, 255, 255, 255]);
  });
}
