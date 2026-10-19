import 'dart:async';
import 'dart:typed_data';

import 'package:super_clipboard/super_clipboard.dart';

/// An image read from the system clipboard, with the extension of its format
/// (`png`, `jpg`, `gif`, `webp`, `tiff` or `bmp`).
class ClipboardImage {
  const ClipboardImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Reads an image from the system clipboard with `super_clipboard`.
///
/// Only image data is read: files copied in the file manager are not, because
/// file URIs are not synthesized into files. Returns `null` when the clipboard
/// holds no image in one of the supported formats, or when reading the
/// clipboard is not available on the platform.
class ClipboardImageReader {
  const ClipboardImageReader();

  static const _formats = <(FileFormat, String)>[
    (Formats.png, 'png'),
    (Formats.jpeg, 'jpg'),
    (Formats.gif, 'gif'),
    (Formats.webp, 'webp'),
    (Formats.tiff, 'tiff'),
    (Formats.bmp, 'bmp'),
  ];

  Future<ClipboardImage?> read() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return null;
    }
    final reader = await clipboard.read();
    for (final (format, extension) in _formats) {
      final bytes = await _readFile(reader, format);
      if (bytes != null) {
        return ClipboardImage(bytes: bytes, extension: extension);
      }
    }
    return null;
  }

  Future<Uint8List?> _readFile(ClipboardReader reader, FileFormat format) {
    final completer = Completer<Uint8List?>();
    final progress = reader.getFile(
      format,
      (file) async {
        try {
          completer.complete(await file.readAll());
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
      onError: (error) => completer.completeError(error),
      synthesizeFilesFromURIs: false,
    );
    if (progress == null) {
      completer.complete(null);
    }
    return completer.future;
  }
}
