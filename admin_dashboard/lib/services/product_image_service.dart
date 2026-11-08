import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A picked photo after size validation and, when needed, compression.
class PreparedImage {
  const PreparedImage({
    required this.bytes,
    required this.originalBytes,
    required this.wasCompressed,
    required this.contentType,
  });

  /// Bytes ready to be stored.
  final Uint8List bytes;

  /// Size of the file the admin picked, in bytes.
  final int originalBytes;

  /// True when the image was resized/re-encoded to fit under the limit.
  final bool wasCompressed;

  /// MIME type of the prepared bytes.
  final String contentType;

  /// Bytes saved by compression (0 when the original was kept).
  int get savedBytes =>
      originalBytes > bytes.length ? originalBytes - bytes.length : 0;
}

/// Human-readable byte size, e.g. `812 KB` or `2.40 MB`.
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

/// Compresses product photos for inline Firestore storage.
///
/// The project is on the Firebase Spark plan, so photos are stored inline as
/// base64 data URLs on the `products` document — the same approach the mobile
/// app uses for profile photos — instead of being uploaded to Cloud Storage.
class ProductImageService {
  ProductImageService();

  /// Photos above this size are flagged in the UI (1 MB).
  static const int maxBytes = 1024 * 1024;

  /// Compression target for stored photos.
  ///
  /// Base64 inflates bytes by 33% and Firestore caps a document at 1 MiB, so
  /// the stored target sits well below [maxBytes] to leave room for the rest
  /// of the product document.
  static const int maxStoredBytes = 700 * 1024;

  /// Longest side kept after resizing.
  static const int maxDimension = 1600;

  /// Validates and, when needed, compresses [bytes].
  Future<PreparedImage> prepare(Uint8List bytes) async {
    if (bytes.length <= maxStoredBytes) {
      return PreparedImage(
        bytes: bytes,
        originalBytes: bytes.length,
        wasCompressed: false,
        contentType: _contentTypeOf(bytes),
      );
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // Undecodable input: keep it rather than dropping the admin's photo.
      return PreparedImage(
        bytes: bytes,
        originalBytes: bytes.length,
        wasCompressed: false,
        contentType: 'application/octet-stream',
      );
    }

    final encoded = _encodeUnderLimit(decoded);

    return PreparedImage(
      bytes: encoded,
      originalBytes: bytes.length,
      wasCompressed: encoded.length < bytes.length,
      contentType: 'image/jpeg',
    );
  }

  /// Encodes the prepared bytes as a `data:image/...;base64,...` URL so it can
  /// be stored directly on the product document.
  String toDataUrl(PreparedImage prepared) {
    return 'data:${prepared.contentType};base64,'
        '${base64Encode(prepared.bytes)}';
  }

  /// Encodes [image] as JPEG, lowering quality and then shrinking the image
  /// until the result fits under [maxStoredBytes].
  Uint8List _encodeUnderLimit(img.Image image) {
    var candidate = _resizeTo(image, maxDimension);

    for (var attempt = 0; attempt < 6; attempt++) {
      var quality = 85;
      var encoded = img.encodeJpg(candidate, quality: quality);

      // JPEG size scales roughly linearly with quality, so jump close to the
      // target first instead of stepping down one notch at a time.
      while (encoded.length > maxStoredBytes && quality > 30) {
        final ratio = maxStoredBytes / encoded.length;
        var next = (quality * ratio).round();
        if (next < 30) next = 30;
        if (next >= quality) next = quality - 5;
        quality = next;
        encoded = img.encodeJpg(candidate, quality: quality);
      }

      if (encoded.length <= maxStoredBytes) return encoded;

      // Quality alone was not enough: shrink the image and try again.
      final longest = candidate.width > candidate.height
          ? candidate.width
          : candidate.height;
      if (longest <= 600) return encoded;
      candidate = _resizeTo(candidate, (longest * 0.7).round());
    }

    return img.encodeJpg(candidate, quality: 30);
  }

  /// Scales [image] so its longest side is at most [longestSide] pixels.
  img.Image _resizeTo(img.Image image, int longestSide) {
    final longest = image.width > image.height ? image.width : image.height;
    if (longest <= longestSide) return image;

    final scale = longestSide / longest;
    return img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  String _contentTypeOf(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
