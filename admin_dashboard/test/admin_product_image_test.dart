import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_dashboard/widgets/admin_product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  final pngBytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 8, height: 8)),
  );
  final dataUrl = 'data:image/png;base64,${base64Encode(pngBytes)}';

  group('decodeBase64Image', () {
    test('decodes a data URL', () {
      expect(decodeBase64Image(dataUrl), pngBytes);
    });

    test('returns null for network URLs and asset paths', () {
      expect(decodeBase64Image('https://example.com/photo.jpg'), isNull);
      expect(decodeBase64Image('assets/images/prod.jpg'), isNull);
      expect(decodeBase64Image(''), isNull);
    });

    test('returns null for malformed payloads', () {
      expect(decodeBase64Image('data:image/png;base64,'), isNull);
      expect(decodeBase64Image('data:image/png;base64,!!!not-base64!!!'), isNull);
    });
  });

  group('AdminProductImage', () {
    testWidgets('renders an embedded data URL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminProductImage(image: dataUrl)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders a fallback for an empty value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AdminProductImage(image: '')),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
