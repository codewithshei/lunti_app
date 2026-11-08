import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show IconData, Icons;

/// Category tag used to group, filter and badge admin notifications.
class AdminNotificationCategory {
  const AdminNotificationCategory._(this.label, this.icon);

  /// Value stored in the `category` field of each document.
  final String label;

  final IconData icon;

  static const _newOrderLabel = 'New Order';
  static const _cancellationLabel = 'Cancellation';
  static const _reviewLabel = 'Review';
  static const _messageLabel = 'Message';

  static const newOrder =
      AdminNotificationCategory._(_newOrderLabel, Icons.receipt_long_outlined);
  static const cancellation =
      AdminNotificationCategory._(_cancellationLabel, Icons.cancel_outlined);
  static const review =
      AdminNotificationCategory._(_reviewLabel, Icons.star_outline);
  static const message =
      AdminNotificationCategory._(_messageLabel, Icons.chat_bubble_outline);
  static const other =
      AdminNotificationCategory._('Other', Icons.notifications_none);

  /// Filter chips shown at the top of the notifications popover.
  ///
  /// `(chip label, stored category label)` — `null` means "All".
  static const filters = <(String, String?)>[
    ('All', null),
    ('Orders', _newOrderLabel),
    ('Cancellations', _cancellationLabel),
    ('Reviews', _reviewLabel),
    ('Messages', _messageLabel),
  ];

  static AdminNotificationCategory fromLabel(String? label) {
    switch (label) {
      case 'New Order':
        return newOrder;
      case 'Cancellation':
        return cancellation;
      case 'Review':
        return review;
      case 'Message':
        return message;
      default:
        return other;
    }
  }
}

/// Admin alert stored in the `admin_notifications` collection.
///
/// [type] and [refId] drive the tap navigation: `order` and `order_cancelled`
/// open the order detail page, `review` opens the reviews table and `message`
/// opens the support inbox.
class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
    this.category,
    this.type,
    this.refId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  /// Category tag, e.g. `New Order`, `Cancellation`, `Review`, `Message`.
  final String? category;

  /// `order`, `order_cancelled`, `review`, `message`, or null.
  final String? type;

  /// Order document id for order alerts, product id for reviews, or the
  /// customer uid for messages.
  final String? refId;

  bool get hasLink =>
      refId != null &&
      (type == 'order' ||
          type == 'order_cancelled' ||
          type == 'review' ||
          type == 'message');

  /// Resolved tag for badges and filter chips.
  AdminNotificationCategory get tag =>
      AdminNotificationCategory.fromLabel(category);

  factory AdminNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AdminNotification(
      id: id,
      title: _string(data['title']) ?? 'Notification',
      body: _string(data['body']) ?? '',
      timestamp: _dateTime(data['timestamp']) ??
          _dateTime(data['createdAt']) ??
          DateTime.now(),
      read: data['read'] == true,
      category: _string(data['category']),
      type: _string(data['type']),
      refId: _string(data['refId']) ??
          _string(data['orderId']) ??
          _string(data['uid']),
    );
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
