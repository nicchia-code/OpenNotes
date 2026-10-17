import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Invisible strips along the edges and corners of the Linux window that resize it.
///
/// The strips are active only while the system does not show the window as
/// maximized, full screen or tiled; otherwise they are not built at all, so the
/// clicks reach the content below.
class LinuxWindowResizeHandles extends StatefulWidget {
  final Widget child;

  const LinuxWindowResizeHandles({super.key, required this.child});

  @override
  State<LinuxWindowResizeHandles> createState() => _LinuxWindowResizeHandlesState();
}

class _LinuxWindowResizeHandlesState extends State<LinuxWindowResizeHandles>
    with WindowListener {
  static const _tiledChannel = MethodChannel('opennotes/window');
  static const _edgeThickness = 6.0;
  static const _cornerSize = 12.0;

  final _resizable = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _refresh();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _resizable.dispose();
    super.dispose();
  }

  @override
  void onWindowMaximize() => _refresh();

  @override
  void onWindowUnmaximize() => _refresh();

  @override
  void onWindowRestore() => _refresh();

  @override
  void onWindowResized() => _refresh();

  @override
  void onWindowEnterFullScreen() => _refresh();

  @override
  void onWindowLeaveFullScreen() => _refresh();

  Future<void> _refresh() async {
    final blocked =
        await windowManager.isMaximized() ||
        await windowManager.isFullScreen() ||
        await _tiledChannel.invokeMethod<bool>('isTiled') == true;
    if (mounted) _resizable.value = !blocked;
  }

  @override
  Widget build(BuildContext context) {
    // Corners come last so that they win over the edges they overlap.
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        _strip(
          SystemMouseCursors.resizeUpDown,
          ResizeEdge.top,
          top: 0,
          left: _cornerSize,
          right: _cornerSize,
          height: _edgeThickness,
        ),
        _strip(
          SystemMouseCursors.resizeUpDown,
          ResizeEdge.bottom,
          bottom: 0,
          left: _cornerSize,
          right: _cornerSize,
          height: _edgeThickness,
        ),
        _strip(
          SystemMouseCursors.resizeLeftRight,
          ResizeEdge.left,
          left: 0,
          top: _cornerSize,
          bottom: _cornerSize,
          width: _edgeThickness,
        ),
        _strip(
          SystemMouseCursors.resizeLeftRight,
          ResizeEdge.right,
          right: 0,
          top: _cornerSize,
          bottom: _cornerSize,
          width: _edgeThickness,
        ),
        _strip(
          SystemMouseCursors.resizeUpLeftDownRight,
          ResizeEdge.topLeft,
          top: 0,
          left: 0,
          width: _cornerSize,
          height: _cornerSize,
        ),
        _strip(
          SystemMouseCursors.resizeUpRightDownLeft,
          ResizeEdge.topRight,
          top: 0,
          right: 0,
          width: _cornerSize,
          height: _cornerSize,
        ),
        _strip(
          SystemMouseCursors.resizeUpRightDownLeft,
          ResizeEdge.bottomLeft,
          bottom: 0,
          left: 0,
          width: _cornerSize,
          height: _cornerSize,
        ),
        _strip(
          SystemMouseCursors.resizeUpLeftDownRight,
          ResizeEdge.bottomRight,
          bottom: 0,
          right: 0,
          width: _cornerSize,
          height: _cornerSize,
        ),
      ],
    );
  }

  Widget _strip(
    MouseCursor cursor,
    ResizeEdge edge, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: ValueListenableBuilder<bool>(
        valueListenable: _resizable,
        builder: (context, resizable, _) {
          if (!resizable) return const SizedBox.shrink();
          return MouseRegion(
            cursor: cursor,
            opaque: true,
            onEnter: (_) => _refresh(),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                if ((event.buttons & kPrimaryButton) != 0) {
                  windowManager.startResizing(edge);
                }
              },
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}
