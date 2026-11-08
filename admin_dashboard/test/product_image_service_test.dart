import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:admin_dashboard/services/product_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  final service = ProductImageService();

  group('ProductImageService.prepare', () {
    test('keeps images at or under the stored limit untouched', () async {
      final bytes = _noiseJpeg(400, 300, quality: 90);

      final prepared = await service.prepare(bytes);

      expect(prepared.wasCompressed, isFalse);
      expect(prepared.bytes, same(bytes));
      expect(prepared.originalBytes, bytes.length);
      expect(prepared.contentType, 'image/jpeg');
    });

    test('compresses images over the stored limit below it', () async {
      final bytes = _noiseJpeg(1400, 1400, quality: 100);
      expect(
        bytes.length,
        greaterThan(ProductImageService.maxStoredBytes),
        reason: 'fixture must exceed the stored limit',
      );

      final prepared = await service.prepare(bytes);

      expect(prepared.wasCompressed, isTrue);
      expect(prepared.originalBytes, bytes.length);
      expect(
        prepared.bytes.length,
        lessThan(ProductImageService.maxStoredBytes),
      );
      expect(prepared.savedBytes, greaterThan(0));
      expect(prepared.contentType, 'image/jpeg');
    });

    test('encodes a data URL that round-trips back to the bytes', () async {
      final bytes = _noiseJpeg(400, 300, quality: 90);
      final prepared = await service.prepare(bytes);

      final dataUrl = service.toDataUrl(prepared);

      const prefix = 'data:image/jpeg;base64,';
      expect(dataUrl, startsWith(prefix));
      expect(base64Decode(dataUrl.substring(prefix.length)), bytes);
    });

    test('keeps the encoded data URL under the Firestore document cap', () async {
      final bytes = _noiseJpeg(1400, 1400, quality: 100);
      final prepared = await service.prepare(bytes);

      final dataUrl = service.toDataUrl(prepared);

      // Firestore caps a document at 1 MiB, and the document also holds the
      // rest of the product fields.
      expect(dataUrl.length, lessThan(1024 * 1024));
    });

    test('keeps undecodable bytes instead of failing', () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(2 * 1024 * 1024, (index) => index % 251),
      );

      final prepared = await service.prepare(bytes);

      expect(prepared.wasCompressed, isFalse);
      expect(prepared.bytes, same(bytes));
    });

    test('detects PNG content type', () async {
      final png = img.encodePng(img.Image(width: 8, height: 8));

      final prepared = await service.prepare(png);

      expect(prepared.contentType, 'image/png');
      expect(prepared.wasCompressed, isFalse);
    });
  });

  group('formatBytes', () {
    test('formats KB and MB', () {
      expect(formatBytes(1024), '1 KB');
      expect(formatBytes(812 * 1024), '812 KB');
      expect(formatBytes(2 * 1024 * 1024), '2.00 MB');
    });
  });
}

/// Builds a noisy JPEG that compresses poorly, so large dimensions reliably
/// exceed the 1MB limit.
Uint8List _noiseJpeg(int width, int height, {required int quality}) {
  final random = Random(7);
  final pixels = Uint8List(width * height * 4);
  for (var i = 0; i < pixels.length; i += 4) {
    pixels[i] = random.nextInt(256);
    pixels[i + 1] = random.nextInt(256);
    pixels[i + 2] = random.nextInt(256);
    pixels[i + 3] = 255;
  }
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: pixels.buffer,
    numChannels: 4,
  );
  return img.encodeJpg(image, quality: quality);
}
