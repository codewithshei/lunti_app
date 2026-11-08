import 'package:cloud_firestore/cloud_firestore.dart';

/// One customer review stored under `products/{productId}/reviews/{uid}`.
///
/// The review document id is the reviewer's Firebase uid, so one account can
/// have at most one review per product (submitting again edits that review).
class ProductReview {
  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.moderated = false,
  });

  final String id;
  final String productId;
  final String userId;
  final String userName;

  /// Whole stars from 1 to 5.
  final int rating;
  final String text;
  final DateTime createdAt;

  /// Hidden from the shop by an admin. The reviewer's own edit preserves it.
  final bool moderated;

  factory ProductReview.fromFirestore(
    String productId,
    String id,
    Map<String, dynamic> data,
  ) {
    return ProductReview(
      id: id,
      productId: productId,
      userId: _string(data['userId']) ?? id,
      userName: _string(data['userName']) ?? 'LUNTI customer',
      rating: (_int(data['rating']) ?? 0).clamp(1, 5).toInt(),
      text: _string(data['text']) ?? '',
      createdAt: _dateTime(data['createdAt']) ?? DateTime.now(),
      moderated: data['moderated'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Aggregate rating shown near the product title and on catalog cards.
class ReviewSummary {
  const ReviewSummary({this.average = 0, this.count = 0});

  final double average;
  final int count;

  bool get hasReviews => count > 0;

  /// "4.8" (one decimal) or "—" when there are no reviews yet.
  String get averageLabel =>
      hasReviews ? average.toStringAsFixed(1) : '\u2014';
}
