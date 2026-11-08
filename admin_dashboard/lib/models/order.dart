import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical order status shared with the mobile app. Older prototype values
/// are mapped by [OrderStatusX.parse] so existing documents keep working.
enum OrderStatus { pending, approved, packed, shipped, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus parse(Object? value) {
    switch ('$value'.toLowerCase()) {
      case 'approved':
      case 'confirmed':
        return OrderStatus.approved;
      case 'packed':
        return OrderStatus.packed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'completed':
      case 'delivered':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
      case 'returned':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

/// One entry in an order's status audit trail.
class OrderStatusHistoryEntry {
  const OrderStatusHistoryEntry({
    required this.status,
    required this.at,
    this.by = '',
  });

  final OrderStatus status;
  final DateTime at;

  /// Admin uid or email when known.
  final String by;

  factory OrderStatusHistoryEntry.fromFirestore(Map<String, dynamic> data) {
    return OrderStatusHistoryEntry(
      status: OrderStatusX.parse(data['status']),
      at: _dateTime(data['at']) ?? DateTime.now(),
      by: '${data['by'] ?? ''}'.trim(),
    );
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'status': status.name,
        'at': Timestamp.fromDate(at),
        'by': by,
      };

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// The payment status recorded once an order is completed.
///
/// Cash on delivery settles on delivery, so a completed COD order becomes
/// 'Paid (COD)'. Wallet and card orders settle up front and keep their own
/// label; anything unrecognised falls back to a plain 'Paid'.
String paidPaymentStatus(Object? paymentMethod) {
  final text = '${paymentMethod ?? ''}'.trim().toLowerCase();
  if (text.contains('gcash')) return 'Paid (GCash)';
  if (text.contains('card') ||
      text.contains('credit') ||
      text.contains('debit')) {
    return 'Paid (Card)';
  }
  if (text.contains('cash') || text == 'cod' || text.contains('delivery')) {
    return 'Paid (COD)';
  }
  return 'Paid';
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.fullName,
    required this.address,
    required this.phone,
    required this.paymentMethod,
    this.paymentStatus = '',
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.statusHistory = const <OrderStatusHistoryEntry>[],
  });

  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int shippingFee;
  final int total;
  final String fullName;
  final String address;
  final String phone;
  final String paymentMethod;

  /// 'Paid (GCash)', 'Paid (Card)' or 'Unpaid (COD)' for new orders. Older
  /// orders may not have a stored status.
  final String paymentStatus;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Status changes in order, newest last. Written by the admin dashboard.
  final List<OrderStatusHistoryEntry> statusHistory;

  int get itemCount => items.fold(
        0,
        (runningTotal, item) =>
            runningTotal + (_int(item['quantity']) ?? 1),
      );

  /// Short, distinct reference shown in tables, chips and snackbars.
  ///
  /// Order ids are `LNT-<epoch millis>`, so every order placed in the same era
  /// shares its leading digits — truncating from the front made every row of
  /// the orders table read `#LNT-1762`. Take the trailing digits instead, which
  /// are unique per order.
  String get shortId {
    final match = RegExp(r'^LNT-(\d+)$').firstMatch(id);
    if (match != null) {
      final digits = match.group(1)!;
      final tail = digits.length <= 4
          ? digits
          : digits.substring(digits.length - 4);
      return 'LNT-$tail';
    }
    if (id.isEmpty) return '—';
    return id.length <= 8 ? id : '#${id.substring(id.length - 6)}';
  }

  String get statusLabel => status.label;

  /// Combined quantity per product id, used when cancelling an order.
  ///
  /// The same product can appear on more than one line (for example Natural
  /// plus an engraved version), so stock must be restored against the total.
  Map<String, int> get stockQuantities {
    final requested = <String, int>{};
    for (final item in items) {
      final productId = _string(item['productId']);
      if (productId == null) continue;
      final quantity = _int(item['quantity']) ?? 1;
      if (quantity < 1) continue;
      requested.update(
        productId,
        (value) => value + quantity,
        ifAbsent: () => quantity,
      );
    }
    return requested;
  }

  /// Exact, human-readable method label.
  ///
  /// New orders store the label directly. Legacy prototype documents may
  /// contain `cash_on_delivery`, `gcash` or similar keys, which are mapped to
  /// the same labels the mobile app shows.
  String get paymentDisplay {
    final value = paymentMethod.trim();
    final lower = value.toLowerCase();
    if (lower == 'cash_on_delivery' ||
        lower == 'cod' ||
        lower.contains('cash on delivery')) {
      return 'Cash on Delivery';
    }
    if (lower == 'gcash' || lower.contains('gcash')) {
      return 'GCash (Simulated)';
    }
    if (lower.contains('card') ||
        lower.contains('credit') ||
        lower.contains('debit')) {
      return 'Credit/Debit Card (Simulated)';
    }
    return value.isEmpty ? 'Not set' : value;
  }

  /// Whether the order has been paid.
  ///
  /// Cash on delivery settles on delivery, so a completed COD order counts as
  /// paid even when its stored status predates that rule.
  bool get isPaymentPaid =>
      hasPaidOnRecord || status == OrderStatus.completed;

  /// Whether the stored record already says paid.
  ///
  /// Used to decide whether a status change needs to write the payment status
  /// at all, so an already-paid wallet order is never rewritten.
  bool get hasPaidOnRecord =>
      paymentStatus.trim().toLowerCase().startsWith('paid');

  /// Status shown in the payment column.
  ///
  /// A completed order has been delivered, so cash on delivery has been
  /// collected — including orders stored before completion began writing the
  /// payment status, which would otherwise read 'Unpaid (COD)' forever.
  String get paymentStatusDisplay {
    final value = paymentStatus.trim();
    if (status == OrderStatus.completed && !hasPaidOnRecord) {
      return paidPaymentStatus(paymentMethod);
    }
    return value.isEmpty ? 'Not recorded' : value;
  }

  factory Order.fromJson(Map<String, dynamic> json, String docId) {
    final rawItems = json['items'];
    final items = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map) {
          items.add(Map<String, dynamic>.from(entry));
        }
      }
    }

    final addressLine1 = _string(json['addressLine1']) ?? '';
    final addressLine2 = _string(json['addressLine2']) ?? '';
    final combined = [
      addressLine1,
      addressLine2,
    ].where((part) => part.isNotEmpty).join(', ');

    return Order(
      id: docId,
      userId: _string(json['userId']) ?? '',
      items: items,
      subtotal: _int(json['subtotal']) ?? 0,
      shippingFee:
          _int(json['shippingFee']) ?? _int(json['deliveryFee']) ?? 0,
      total: _int(json['total']) ?? 0,
      fullName: _string(json['customerName']) ??
          _string(json['fullName']) ??
          'LUNTI customer',
      address: _string(json['address']) ??
          (combined.isEmpty ? 'No address on file' : combined),
      phone: _string(json['phone']) ?? '',
      paymentMethod: _string(json['paymentMethod']) ?? 'Not set',
      paymentStatus: _string(json['paymentStatus']) ?? '',
      status: OrderStatusX.parse(json['status']),
      createdAt: _dateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTime(json['updatedAt']),
      statusHistory: _history(json['statusHistory']),
    );
  }

  static List<OrderStatusHistoryEntry> _history(Object? value) {
    if (value is! List) return const <OrderStatusHistoryEntry>[];
    final entries = <OrderStatusHistoryEntry>[];
    for (final entry in value) {
      if (entry is Map) {
        entries.add(
          OrderStatusHistoryEntry.fromFirestore(Map<String, dynamic>.from(entry)),
        );
      }
    }
    return entries;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'deliveryFee': shippingFee,
      'total': total,
      'customerName': fullName,
      'fullName': fullName,
      'address': address,
      'phone': phone,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'statusHistory': [
        for (final entry in statusHistory) entry.toFirestore(),
      ],
    };
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
