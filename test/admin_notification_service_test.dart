import 'package:flutter_test/flutter_test.dart';
import 'package:lunti_app/services/admin_notification_service.dart';

void main() {
  group('AdminNotificationCategory', () {
    test('resolves the stored category labels', () {
      expect(
        AdminNotificationCategory.fromLabel('New Order'),
        AdminNotificationCategory.newOrder,
      );
      expect(
        AdminNotificationCategory.fromLabel('Cancellation'),
        AdminNotificationCategory.cancellation,
      );
      expect(
        AdminNotificationCategory.fromLabel('Review'),
        AdminNotificationCategory.review,
      );
      expect(
        AdminNotificationCategory.fromLabel('Message'),
        AdminNotificationCategory.message,
      );
    });

    test('returns null for unknown labels', () {
      expect(AdminNotificationCategory.fromLabel(null), isNull);
      expect(AdminNotificationCategory.fromLabel('Nope'), isNull);
    });
  });

  group('AdminNotificationService', () {
    test('writes are a safe no-op without Firebase', () async {
      // Widget tests run without Firebase initialized, so these must not throw.
      expect(AdminNotificationService.isAvailable, isFalse);

      await AdminNotificationService.instance.notifyNewOrder(
        orderId: 'ORD-1',
        customerName: 'Maya Santos',
      );
      await AdminNotificationService.instance.notifyOrderCancelled(
        orderId: 'ORD-1',
      );
      await AdminNotificationService.instance.notifyNewReview(
        customerName: 'Maya Santos',
        rating: 5,
        productName: 'Bamboo Tumbler',
        productId: 'p1',
      );
    });
  });
}
