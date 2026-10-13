import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/apple_theme.dart';

/// Size in logical pixels of the exported image. Strokes are stored in these
/// coordinates and the on-screen canvas scales them to its own width, so the
/// stroke widths and the exported image are the same whatever the screen size.
const _canvasSize = Size(800, 600);

/// Freehand drawing canvas inspired by Apple Pencil drawing in Apple Notes.
class ApplePencilCanvas extends StatefulWidget {
  final Future<void> Function(List<int> pngBytes) onSave;

  const ApplePencilCanvas({super.key, required this.onSave});

  @override
  State<ApplePencilCanvas> createState() => _ApplePencilCanvasState();
}

class _DrawnPoint {
  final Offset offset;
  final Paint paint;
  _DrawnPoint(this.offset, this.paint);
}

class _ApplePencilCanvasState extends State<ApplePencilCanvas> {
  final List<List<_DrawnPoint>> _lines = [];
  List<_DrawnPoint> _currentLine = [];

  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;

  final List<Color> _palette = const [
    Colors.black,
    AppleTheme.accentYellow,
    Color(0xFF007AFF), // Apple Blue
    Color(0xFF34C759), // Apple Green
    Color(0xFFFF3B30), // Apple Red
    Color(0xFFAF52DE), // Apple Purple
    Color(0xFF8E8E93), // Apple Grey
  ];

  Paint _createPaint() {
    return Paint()
      ..color = _isEraser ? Colors.white : _selectedColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = _isEraser ? 20.0 : _strokeWidth
      ..blendMode = _isEraser ? BlendMode.clear : BlendMode.srcOver;
  }

  bool _saving = false;

  /// Saves the drawing once. While the save runs the canvas is locked: taps on
  /// "Fine" are ignored, and drawing, tools, "Annulla" and system back do nothing,
  /// so the saved image is exactly what was on screen.
  Future<void> _exportCanvas() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final png = await _renderPng();
      await widget.onSave(png);
    } catch (_) {
      if (mounted) {
        // Failed save unlocks the canvas and returns it to the Pen tool.
        setState(() {
          _saving = false;
          _isEraser = false;
        });
        await _showSaveError();
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<Uint8List> _renderPng() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = _canvasSize;

    // Same painter as the screen, so the export matches what the user saw,
    // including dots left by taps. The eraser clears to transparent and the
    // white background fills what the strokes left empty.
    _CanvasPainter(_lines).paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('PNG export returned no data');
    return byteData.buffer.asUint8List();
  }

  Future<void> _showSaveError() {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Disegno non salvato'),
        content: const Text(
          'Il disegno non è stato salvato tra gli allegati. La tela resta aperta: puoi riprovare o annullare.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_saving,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Disegno', style: TextStyle(fontWeight: FontWeight.w600)),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Annulla', style: TextStyle(color: CupertinoColors.systemGrey)),
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text('Fine', style: TextStyle(fontWeight: FontWeight.bold, color: AppleTheme.adaptiveAccent(context))),
            onPressed: _exportCanvas,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawing Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppleTheme.darkSidebar : AppleTheme.lightSidebar,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppleTheme.darkDivider : AppleTheme.lightDivider,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Palette
                    ..._palette.map((color) {
                      final isSelected = !_isEraser && _selectedColor == color;
                      return GestureDetector(
                        onTap: _saving
                            ? null
                            : () {
                                setState(() {
                                  _selectedColor = color;
                                  _isEraser = false;
                                });
                              },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppleTheme.accentYellow : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
                                : null,
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    // Eraser
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: _saving ? null : () => setState(() => _isEraser = !_isEraser),
                      child: Icon(
                        CupertinoIcons.bandage,
                        color: _isEraser ? AppleTheme.accentYellow : CupertinoColors.systemGrey,
                        size: 22,
                      ),
                    ),
                    // Undo
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: _lines.isNotEmpty && !_saving
                          ? () => setState(() => _lines.removeLast())
                          : null,
                      child: const Icon(CupertinoIcons.arrow_uturn_left, size: 20),
                    ),
                    // Clear
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: _saving ? null : () => setState(() => _lines.clear()),
                      child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 20),
                    ),
                  ],
                ),
              ),
              // Canvas area: 4:3 (the image shape), as wide as the area allows. On
              // short screens the height is the limit, so it is centred with side margins.
              Expanded(
                child: Container(
                  color: const Color(0xFFE5E5EA),
                  alignment: Alignment.center,
                  child: AspectRatio(
                    aspectRatio: _canvasSize.width / _canvasSize.height,
                    child: LayoutBuilder(
                      builder: (context, constraints) => _buildCanvas(constraints.maxWidth / _canvasSize.width),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The drawing surface. Touch positions are converted to [_canvasSize]
  /// coordinates by dividing by [scale] (on-screen pixels per image pixel).
  /// While saving, the surface takes no gestures.
  Widget _buildCanvas(double scale) {
    return ColoredBox(
      color: Colors.white,
      child: GestureDetector(
        onPanStart: _saving
            ? null
            : (details) {
                setState(() {
                  _currentLine = [_DrawnPoint(details.localPosition / scale, _createPaint())];
                  _lines.add(_currentLine);
                });
              },
        onPanUpdate: _saving
            ? null
            : (details) {
                setState(() {
                  _currentLine.add(_DrawnPoint(details.localPosition / scale, _createPaint()));
                });
              },
        onPanEnd: _saving
            ? null
            : (_) {
                setState(() {});
              },
        onTapUp: _saving
            ? null
            : (details) {
                // A tap without movement is a line of one point: it leaves a dot.
                setState(() {
                  _lines.add([_DrawnPoint(details.localPosition / scale, _createPaint())]);
                });
              },
        child: CustomPaint(painter: _CanvasPainter(_lines)),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<_DrawnPoint>> lines;
  _CanvasPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _canvasSize.width);
    // Same as the export: the eraser clears to transparent inside a layer, and
    // white is then filled behind what the strokes left empty. Without the
    // layer, clearing would also remove the white background of the canvas.
    final bounds = Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height);
    canvas.saveLayer(bounds, Paint());
    for (final line in lines) {
      if (line.length == 1) {
        canvas.drawPoints(ui.PointMode.points, [line[0].offset], line[0].paint);
      }
      for (int i = 0; i < line.length - 1; i++) {
        canvas.drawLine(line[i].offset, line[i + 1].offset, line[i].paint);
      }
    }
    canvas.drawRect(bounds, Paint()
      ..color = Colors.white
      ..blendMode = BlendMode.dstOver);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
