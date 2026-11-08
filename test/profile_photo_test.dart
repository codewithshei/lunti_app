import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunti_app/widgets/profile_photo.dart';

void main() {
  group('decodeProfilePhoto', () {
    test('decodes a base64 data URL back into bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 250, 251, 252]);
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';

      expect(decodeProfilePhoto(dataUrl), bytes);
    });

    test('returns null for a regular network URL', () {
      expect(decodeProfilePhoto('https://example.com/photo.jpg'), isNull);
    });

    test('returns null for an empty payload or malformed value', () {
      expect(decodeProfilePhoto('data:image/png;base64,'), isNull);
      expect(decodeProfilePhoto('data:image/jpeg;base64,%%%%'), isNull);
      expect(decodeProfilePhoto(''), isNull);
    });
  });
}
