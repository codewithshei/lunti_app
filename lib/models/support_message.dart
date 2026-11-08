import 'package:cloud_firestore/cloud_firestore.dart';

/// One message in a customer's support conversation.
///
/// Messages live at `support_chats/{uid}/messages`; `isAdmin` lets the app
/// render LUNTI support replies differently from the customer's own messages.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isAdmin = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isAdmin;

  factory SupportMessage.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
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
