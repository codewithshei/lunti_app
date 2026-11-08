import 'package:cloud_firestore/cloud_firestore.dart';

/// Order model used by the legacy database service.
///
/// The mobile checkout and order screens use the richer local `Order` model in
/// `data/mock_app_state.dart`; this model stays available for direct Firestore
/// operations and shares the same canonical status names.
enum OrderStatus { pending, approved, packed, shipped, completed, cancelled }

class Order {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String fullName;
  final String address;
  final String phone;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.fullName,
    required this.address,
    required this.phone,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json, String docId) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = OrderStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => _legacyStatus(statusStr),
    );

    return Order(
      id: docId,
      userId: json['userId'] as String? ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      subtotal: json['subtotal'] as int? ?? 0,
      deliveryFee:
          json['deliveryFee'] as int? ?? json['shippingFee'] as int? ?? 80,
      total: json['total'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash_on_delivery',
      status: status,
      createdAt: _dateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'fullName': fullName,
      'address': address,
      'phone': phone,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static OrderStatus _legacyStatus(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.approved;
      case 'delivered':
        return OrderStatus.completed;
      case 'returned':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
