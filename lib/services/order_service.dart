import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/mock_app_state.dart';
import '../data/payment_method.dart';
import 'admin_notification_service.dart';
import 'catalog_store.dart';
import 'stock_service.dart';

/// Outcome of a customer-initiated cancellation.
class CancelOrderResult {
  const CancelOrderResult._({this.error});

  const CancelOrderResult.success() : error = null;

  const CancelOrderResult.failed(String error) : this._(error: error);

  final String? error;

  bool get isSuccess => error == null;
}

/// Thrown inside the cancellation transaction when the order is no longer
/// pending; aborts every write so stock is never restored twice.
class _OrderNotPendingException implements Exception {
  const _OrderNotPendingException();
}

/// Reads and writes the shared `orders` collection.
///
/// The mobile app writes one document per placed order under a locally
/// generated order id and listens to its own orders with Firestore snapshots.
/// The admin dashboard reads the same documents and updates `status`, so the
/// customer's Order History and Tracking screens update in real time.
class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _orders =>
      FirebaseFirestore.instance.collection('orders');

  CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Live order list for one customer, newest first.
  Stream<List<Order>> watchUserOrders(String userId) {
    return _orders.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final orders = snapshot.docs
            .map((doc) => _fromFirestore(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      },
    );
  }

  /// Live single order used by the tracking screen.
  Stream<Order?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc.id, doc.data() ?? const {});
    });
  }

  /// Saves a placed order. Returns `false` when Firebase is unavailable so the
  /// caller can keep showing the local prototype order (widget tests).
  Future<bool> saveOrder(Order order) async {
    final userId = order.userId.isEmpty ? _currentUserId : order.userId;
    if (!isAvailable) return false;

    // Allow anonymous orders - use 'anonymous' as placeholder userId
    final String effectiveUserId = (userId == null || userId.isEmpty) ? 'anonymous' : userId;

    try {
      await _orders.doc(order.id).set(_toFirestore(order, effectiveUserId));
    } catch (_) {
      return false;
    }

    // Best-effort: alert the admin dashboard. The order is already saved, so a
    // failed notification must not report the order as failed.
    await AdminNotificationService.instance.notifyNewOrder(
      orderId: order.id,
      customerName: order.customerName,
    );

    return true;
  }

  /// Places [order] and reserves its stock in one atomic step.
  ///
  /// With Firebase available the stock check, the stock decrements and the
  /// order document are written in a single Firestore transaction, so a
  /// failure can never leave stock reserved with no order (or an order saved
  /// with no stock behind it). Without Firebase the same validation runs
  /// against the local catalog.
  Future<StockDeductionResult> placeOrder(Order order) async {
    final requested = StockService.requestedQuantities(order.items);

    if (!isAvailable) {
      return _placeOrderLocally(requested);
    }

    final conflicts = <StockConflict>[];
    try {
      await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
        // A retry re-runs this body, so discard any conflicts from the
        // previous attempt before reading the documents again.
        conflicts.clear();

        final snapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final productId in requested.keys) {
          snapshots[productId] = await transaction.get(_products.doc(productId));
        }

        for (final entry in requested.entries) {
          final snapshot = snapshots[entry.key]!;
          final data = snapshot.data();
          final name = _string(data?['name']) ?? entry.key;
          final available = _int(data?['stock']) ?? 0;

          if (!snapshot.exists || available < entry.value) {
            conflicts.add(
              StockConflict(
                productId: entry.key,
                productName: name,
                requested: entry.value,
                available: snapshot.exists ? available : 0,
              ),
            );
          }
        }

        // Returning without write operations cancels the transaction, so a
        // rejected order leaves the catalog untouched.
        if (conflicts.isNotEmpty) return;

        final now = Timestamp.now();
        for (final entry in requested.entries) {
          transaction.update(_products.doc(entry.key), {
            'stock': FieldValue.increment(-entry.value),
            'updatedAt': now,
          });
        }
        transaction.set(
          _orders.doc(order.id),
          _toFirestore(order, order.userId),
        );
      });
    } on FirebaseException catch (exception) {
      return StockDeductionResult.failed(
        'Could not place your order (${exception.code}). Please try again.',
      );
    } catch (_) {
      return const StockDeductionResult.failed(
        'Could not place your order. Check your connection and try again.',
      );
    }

    if (conflicts.isNotEmpty) {
      return StockDeductionResult.insufficient(conflicts);
    }

    // Reflect the sale immediately; the live Firestore snapshot confirms it.
    CatalogStore.instance.applyStockDelta(requested);

    // Best-effort: alert the admin dashboard. The order is already saved.
    await AdminNotificationService.instance.notifyNewOrder(
      orderId: order.id,
      customerName: order.customerName,
    );

    return const StockDeductionResult.success();
  }

  /// Local prototype path: validate against the in-memory catalog.
  Future<StockDeductionResult> _placeOrderLocally(
    Map<String, int> requested,
  ) async {
    final catalog = {
      for (final product in CatalogStore.instance.products.value)
        product.id: product,
    };
    final conflicts = <StockConflict>[];
    for (final entry in requested.entries) {
      final product = catalog[entry.key];
      if (product == null) continue;
      final available = StockService.availableFor(product);
      if (available < entry.value) {
        conflicts.add(
          StockConflict(
            productId: entry.key,
            productName: product.name,
            requested: entry.value,
            available: available,
          ),
        );
      }
    }
    if (conflicts.isNotEmpty) return StockDeductionResult.insufficient(conflicts);

    CatalogStore.instance.applyStockDelta(requested);
    return const StockDeductionResult.success();
  }

  /// Cancels a pending order and restores every product's stock.
  ///
  /// Firestore runs the order status update and the `FieldValue.increment`
  /// stock restores in one transaction, so either both happen or neither does.
  /// The transaction re-reads the order first and aborts if it is no longer
  /// pending, which prevents a double restore when two devices tap Cancel.
  Future<CancelOrderResult> cancelOrder(Order order) async {
    // Only restore stock the first time: an admin may already have cancelled
    // and restocked this order, and the flag survives a status round-trip.
    final requested = order.stockRestored
        ? const <String, int>{}
        : StockService.requestedQuantities(order.items);

    if (!isAvailable) {
      if (order.status != OrderStatus.pending) {
        return const CancelOrderResult.failed(
          'Only pending orders can be cancelled.',
        );
      }
      MockAppState.markOrderCancelled(order.id);
      CatalogStore.instance.restoreStock(requested);
      return const CancelOrderResult.success();
    }

    try {
      await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
        final orderRef = _orders.doc(order.id);
        final snapshot = await transaction.get(orderRef);
        if (!snapshot.exists) {
          throw const _OrderNotPendingException();
        }
        final status = OrderStatusX.fromFirestore(snapshot.data()?['status']);
        if (status != OrderStatus.pending) {
          throw const _OrderNotPendingException();
        }

        final now = Timestamp.now();
        for (final entry in requested.entries) {
          transaction.update(_products.doc(entry.key), {
            'stock': FieldValue.increment(entry.value),
            'updatedAt': now,
          });
        }
        transaction.update(orderRef, {
          'status': OrderStatus.cancelled.name,
          // Shared with the admin dashboard: its cancellation restock is
          // idempotent on this flag, so a later admin status round-trip can
          // never restore the same stock twice.
          'stockRestored': true,
          'updatedAt': now,
          'statusHistory': _appendHistory(
            snapshot.data()?['statusHistory'],
            <String, dynamic>{
              'status': OrderStatus.cancelled.name,
              'at': now,
              'by': order.userId,
            },
          ),
        });
      });
    } on _OrderNotPendingException {
      return const CancelOrderResult.failed(
        'Only pending orders can be cancelled.',
      );
    } on FirebaseException catch (exception) {
      return CancelOrderResult.failed(
        'Could not cancel this order (${exception.code}). Please try again.',
      );
    } catch (_) {
      return const CancelOrderResult.failed(
        'Could not cancel this order. Check your connection and try again.',
      );
    }

    // Best-effort: alert the admin dashboard about the cancellation.
    await AdminNotificationService.instance.notifyOrderCancelled(
      orderId: order.id,
    );

    // Reflect the cancellation immediately, then let the live Firestore
    // snapshots confirm both the order status and the restored stock.
    MockAppState.markOrderCancelled(order.id);
    CatalogStore.instance.restoreStock(requested);
    await CatalogStore.instance.refresh();
    return const CancelOrderResult.success();
  }

  /// Appends [entry] to a stored `statusHistory` array, tolerating documents
  /// written before the audit trail existed.
  static List<Map<String, dynamic>> _appendHistory(
    Object? raw,
    Map<String, dynamic> entry,
  ) {
    final history = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) history.add(Map<String, dynamic>.from(item));
      }
    }
    history.add(entry);
    return history;
  }

  Map<String, dynamic> _toFirestore(Order order, String userId) {
    final catalog = {
      for (final product in CatalogStore.instance.products.value)
        product.id: product,
    };
    final items = <Map<String, dynamic>>[];
    for (final line in order.items) {
      final product = catalog[line.productId];
      final unitPrice = product == null
          ? 0
          : BagPricing.unitPrice(product, line);
      items.add({
        'productId': line.productId,
        'productName': product?.name ?? line.productId,
        'variant': line.variant,
        'engravingText': line.engravingText,
        'quantity': line.quantity,
        'unitPrice': unitPrice,
        'lineTotal': unitPrice * line.quantity,
        'imagePath': product?.image,
      });
    }

    final fullAddress = [
      order.addressLine1,
      order.addressLine2,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return {
      'userId': userId,
      'customerName': order.customerName,
      'fullName': order.customerName,
      'email': order.email,
      'addressTitle': order.addressTitle,
      'addressLine1': order.addressLine1,
      'addressLine2': order.addressLine2,
      'address': fullAddress,
      'phone': order.phone,
      'items': items,
      'subtotal': order.subtotal,
      'shippingFee': order.shippingFee,
      'deliveryFee': order.shippingFee,
      'total': order.total,
      'paymentMethod': order.paymentMethod,
      'paymentStatus': order.paymentStatus.isEmpty
          ? PaymentMethodX.parse(order.paymentMethod).paymentStatus
          : order.paymentStatus,
      'status': order.status.name,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'updatedAt': Timestamp.now(),
      // The audit trail starts at placement.
      'statusHistory': <Map<String, dynamic>>[
        <String, dynamic>{
          'status': order.status.name,
          'at': Timestamp.now(),
          'by': userId,
        },
      ],
    };
  }

  Order _fromFirestore(String id, Map<String, dynamic> data) {
    final rawItems = data['items'];
    final items = <BagLine>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is! Map) continue;
        final productId = '${entry['productId'] ?? ''}'.trim();
        if (productId.isEmpty) continue;
        final quantity = _int(entry['quantity']) ?? 1;
        items.add(
          BagLine(
            productId,
            variant: _string(entry['variant']),
            quantity: quantity < 1 ? 1 : quantity,
          )..engravingText = _string(entry['engravingText']),
        );
      }
    }

    final fullName =
        _string(data['customerName']) ?? _string(data['fullName']) ?? '';
    final addressLine1 = _string(data['addressLine1']) ?? '';
    final addressLine2 = _string(data['addressLine2']) ?? '';
    final combinedAddress = _string(data['address']) ?? '';

    return Order(
      id: id,
      items: items,
      subtotal: _int(data['subtotal']) ?? 0,
      shippingFee: _int(data['shippingFee']) ?? _int(data['deliveryFee']) ?? 0,
      total: _int(data['total']) ?? 0,
      paymentMethod: _string(data['paymentMethod']) ?? 'Cash on Delivery',
      paymentStatus: _string(data['paymentStatus']) ??
          PaymentMethodX.parse(data['paymentMethod']).paymentStatus,
      addressTitle: _string(data['addressTitle']) ?? 'Home',
      addressLine1: addressLine1.isNotEmpty ? addressLine1 : combinedAddress,
      addressLine2: addressLine2,
      phone: _string(data['phone']) ?? '',
      createdAt: _dateTime(data['createdAt']) ?? DateTime.now(),
      customerName: fullName,
      email: _string(data['email']) ?? '',
      userId: _string(data['userId']) ?? '',
      status: OrderStatusX.fromFirestore(data['status']),
      stockRestored: data['stockRestored'] == true,
      statusHistory: _statusHistory(data['statusHistory']),
    );
  }

  /// Reads a stored `statusHistory` array into typed entries, tolerating
  /// documents written before the audit trail existed.
  static List<OrderStatusHistoryEntry> _statusHistory(Object? value) {
    if (value is! List) return const <OrderStatusHistoryEntry>[];
    final entries = <OrderStatusHistoryEntry>[];
    for (final item in value) {
      if (item is! Map) continue;
      final at = _dateTime(item['at']);
      if (at == null) continue;
      entries.add(
        OrderStatusHistoryEntry(
          status: OrderStatusX.fromFirestore(item['status']),
          at: at,
          by: _string(item['by']) ?? '',
        ),
      );
    }
    return entries;
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
