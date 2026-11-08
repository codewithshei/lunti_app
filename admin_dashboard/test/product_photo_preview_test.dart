import 'dart:typed_data';

import 'package:admin_dashboard/widgets/product_photo_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  final bytes = Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 8)));

  testWidgets('shows the compression helper when the original exceeds 1MB', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductPhotoPreview(
            bytes: bytes,
            filename: 'tumbler.png',
            originalBytes: 2 * 1024 * 1024,
            preparedBytes: 700 * 1024,
            wasCompressed: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('tumbler.png'), findsOneWidget);
    expect(find.text('2.00 MB → 700 KB'), findsOneWidget);
    expect(
      find.text(
        'Image exceeds 1MB — compressing automatically for fast app loading',
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides the helper for images already under 1MB', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductPhotoPreview(
            bytes: bytes,
            filename: 'coaster.jpg',
            originalBytes: 400 * 1024,
            preparedBytes: 400 * 1024,
            wasCompressed: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('coaster.jpg'), findsOneWidget);
    expect(find.text('400 KB'), findsOneWidget);
    expect(
      find.text(
        'Image exceeds 1MB — compressing automatically for fast app loading',
      ),
      findsNothing,
    );
  });
}
