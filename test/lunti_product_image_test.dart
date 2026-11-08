import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunti_app/widgets/lunti_product_image.dart';
import 'package:lunti_app/widgets/profile_photo.dart';

/// 1x1 transparent PNG.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  final dataUrl = 'data:image/png;base64,$_pngBase64';

  group('decodeBase64Image', () {
    test('decodes a data URL', () {
      expect(decodeBase64Image(dataUrl), base64Decode(_pngBase64));
    });

    test('returns null for non-data values', () {
      expect(decodeBase64Image('https://example.com/photo.jpg'), isNull);
      expect(decodeBase64Image('assets/images/prod.jpg'), isNull);
      expect(decodeBase64Image(''), isNull);
      expect(decodeBase64Image('data:image/png;base64,'), isNull);
    });

    test('keeps the profile-photo alias working', () {
      expect(decodeProfilePhoto(dataUrl), isNotNull);
    });
  });

  group('LuntiProductImage', () {
    testWidgets('renders an embedded data URL from memory', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LuntiProductImage(image: dataUrl, width: 80, height: 80),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is MemoryImage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders a network URL from the network', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuntiProductImage(
              image: 'https://example.com/photo.jpg',
              width: 80,
              height: 80,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is NetworkImage,
        ),
        findsOneWidget,
      );
    });
  });
}
