import 'package:flutter/material.dart';

import 'clipboard_image_reader.dart';
import 'pasted_image.dart';

/// Context menu of a text part of the note editor.
///
/// It shows the default items with «Incolla» as paste label. When the
/// clipboard holds an image and no text, «Incolla» is offered as well, and
/// [onPasteImage] receives the image.
class TextPartContextMenu extends StatefulWidget {
  const TextPartContextMenu({
    super.key,
    required this.editableTextState,
    required this.onPasteImage,
    this.readImage = readPastedImage,
  });

  final EditableTextState editableTextState;
  final void Function(ClipboardImage image) onPasteImage;
  final Future<ClipboardImage?> Function() readImage;

  @override
  State<TextPartContextMenu> createState() => _TextPartContextMenuState();
}

class _TextPartContextMenuState extends State<TextPartContextMenu> {
  ClipboardImage? _image;

  @override
  void initState() {
    super.initState();
    widget.readImage().then((image) {
      if (mounted && image != null) {
        setState(() => _image = image);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.editableTextState;
    return ListenableBuilder(
      listenable: state.clipboardStatus,
      builder: (context, _) {
        final items = [...state.contextMenuButtonItems];
        final pasteIndex = items.indexWhere(
          (item) => item.type == ContextMenuButtonType.paste,
        );
        if (pasteIndex >= 0) {
          items[pasteIndex] = items[pasteIndex].copyWith(label: 'Incolla');
        } else if (!state.widget.readOnly && _image != null) {
          final image = _image!;
          final afterCopyOrCut = items.lastIndexWhere(
            (item) =>
                item.type == ContextMenuButtonType.cut ||
                item.type == ContextMenuButtonType.copy,
          );
          items.insert(
            afterCopyOrCut + 1,
            ContextMenuButtonItem(
              type: ContextMenuButtonType.paste,
              label: 'Incolla',
              onPressed: () {
                state.hideToolbar();
                widget.onPasteImage(image);
              },
            ),
          );
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: items,
          anchors: state.contextMenuAnchors,
        );
      },
    );
  }
}
