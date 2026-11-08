import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/mock_app_state.dart';
import '../models/app_notification.dart';
import 'order_service.dart';

/// In-app notifications at `users/{uid}/notifications`.
///
/// Order-status notifications are derived from the same `orders` documents the
/// admin dashboard updates. A deterministic document id per order + status
/// keeps them idempotent, so opening the app repeatedly never duplicates an
/// announcement. Without Firebase the service keeps a local list for widget
/// tests and offline previews.
class NotificationService {
  NotificationService._() {
    localNotifications.addListener(() {
      _localController.add(localNotifications.value);
    });
  }

  static final NotificationService instance = NotificationService._();

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  final ValueNotifier<List<AppNotification>> localNotifications =
      ValueNotifier<List<AppNotification>>(const []);

  final StreamController<List<AppNotification>> _localController =
      StreamController<List<AppNotification>>.broadcast();

  final Map<String, StreamSubscription<List<Order>>> _orderSubs =
      <String, StreamSubscription<List<Order>>>{};

  final Set<String> _createdThisSession = <String>{};

  CollectionReference<Map<String, dynamic>> _notifications(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  /// Live notifications for one account, newest first.
  Stream<List<AppNotification>> watch(String uid) {
    if (isAvailable) {
      return _notifications(uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
              .toList());
    }
    return _watchLocal();
  }

  Stream<List<AppNotification>> _watchLocal() async* {
    List<AppNotification> sorted() {
      final items = List<AppNotification>.of(localNotifications.value)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    }

    yield sorted();
    yield* _localController.stream.map((_) => sorted());
  }

  /// Live unread badge count for the bell icon.
  Stream<int> watchUnreadCount(String uid) {
    return watch(uid).map(
      (items) => items.where((item) => !item.isRead).length,
    );
  }

  Future<void> markRead(String uid, String notificationId) async {
    if (!isAvailable) {
      localNotifications.value = [
        for (final item in localNotifications.value)
          item.id == notificationId ? item.copyWith(isRead: true) : item,
      ];
      return;
    }
    try {
      await _notifications(uid).doc(notificationId).update({'isRead': true});
    } catch (_) {
      // The live snapshot will reflect the write when it succeeds.
    }
  }

  Future<void> markAllRead(String uid) async {
    if (!isAvailable) {
      localNotifications.value = [
        for (final item in localNotifications.value)
          item.copyWith(isRead: true),
      ];
      return;
    }
    try {
      final unread = await _notifications(uid)
          .where('isRead', isEqualTo: false)
          .get();
      if (unread.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {
      // Keep the screen usable; the next snapshot will show what saved.
    }
  }

  /// Starts watching this customer's orders so status changes become
  /// notifications. Safe to call from multiple screens; only one listener per
  /// uid is created.
  void startOrderSync(String uid) {
    if (!isAvailable) {
      syncLocalOrders();
      return;
    }
    if (_orderSubs.containsKey(uid)) return;
    _orderSubs[uid] = OrderService.instance.watchUserOrders(uid).listen(
      (orders) {
        for (final order in orders) {
          unawaited(_ensureOrderNotification(uid, order));
        }
      },
      onError: (_) {
        // A transient read error should not break the notifications screen.
      },
    );
  }

  /// Adds local notifications for prototype orders (tests / offline).
  void syncLocalOrders() {
    for (final order in MockAppState.orders.value) {
      _addLocalNotification(order);
    }
  }

  void _addLocalNotification(Order order) {
    final id = _notificationId(order);
    if (localNotifications.value.any((item) => item.id == id)) return;
    final copy = _copyFor(order);
    localNotifications.value = [
      AppNotification(
        id: id,
        title: copy.title,
        message: copy.message,
        orderId: order.id,
        status: order.status.name,
        createdAt: DateTime.now(),
      ),
      ...localNotifications.value,
    ];
  }

  Future<void> _ensureOrderNotification(String uid, Order order) async {
    final id = _notificationId(order);
    if (_createdThisSession.contains(id)) return;
    _createdThisSession.add(id);

    try {
      final ref = _notifications(uid).doc(id);
      final existing = await ref.get();
      if (existing.exists) return;
      final copy = _copyFor(order);
      await ref.set(
        AppNotification(
          id: id,
          title: copy.title,
          message: copy.message,
          orderId: order.id,
          status: order.status.name,
          createdAt: DateTime.now(),
        ).toFirestore(),
      );
    } catch (_) {
      // Allow a later snapshot to retry this notification.
      _createdThisSession.remove(id);
    }
  }

  static String _notificationId(Order order) {
    return 'order_${order.id}_${order.status.name}';
  }

  static ({String title, String message}) _copyFor(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
        return (
          title: 'Order received',
          message: 'Your order ${order.id} was received. We will let you know '
              'when it is approved.',
        );
      case OrderStatus.approved:
        return (
          title: 'Order approved',
          message: 'Your order ${order.id} was approved!',
        );
      case OrderStatus.packed:
        return (
          title: 'Order packed',
          message: 'Your order ${order.id} has been packed and is getting '
              'ready to ship.',
        );
      case OrderStatus.shipped:
        return (
          title: 'Order shipped',
          message: 'Your order ${order.id} is on the way.',
        );
      case OrderStatus.completed:
        return (
          title: 'Order delivered',
          message: 'Your order ${order.id} was delivered. Enjoy your LUNTI '
              'pieces!',
        );
      case OrderStatus.cancelled:
        return (
          title: 'Order cancelled',
          message: 'Your order ${order.id} was cancelled. Any reserved stock '
              'has been returned.',
        );
    }
  }

  /// Clears in-memory notifications between widget tests.
  void resetLocal() {
    localNotifications.value = const [];
    _createdThisSession.clear();
  }
}
