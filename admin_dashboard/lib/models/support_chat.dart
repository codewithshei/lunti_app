import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in the admin Messages workspace.
///
/// The customer app keeps a lightweight parent document at
/// `support_chats/{uid}` with the customer's name/email, a preview of the last
/// message and an unread counter for the admin dashboard.
class SupportThread {
  const SupportThread({
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderIsAdmin,
    required this.adminUnread,
  });

  final String uid;
  final String userName;
  final String userEmail;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final bool lastSenderIsAdmin;
  final int adminUnread;

  bool get hasUnread => adminUnread > 0;

  String get displayName {
    if (userName.isNotEmpty) return userName;
    if (userEmail.isNotEmpty) return userEmail;
    return 'LUNTI customer';
  }

  String get displayEmail => userEmail.isNotEmpty ? userEmail : uid;

  factory SupportThread.fromDoc(String uid, Map<String, dynamic> data) {
    return SupportThread(
      uid: uid,
      userName:
          _string(data['userName']) ?? _string(data['customerName']) ?? '',
      userEmail: _string(data['userEmail']) ?? _string(data['email']) ?? '',
      lastMessage: _string(data['lastMessage']) ?? '',
      lastMessageAt:
          _dateTime(data['lastMessageAt']) ?? _dateTime(data['updatedAt']),
      lastSenderIsAdmin: data['lastSenderIsAdmin'] == true,
      adminUnread: _int(data['adminUnread']) ?? 0,
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

/// One message inside `support_chats/{uid}/messages`.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isAdmin,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isAdmin;

  factory SupportMessage.fromDoc(String id, Map<String, dynamic> data) {
    return SupportMessage(
      id: id,
      senderId: _string(data['senderId']) ?? '',
      text: _string(data['text']) ?? '',
      timestamp: _dateTime(data['timestamp']) ?? DateTime.now(),
      isAdmin: data['isAdmin'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAdmin': isAdmin,
    };
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
