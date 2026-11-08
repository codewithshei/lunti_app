import 'package:cloud_firestore/cloud_firestore.dart';

/// One customer review shown in the admin "Reviews" table.
///
/// Mirrors the mobile `ProductReview` document stored at
/// `products/{productId}/reviews/{uid}`. [productName] is resolved from the
/// catalog by the dashboard so the table can render it without a second query.
class AdminReview {
  const AdminReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.moderated = false,
  });

  final String id;

  /// Product document id, taken from the review's collection path.
  final String productId;

  /// Catalog name resolved by the dashboard (the review doc only stores the id).
  final String productName;

  final String userId;
  final String userName;

  /// Whole stars from 1 to 5.
  final int rating;
  final String text;
  final DateTime createdAt;

  /// True once an admin has hidden the review from the shop.
  final bool moderated;

  factory AdminReview.fromFirestore({
    required String productId,
    required String id,
    required Map<String, dynamic> data,
    required String productName,
  }) {
    return AdminReview(
      id: id,
      productId: productId,
      productName: productName,
      userId: _string(data['userId']) ?? id,
      userName: _string(data['userName']) ?? 'LUNTI customer',
      rating: (_int(data['rating']) ?? 0).clamp(1, 5).toInt(),
      text: _string(data['text']) ?? '',
      createdAt: _dateTime(data['createdAt']) ?? DateTime.now(),
      moderated: data['moderated'] == true,
    );
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
