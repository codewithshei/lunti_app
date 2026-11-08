import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/support_message.dart';

/// Customer-to-admin support chat at `support_chats/{uid}/messages`.
///
/// The customer app writes messages with `isAdmin: false`; the admin dashboard
/// replies with `isAdmin: true` and the live snapshot renders both sides.
/// Without Firebase the conversation stays in memory for tests/previews.
class ChatService {
  ChatService._() {
    localMessages.addListener(() {
      _localController.add(localMessages.value);
    });
  }

  static final ChatService instance = ChatService._();

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  final ValueNotifier<List<SupportMessage>> localMessages =
      ValueNotifier<List<SupportMessage>>(const []);

  final StreamController<List<SupportMessage>> _localController =
      StreamController<List<SupportMessage>>.broadcast();

  CollectionReference<Map<String, dynamic>> _messages(String uid) {
    return FirebaseFirestore.instance
        .collection('support_chats')
        .doc(uid)
        .collection('messages');
  }

  /// Parent document used by the admin inbox for the thread list preview and
  /// unread badge. The message history stays in the `messages` subcollection.
  DocumentReference<Map<String, dynamic>> _conversation(String uid) {
    return FirebaseFirestore.instance.collection('support_chats').doc(uid);
  }

  /// Live conversation, oldest message first.
  Stream<List<SupportMessage>> watchMessages(String uid) {
    if (isAvailable) {
      return _messages(uid)
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SupportMessage.fromFirestore(doc.id, doc.data()))
              .toList());
    }
    return _watchLocal();
  }

  Stream<List<SupportMessage>> _watchLocal() async* {
    List<SupportMessage> sorted() {
      final items = List<SupportMessage>.of(localMessages.value)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return items;
    }

    yield sorted();
    yield* _localController.stream.map((_) => sorted());
  }

  /// Sends a customer message. Returns an error message on failure.
  Future<String?> sendMessage({
    required String uid,
    required String senderId,
    required String text,
    bool isAdmin = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Write a message before sending.';
    if (trimmed.length > 1000) {
      return 'Keep your message to 1000 characters or fewer.';
    }

    final message = SupportMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      senderId: senderId,
      text: trimmed,
      timestamp: DateTime.now(),
      isAdmin: isAdmin,
    );

    if (!isAvailable) {
      localMessages.value = [...localMessages.value, message];
      return null;
    }

    try {
      await _messages(uid).doc(message.id).set(message.toFirestore());
    } on FirebaseException catch (exception) {
      return 'Could not send your message (${exception.code}). '
          'Please try again.';
    } catch (_) {
      return 'Could not send your message. Check your connection and try again.';
    }

    // Keep the admin inbox preview/unread counter in sync. The message is
    // already saved, so a metadata failure must not surface as a send error.
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _conversation(uid).set(
        {
          'uid': uid,
          'userName': _displayName(user),
          'userEmail': user?.email ?? '',
          'lastMessage': trimmed,
          'lastMessageAt': Timestamp.fromDate(message.timestamp),
          'lastSenderId': senderId,
          'lastSenderIsAdmin': isAdmin,
          if (!isAdmin) 'adminUnread': FieldValue.increment(1),
          if (isAdmin) 'adminUnread': 0,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Older rule deployments may not allow the parent document yet.
    }

    return null;
  }

  static String _displayName(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'LUNTI customer';
  }

  /// Clears the in-memory conversation between widget tests.
  void resetLocal() {
    localMessages.value = const [];
  }
}
