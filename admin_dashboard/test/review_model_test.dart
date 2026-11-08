import 'package:admin_dashboard/models/review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminReview', () {
    test('maps every field from the Firestore document', () {
      final createdAt = DateTime(2026, 11, 8, 9, 30);
      final review = AdminReview.fromFirestore(
        productId: 'phone-speaker',
        id: 'user-1',
        productName: 'Phone Speaker',
        data: {
          'userId': 'user-1',
          'userName': 'Maya Santos',
          'rating': 5,
          'text': 'Beautiful finish.',
          'createdAt': Timestamp.fromDate(createdAt),
          'moderated': true,
        },
      );

      expect(review.id, 'user-1');
      expect(review.productId, 'phone-speaker');
      expect(review.productName, 'Phone Speaker');
      expect(review.userId, 'user-1');
      expect(review.userName, 'Maya Santos');
      expect(review.rating, 5);
      expect(review.text, 'Beautiful finish.');
      expect(review.createdAt, createdAt);
      expect(review.moderated, isTrue);
    });

    test('falls back to the document id and safe defaults', () {
      final review = AdminReview.fromFirestore(
        productId: 'coaster',
        id: 'user-2',
        productName: 'Coaster',
        data: const {},
      );

      expect(review.userId, 'user-2');
      expect(review.userName, 'LUNTI customer');
      expect(review.text, '');
      expect(review.moderated, isFalse);
    });

    test('clamps out-of-range ratings into 1-5', () {
      AdminReview build(int rating) => AdminReview.fromFirestore(
            productId: 'p',
            id: 'u',
            productName: 'P',
            data: {'rating': rating},
          );

      expect(build(0).rating, 1);
      expect(build(9).rating, 5);
      expect(build(3).rating, 3);
    });
  });
}
