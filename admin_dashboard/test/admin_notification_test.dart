import 'package:admin_dashboard/models/admin_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminNotification', () {
    test('maps title, body, timestamp, category and read state', () {
      final timestamp = DateTime(2026, 11, 8, 9, 30);
      final notification = AdminNotification.fromFirestore('n1', {
        'title': 'New order',
        'body': 'Order #abc was placed.',
        'timestamp': Timestamp.fromDate(timestamp),
        'read': false,
        'category': 'New Order',
        'type': 'order',
        'refId': 'order-123',
      });

      expect(notification.id, 'n1');
      expect(notification.title, 'New order');
      expect(notification.body, 'Order #abc was placed.');
      expect(notification.timestamp, timestamp);
      expect(notification.read, isFalse);
      expect(notification.category, 'New Order');
      expect(notification.tag, AdminNotificationCategory.newOrder);
      expect(notification.type, 'order');
      expect(notification.refId, 'order-123');
      expect(notification.hasLink, isTrue);
    });

    test('only navigable types produce a deep link', () {
      AdminNotification build(String? type, String? refId) =>
          AdminNotification.fromFirestore('n', {
            'type': type,
            'refId': refId,
          });

      expect(build('order', 'o1').hasLink, isTrue);
      expect(build('order_cancelled', 'o1').hasLink, isTrue);
      expect(build('review', 'p1').hasLink, isTrue);
      expect(build('message', 'u1').hasLink, isTrue);
      expect(build('order', null).hasLink, isFalse);
      expect(build('other', 'x').hasLink, isFalse);
      expect(build(null, null).hasLink, isFalse);
    });

    test('resolves category tags and falls back to Other', () {
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
      expect(
        AdminNotificationCategory.fromLabel(null),
        AdminNotificationCategory.other,
      );
      expect(
        AdminNotificationCategory.fromLabel('Nope'),
        AdminNotificationCategory.other,
      );
    });

    test('exposes a filter chip for every category', () {
      expect(
        AdminNotificationCategory.filters.map((entry) => entry.$1).toList(),
        ['All', 'Orders', 'Cancellations', 'Reviews', 'Messages'],
      );
      expect(
        AdminNotificationCategory.filters.map((entry) => entry.$2).toList(),
        [null, 'New Order', 'Cancellation', 'Review', 'Message'],
      );
    });

    test('falls back to createdAt and legacy reference fields', () {
      final createdAt = DateTime(2026, 11, 8, 9, 30);
      final notification = AdminNotification.fromFirestore('n2', {
        'title': 'New message',
        'createdAt': Timestamp.fromDate(createdAt),
        'uid': 'user-9',
        'type': 'message',
      });

      expect(notification.timestamp, createdAt);
      expect(notification.refId, 'user-9');
      expect(notification.hasLink, isTrue);
    });

    test('provides safe defaults for incomplete documents', () {
      final notification = AdminNotification.fromFirestore('n3', const {});

      expect(notification.title, 'Notification');
      expect(notification.body, '');
      expect(notification.read, isFalse);
      expect(notification.hasLink, isFalse);
    });
  });
}
