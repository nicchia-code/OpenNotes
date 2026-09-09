import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/apple_theme.dart';

/// Freehand drawing canvas inspired by Apple Pencil drawing in Apple Notes.
class ApplePencilCanvas extends StatefulWidget {
  final Function(List<int> pngBytes) onSave;

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

  Future<void> _exportCanvas() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(800, 600);

    // Draw white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Render strokes
    for (final line in _lines) {
      for (int i = 0; i < line.length - 1; i++) {
        canvas.drawLine(line[i].offset, line[i + 1].offset, line[i].paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      widget.onSave(byteData.buffer.asUint8List());
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Disegno', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Annulla', style: TextStyle(color: CupertinoColors.systemGrey)),
          onPressed: () => Navigator.of(context).pop(),
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
                      onTap: () {
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
                    onPressed: () => setState(() => _isEraser = !_isEraser),
                    child: Icon(
                      CupertinoIcons.bandage,
                      color: _isEraser ? AppleTheme.accentYellow : CupertinoColors.systemGrey,
                      size: 22,
                    ),
                  ),
                  // Undo
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: _lines.isNotEmpty
                        ? () => setState(() => _lines.removeLast())
                        : null,
                    child: const Icon(CupertinoIcons.arrow_uturn_left, size: 20),
                  ),
                  // Clear
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => setState(() => _lines.clear()),
                    child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 20),
                  ),
                ],
              ),
            ),
            // Canvas Area
            Expanded(
              child: Container(
                color: Colors.white,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentLine = [_DrawnPoint(details.localPosition, _createPaint())];
                      _lines.add(_currentLine);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentLine.add(_DrawnPoint(details.localPosition, _createPaint()));
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {});
                  },
                  child: CustomPaint(
                    painter: _CanvasPainter(_lines),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<_DrawnPoint>> lines;
  _CanvasPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      for (int i = 0; i < line.length - 1; i++) {
        canvas.drawLine(line[i].offset, line[i + 1].offset, line[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
