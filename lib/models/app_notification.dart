import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry in the in-app notifications centre.
///
/// Notifications live at `users/{uid}/notifications/{id}`. Order-status
/// notifications use a deterministic id (`order_<orderId>_<status>`) so the
/// same status is never announced twice, even after an app restart.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.orderId = '',
    this.status = '',
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String orderId;
  final String status;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AppNotification(
      id: id,
      title: _string(data['title']) ?? 'LUNTI update',
      message: _string(data['message']) ?? '',
      orderId: _string(data['orderId']) ?? '',
      status: _string(data['status']) ?? '',
      isRead: data['isRead'] == true,
      createdAt: _dateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'orderId': orderId,
      'status': status,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      orderId: orderId,
      status: status,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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
