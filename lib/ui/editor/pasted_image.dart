import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'clipboard_image_reader.dart';

/// Longest side, in pixels, of a pasted image that is kept as it is.
const pastedImageMaxSide = 2048;

const _jpegQuality = 85;

/// An image ready to be saved as a note attachment.
class PreparedImage {
  const PreparedImage({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// One of `png`, `jpg`, `gif` or `webp`.
  final String extension;
}

/// Turns the bytes of a pasted image into the attachment to save.
///
/// PNG, JPEG, GIF and WebP keep their format; any other format becomes PNG.
/// An image whose longest side exceeds [pastedImageMaxSide] is scaled down
/// keeping its proportions: a JPEG is re-encoded at quality 85, a WebP becomes
/// PNG, and GIF is never scaled down. Returns null when the bytes are not a
/// decodable image.
PreparedImage? prepareImageForNote(Uint8List bytes) {
  final decoder = img.findDecoderForData(bytes);
  if (decoder == null) {
    return null;
  }
  final format = decoder.format;
  if (format == img.ImageFormat.gif) {
    return PreparedImage(bytes: bytes, extension: 'gif');
  }
  final image = decoder.decode(bytes);
  if (image == null) {
    return null;
  }

  final longestSide = math.max(image.width, image.height);
  if (longestSide <= pastedImageMaxSide) {
    return switch (format) {
      img.ImageFormat.jpg => PreparedImage(bytes: bytes, extension: 'jpg'),
      img.ImageFormat.png => PreparedImage(bytes: bytes, extension: 'png'),
      img.ImageFormat.webp => PreparedImage(bytes: bytes, extension: 'webp'),
      _ => PreparedImage(bytes: img.encodePng(image), extension: 'png'),
    };
  }

  final resized = image.width >= image.height
      ? img.copyResize(image, width: pastedImageMaxSide)
      : img.copyResize(image, height: pastedImageMaxSide);
  if (format == img.ImageFormat.jpg) {
    return PreparedImage(
      bytes: img.encodeJpg(resized, quality: _jpegQuality),
      extension: 'jpg',
    );
  }
  return PreparedImage(bytes: img.encodePng(resized), extension: 'png');
}

/// Reads the image on the system clipboard; null when there is none or the
/// clipboard cannot be read.
Future<ClipboardImage?> readPastedImage() async {
  try {
    return await const ClipboardImageReader().read();
  } catch (_) {
    return null;
  }
}
