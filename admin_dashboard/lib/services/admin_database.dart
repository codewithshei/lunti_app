import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import 'package:admin_dashboard/models/admin_notification.dart';
import 'package:admin_dashboard/models/admin_product.dart';
import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/models/review.dart';
import 'package:admin_dashboard/models/support_chat.dart';

/// Firestore access for the admin dashboard. Both collection shapes match the
/// mobile app, so products added here appear in the shop and status updates
/// here appear in the customer's Order History/Tracking instantly.
class AdminDatabase {
  AdminDatabase({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  /// Default Firestore instance, resolved lazily so tests can subclass this
  /// class without initialising Firebase.
  FirebaseFirestore get _firestore =>
      _override ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _supportChats =>
      _firestore.collection('support_chats');

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  Stream<List<Order>> getAllOrders() {
    return _orders.snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<Order?> getOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    return Order.fromJson(doc.data() ?? const {}, doc.id);
  }

  Stream<Order?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Order.fromJson(doc.data() ?? const {}, doc.id);
    });
  }

  /// Whether moving an order to [next] must add its quantities back to stock.
  ///
  /// Stock is restored only on the transition into Cancelled and only once,
  /// so repeated cancels or an order already restored by the customer never
  /// increase stock twice.
  static bool shouldRestoreStock({
    required OrderStatus current,
    required OrderStatus next,
    required bool alreadyRestored,
  }) {
    return next == OrderStatus.cancelled &&
        current != OrderStatus.cancelled &&
        !alreadyRestored;
  }

  /// Whether moving an order to [next] must settle its payment status.
  ///
  /// Completion means the order was delivered, so cash on delivery has been
  /// collected by the rider. Wallet and card orders settle up front and are
  /// already paid, so their stored label is left untouched.
  static bool shouldMarkPaid({
    required OrderStatus next,
    required bool alreadyPaid,
  }) =>
      next == OrderStatus.completed && !alreadyPaid;

  /// The statuses an order may move to from [current].
  ///
  /// Fulfilment advances one step at a time and any non-final status can be
  /// cancelled. Cancelled is terminal, so stock can never be restored twice by
  /// reopening an order.
  static Set<OrderStatus> nextStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return const {OrderStatus.approved, OrderStatus.cancelled};
      case OrderStatus.approved:
        return const {OrderStatus.packed, OrderStatus.cancelled};
      case OrderStatus.packed:
        return const {OrderStatus.shipped, OrderStatus.cancelled};
      case OrderStatus.shipped:
        return const {OrderStatus.completed, OrderStatus.cancelled};
      case OrderStatus.completed:
        return const {OrderStatus.cancelled};
      case OrderStatus.cancelled:
        return const <OrderStatus>{};
    }
  }

  /// Whether [current] may move to [next] in one step.
  static bool canTransition(OrderStatus current, OrderStatus next) =>
      nextStatuses(current).contains(next);

  /// Moves an order to [status], restoring product stock when it is cancelled.
  ///
  /// The status update and the `FieldValue.increment` restores run in one
  /// transaction. Re-reading the order first makes cancellation idempotent:
  /// an order that is already cancelled (or already restored once) never
  /// increases stock a second time, even when two admins tap Cancel together.
  /// Every change is appended to `statusHistory` for the audit trail.
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String actor = '',
  }) async {
    final orderRef = _orders.doc(orderId);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) {
        throw StateError('Order $orderId was not found.');
      }

      final data = snapshot.data() ?? const <String, dynamic>{};
      final order = Order.fromJson(data, orderId);

      if (!canTransition(order.status, status)) {
        throw StateError(
          'Cannot move order ${order.shortId} from ${order.status.label} to '
          '${status.label}.',
        );
      }

      final alreadyRestored = data['stockRestored'] == true;
      final shouldRestoreStock = AdminDatabase.shouldRestoreStock(
        current: order.status,
        next: status,
        alreadyRestored: alreadyRestored,
      );

      final requested =
          shouldRestoreStock ? order.stockQuantities : const <String, int>{};

      // Read every product before the first write, as Firestore transactions
      // require. Missing products are skipped instead of failing the whole
      // status update.
      final productSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final productId in requested.keys) {
        productSnapshots[productId] =
            await transaction.get(_products.doc(productId));
      }

      final now = Timestamp.now();
      for (final entry in requested.entries) {
        if (productSnapshots[entry.key]?.exists != true) continue;
        transaction.update(_products.doc(entry.key), {
          'stock': FieldValue.increment(entry.value),
          'updatedAt': now,
        });
      }

      final history = <OrderStatusHistoryEntry>[
        ...order.statusHistory,
        OrderStatusHistoryEntry(
          status: status,
          at: now.toDate(),
          by: actor,
        ),
      ];

      // Completion settles cash on delivery: the rider has collected it.
      final settlePayment = AdminDatabase.shouldMarkPaid(
        next: status,
        alreadyPaid: order.hasPaidOnRecord,
      );

      transaction.update(orderRef, {
        'status': status.name,
        'updatedAt': now,
        if (shouldRestoreStock) 'stockRestored': true,
        if (settlePayment)
          'paymentStatus': paidPaymentStatus(order.paymentMethod),
        'statusHistory': [
          for (final entry in history) entry.toFirestore(),
        ],
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Support chat
  // ---------------------------------------------------------------------------

  /// Live list of customer conversations, newest activity first.
  Stream<List<SupportThread>> watchSupportThreads() {
    return _supportChats.snapshots().map((snapshot) {
      final threads = snapshot.docs
          .map((doc) => SupportThread.fromDoc(doc.id, doc.data()))
          .where((thread) =>
              thread.lastMessage.isNotEmpty || thread.lastMessageAt != null)
          .toList()
        ..sort((a, b) {
          final aDate =
              a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      return threads;
    });
  }

  /// Live message history for one customer, oldest first.
  Stream<List<SupportMessage>> watchSupportMessages(String uid) {
    return _supportChats
        .doc(uid)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessage.fromDoc(doc.id, doc.data()))
            .toList());
  }

  /// Writes an admin reply and updates the thread preview so the customer's
  /// live chat and the dashboard list stay in sync.
  Future<void> sendSupportMessage({
    required String uid,
    required String adminId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Message cannot be empty.');
    }

    final timestamp = DateTime.now();
    final messageRef = _supportChats.doc(uid).collection('messages').doc();
    final message = SupportMessage(
      id: messageRef.id,
      senderId: adminId,
      text: trimmed,
      timestamp: timestamp,
      isAdmin: true,
    );

    await messageRef.set(message.toFirestore());

    // The reply is already saved; keep the inbox preview best-effort so an
    // older rule deployment cannot block the conversation itself.
    try {
      await _supportChats.doc(uid).set(
        {
          'uid': uid,
          'lastMessage': trimmed,
          'lastMessageAt': Timestamp.fromDate(timestamp),
          'lastSenderId': adminId,
          'lastSenderIsAdmin': true,
          'adminUnread': 0,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // The message history remains the source of truth for the conversation.
    }
  }

  /// Clears the unread badge when the admin opens a conversation.
  Future<void> markSupportThreadRead(String uid) async {
    await _supportChats.doc(uid).update({'adminUnread': 0});
  }

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------

  String newProductId() => _products.doc().id;

  Stream<List<AdminProduct>> watchProducts() {
    return _products.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => AdminProduct.fromDoc(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return products;
    });
  }

  Future<AdminProduct?> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return AdminProduct.fromDoc(doc.id, doc.data() ?? const {});
  }

  Future<void> saveProduct(AdminProduct product) async {
    await _products.doc(product.id).set(product.toFirestore());
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  /// Live reviews across every product, newest first.
  ///
  /// A `collectionGroup` query reads `products/{productId}/reviews` for every
  /// product in one stream, with product names taken from the catalog. When
  /// that query is unavailable — most commonly because the collection-group
  /// index has not been created yet — it falls back to reading each product's
  /// `reviews` subcollection directly so the page never hangs.
  Stream<List<AdminReview>> watchAllReviews() async* {
    try {
      await for (final reviews in _watchCollectionGroupReviews()) {
        yield reviews;
      }
    } catch (_) {
      await for (final reviews in _watchProductReviews()) {
        yield reviews;
      }
    }
  }

  Stream<List<AdminReview>> _watchCollectionGroupReviews() {
    final controller = StreamController<List<AdminReview>>();
    final productNames = <String, String>{};

    final productsSub = _products.snapshots().listen(
      (snapshot) {
        for (final doc in snapshot.docs) {
          productNames[doc.id] =
              _string(doc.data()['name']) ?? 'Untitled product';
        }
      },
      onError: (_) {},
    );

    final reviewsSub =
        _firestore.collectionGroup('reviews').snapshots().listen(
      (snapshot) {
        if (controller.isClosed) return;
        final reviews = snapshot.docs.map((doc) {
          final productId = doc.reference.parent.parent?.id ?? '';
          return AdminReview.fromFirestore(
            productId: productId,
            id: doc.id,
            data: doc.data(),
            productName: productNames[productId] ?? 'Unknown product',
          );
        }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(reviews);
      },
      onError: (Object error) {
        if (!controller.isClosed) controller.addError(error);
      },
    );

    controller.onCancel = () {
      productsSub.cancel();
      reviewsSub.cancel();
    };

    return controller.stream;
  }

  /// Reads each product's `reviews` subcollection in turn. Slower than the
  /// collection-group query, but it needs no index.
  Stream<List<AdminReview>> _watchProductReviews() async* {
    await for (final snapshot in _products.snapshots()) {
      final reviews = <AdminReview>[];

      for (final product in snapshot.docs) {
        final name = _string(product.data()['name']) ?? 'Untitled product';
        try {
          final reviewSnap = await product.reference.collection('reviews').get();
          for (final doc in reviewSnap.docs) {
            reviews.add(
              AdminReview.fromFirestore(
                productId: product.id,
                id: doc.id,
                data: doc.data(),
                productName: name,
              ),
            );
          }
        } catch (_) {
          // Skip products whose reviews cannot be read.
        }
      }

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield reviews;
    }
  }

  /// Hides a review from the shop ([moderated] = true) or restores it.
  Future<void> setReviewModerated(
    AdminReview review, {
    required bool moderated,
  }) async {
    await _reviewRef(review).update({'moderated': moderated});
  }

  /// Permanently removes a review.
  Future<void> deleteReview(AdminReview review) async {
    await _reviewRef(review).delete();
  }

  DocumentReference<Map<String, dynamic>> _reviewRef(AdminReview review) {
    return _products.doc(review.productId).collection('reviews').doc(review.id);
  }

  // ---------------------------------------------------------------------------
  // Admin notifications
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _adminNotifications =>
      _firestore.collection('admin_notifications');

  /// Live admin alerts, newest first.
  Stream<List<AdminNotification>> watchAdminNotifications() {
    return _adminNotifications.snapshots().map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AdminNotification.fromFirestore(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }

  Future<void> markNotificationRead(String id) async {
    await _adminNotifications.doc(id).update({'read': true});
  }

  /// Marks every unread alert as read in one batch.
  Future<void> markAllNotificationsRead() async {
    final snapshot = await _adminNotifications
        .where('read', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Demo data
  // ---------------------------------------------------------------------------

  /// Seeds the three showcase pieces that ship with the dashboard demo.
  ///
  /// Deterministic document ids match the mobile sample catalog, so running
  /// both seeders never creates duplicate product names. Missing ids are
  /// added individually, which also repairs a partially seeded project.
  Future<void> seedProducts() async {
    try {
      final snapshot = await _products.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      final missing = _seedProducts.entries
          .where((product) => !existingIds.contains(product.key))
          .toList();
      if (missing.isEmpty) return;

      final batch = _firestore.batch();
      for (final entry in missing) {
        batch.set(_products.doc(entry.key), entry.value);
      }
      await batch.commit();
    } catch (_) {
      // Seeding needs an authenticated session under the project rules.
      // The login screen retries after sign-in, so startup stays usable.
    }
  }

  static final Map<String, Map<String, dynamic>> _seedProducts = {
    'phone-speaker': {
      'name': 'Phone Speaker',
      'description': 'A handcrafted bamboo piece for your phone, with natural '
          'warmth for your desk or bedside.',
      'type': 'product',
      'category': 'customized',
      'price': 450,
      'stock': 8,
      'engravingPrice': 100,
      'availableEngravings': ['Natural', 'Engraved'],
      'imagePath': 'assets/images/prod_phone_speaker.jpg',
      'note': 'Natural bamboo',
      'eyebrow': 'Bamboo everyday',
      'material': 'Bamboo',
      'origin': 'Cardona, Rizal, Philippines',
      'care': 'Wipe gently; keep dry.',
      'gallery': ['assets/images/prod_phone_speaker.jpg'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    'coaster': {
      'name': 'Coaster',
      'description': 'A simple bamboo coaster for coffee, tea and slow '
          'mornings.',
      'type': 'product',
      'category': 'engraving',
      'price': 140,
      'stock': 40,
      'engravingPrice': 0,
      'availableEngravings': <String>[],
      'imagePath': 'assets/images/prod_coaster.jpg',
      'note': 'For everyday rituals',
      'eyebrow': 'Everyday rituals',
      'material': 'Bamboo',
      'origin': 'Cardona, Rizal, Philippines',
      'care': 'Wipe gently; keep dry.',
      'gallery': ['assets/images/prod_coaster.jpg'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    'arc-holder': {
      'name': 'Small Speaker',
      'description': 'A compact bamboo passive speaker that amps up your '
          'phone with no wires.',
      'type': 'product',
      'category': 'customized',
      'price': 150,
      'stock': 16,
      'engravingPrice': 100,
      'availableEngravings': ['Natural', 'Engraved'],
      'imagePath': 'assets/images/prod_arc_holder.jpg',
      'note': 'Compact phone speaker',
      'eyebrow': 'Sound by bamboo',
      'material': 'Bamboo',
      'origin': 'Cardona, Rizal, Philippines',
      'care': 'Wipe gently; keep dry.',
      'gallery': ['assets/images/prod_arc_holder.jpg'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  };
}
