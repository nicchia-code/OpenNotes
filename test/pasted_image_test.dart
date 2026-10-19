import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:open_notes/ui/editor/pasted_image.dart';

img.Image _solid(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 80, 40));
  return image;
}

void main() {
  test('a small PNG keeps its bytes and format', () {
    final bytes = Uint8List.fromList(img.encodePng(_solid(300, 200)));

    final prepared = prepareImageForNote(bytes);

    expect(prepared!.extension, 'png');
    expect(prepared.bytes, bytes);
  });

  test('a small JPEG keeps its bytes and format', () {
    final bytes = Uint8List.fromList(img.encodeJpg(_solid(300, 200)));

    final prepared = prepareImageForNote(bytes);

    expect(prepared!.extension, 'jpg');
    expect(prepared.bytes, bytes);
  });

  test('another format, such as BMP, becomes PNG', () {
    final bytes = Uint8List.fromList(img.encodeBmp(_solid(300, 200)));

    final prepared = prepareImageForNote(bytes);

    expect(prepared!.extension, 'png');
    expect(img.findFormatForData(prepared.bytes), img.ImageFormat.png);
  });

  test('a TIFF becomes PNG', () {
    final bytes = Uint8List.fromList(img.encodeTiff(_solid(300, 200)));

    final prepared = prepareImageForNote(bytes);

    expect(prepared!.extension, 'png');
    expect(img.findFormatForData(prepared.bytes), img.ImageFormat.png);
  });

  test('a PNG wider than 2048 px is scaled down keeping its proportions', () {
    final bytes = Uint8List.fromList(img.encodePng(_solid(3000, 1500)));

    final prepared = prepareImageForNote(bytes);
    final decoded = img.decodeImage(prepared!.bytes)!;

    expect(prepared.extension, 'png');
    expect(decoded.width, 2048);
    expect(decoded.height, 1024);
  });

  test('a tall PNG is scaled down on its height', () {
    final bytes = Uint8List.fromList(img.encodePng(_solid(1000, 4000)));

    final decoded = img.decodeImage(prepareImageForNote(bytes)!.bytes)!;

    expect(decoded.width, 512);
    expect(decoded.height, 2048);
  });

  test('a JPEG wider than 2048 px is scaled down and written as JPEG', () {
    final bytes = Uint8List.fromList(img.encodeJpg(_solid(2500, 1000)));

    final prepared = prepareImageForNote(bytes);
    final decoded = img.decodeImage(prepared!.bytes)!;

    expect(prepared.extension, 'jpg');
    expect(img.findFormatForData(prepared.bytes), img.ImageFormat.jpg);
    expect(decoded.width, 2048);
  });

  test('a GIF is never scaled down', () {
    final bytes = Uint8List.fromList(img.encodeGif(_solid(3000, 1500)));

    final prepared = prepareImageForNote(bytes);

    expect(prepared!.extension, 'gif');
    expect(prepared.bytes, bytes);
  });

  test('bytes that are not an image give no attachment', () {
    final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

    expect(prepareImageForNote(bytes), isNull);
  });
}
