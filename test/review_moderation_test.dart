import 'package:flutter_test/flutter_test.dart';
import 'package:lunti_app/models/product_review.dart';
import 'package:lunti_app/services/review_service.dart';

ProductReview _review(
  String id, {
  bool moderated = false,
  DateTime? createdAt,
}) {
  return ProductReview(
    id: id,
    productId: 'p1',
    userId: id,
    userName: 'Customer $id',
    rating: 5,
    text: 'Review by $id',
    createdAt: createdAt ?? DateTime(2026, 11, 8),
    moderated: moderated,
  );
}

void main() {
  group('ProductReview moderation', () {
    test('parses the moderated flag', () {
      final review = ProductReview.fromFirestore('p1', 'u1', {
        'rating': 5,
        'text': 'Beautiful finish.',
        'moderated': true,
      });

      expect(review.moderated, isTrue);
    });

    test('defaults to visible when the flag is missing', () {
      final review = ProductReview.fromFirestore('p1', 'u1', {'rating': 5});
      expect(review.moderated, isFalse);
    });

    test('treats any non-true value as visible', () {
      for (final value in <Object?>[null, false, 'true', 1]) {
        final review = ProductReview.fromFirestore('p1', 'u1', {
          'moderated': value,
        });
        expect(review.moderated, isFalse, reason: 'value: $value');
      }
    });

    test('toFirestore never writes moderated, so an edit cannot self-unhide', () {
      final json = _review('u1', moderated: true).toFirestore();
      expect(json.containsKey('moderated'), isFalse);
    });
  });

  group('ReviewService.visible', () {
    test('hides moderated reviews and keeps the rest', () {
      final visible = ReviewService.visible(<ProductReview>[
        _review('u1'),
        _review('u2', moderated: true),
      ]);

      expect(visible, hasLength(1));
      expect(visible.single.id, 'u1');
    });

    test('returns an empty list when every review is moderated', () {
      expect(
        ReviewService.visible(<ProductReview>[_review('u1', moderated: true)]),
        isEmpty,
      );
    });

    test('keeps order untouched so callers can sort afterwards', () {
      final visible = ReviewService.visible(<ProductReview>[
        _review('old', createdAt: DateTime(2026, 11, 1)),
        _review('new', createdAt: DateTime(2026, 11, 9)),
      ]);

      expect(visible.map((review) => review.id).toList(), ['old', 'new']);
    });
  });
}
