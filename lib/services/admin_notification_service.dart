import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// The category tags the admin dashboard groups and filters alerts by.
enum AdminNotificationCategory {
  newOrder('New Order'),
  cancellation('Cancellation'),
  review('Review'),
  message('Message');

  const AdminNotificationCategory(this.label);

  /// Value stored in the `category` field of each document.
  final String label;

  static AdminNotificationCategory? fromLabel(String? label) {
    for (final category in values) {
      if (category.label == label) return category;
    }
    return null;
  }
}

/// Writes buyer activity into the shared `admin_notifications` collection.
///
/// The admin dashboard listens to this collection for its notification bell,
/// so a new order, a cancellation or a fresh review surfaces there in real
/// time. Every write is best-effort: it must never block or fail the purchase,
/// cancellation or review the customer just completed.
class AdminNotificationService {
  AdminNotificationService._();

  static final AdminNotificationService instance = AdminNotificationService._();

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('admin_notifications');

  /// Creates one alert. Silently does nothing when Firebase is unavailable
  /// (widget tests, offline preview) or the write is rejected.
  Future<void> _create({
    required String title,
    required String body,
    required AdminNotificationCategory category,
    required String type,
    String? refId,
  }) async {
    if (!isAvailable) return;
    try {
      await _collection.add(<String, dynamic>{
        'title': title,
        'body': body,
        'category': category.label,
        'type': type,
        'refId': refId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (_) {
      // Best-effort only: the buyer action already succeeded.
    }
  }

  /// A customer just placed an order.
  Future<void> notifyNewOrder({
    required String orderId,
    required String customerName,
  }) =>
      _create(
        title: 'New Order Placed',
        body: 'Order #$orderId placed by ${_name(customerName)}',
        category: AdminNotificationCategory.newOrder,
        type: 'order',
        refId: orderId,
      );

  /// A customer cancelled their own order.
  Future<void> notifyOrderCancelled({required String orderId}) => _create(
        title: 'Order Cancelled',
        body: 'Order #$orderId was cancelled by buyer',
        category: AdminNotificationCategory.cancellation,
        type: 'order_cancelled',
        refId: orderId,
      );

  /// A customer submitted a product review.
  Future<void> notifyNewReview({
    required String customerName,
    required int rating,
    required String productName,
    required String productId,
  }) =>
      _create(
        title: 'New Product Review',
        body: '${_name(customerName)} left a $rating-star review on '
            '${_name(productName)}',
        category: AdminNotificationCategory.review,
        type: 'review',
        refId: productId,
      );

  static String _name(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'a customer' : trimmed;
  }
}
