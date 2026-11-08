import 'package:admin_dashboard/models/admin_product.dart';
import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatusX', () {
    test('parses canonical values', () {
      expect(OrderStatusX.parse('pending'), OrderStatus.pending);
      expect(OrderStatusX.parse('approved'), OrderStatus.approved);
      expect(OrderStatusX.parse('packed'), OrderStatus.packed);
      expect(OrderStatusX.parse('shipped'), OrderStatus.shipped);
      expect(OrderStatusX.parse('completed'), OrderStatus.completed);
      expect(OrderStatusX.parse('cancelled'), OrderStatus.cancelled);
    });

    test('maps legacy prototype values', () {
      expect(OrderStatusX.parse('confirmed'), OrderStatus.approved);
      expect(OrderStatusX.parse('delivered'), OrderStatus.completed);
      expect(OrderStatusX.parse('returned'), OrderStatus.cancelled);
    });

    test('falls back to pending for unknown values', () {
      expect(OrderStatusX.parse(null), OrderStatus.pending);
      expect(OrderStatusX.parse('unknown'), OrderStatus.pending);
    });
  });

  group('Order.fromJson', () {
    test('maps customer, address, items and totals', () {
      final createdAt = DateTime(2026, 11, 8, 9, 30);
      final order = Order.fromJson({
        'userId': 'user-1',
        'customerName': 'Maya Santos',
        'addressLine1': '24 Bamboo Lane',
        'addressLine2': 'Cardona, Rizal',
        'phone': '+63 900 000 0000',
        'paymentMethod': 'cash_on_delivery',
        'status': 'confirmed',
        'subtotal': 500,
        'deliveryFee': 80,
        'total': 580,
        'createdAt': Timestamp.fromDate(createdAt),
        'items': [
          {'productName': 'Phone Speaker', 'quantity': 1},
          {'productName': 'Coaster', 'quantity': 2},
        ],
      }, 'LNT-123456789');

      expect(order.fullName, 'Maya Santos');
      expect(order.address, '24 Bamboo Lane, Cardona, Rizal');
      expect(order.shippingFee, 80);
      expect(order.total, 580);
      expect(order.status, OrderStatus.approved);
      expect(order.createdAt, createdAt);
      expect(order.itemCount, 3);
      expect(order.shortId, 'LNT-6789');
      expect(order.paymentDisplay, 'Cash on Delivery');
      expect(order.paymentStatusDisplay, 'Not recorded');
      expect(order.isPaymentPaid, isFalse);
    });

    test('gives every order a distinct short id even when ids share a prefix', () {
      // Real order ids are `LNT-<epoch millis>`, so every order placed in the
      // same era shares its leading digits. Truncating from the front made the
      // whole orders table read `#LNT-1762`.
      final a = Order.fromJson(const {}, 'LNT-17620123456');
      final b = Order.fromJson(const {}, 'LNT-17620198765');

      expect(a.shortId, 'LNT-3456');
      expect(b.shortId, 'LNT-8765');
      expect(a.shortId, isNot(b.shortId));
    });

    test('falls back to a readable short id for other id shapes', () {
      expect(Order.fromJson(const {}, 'LNT-1794').shortId, 'LNT-1794');
      expect(Order.fromJson(const {}, 'short').shortId, 'short');
      expect(
        Order.fromJson(const {}, 'aaaaaaaaaaaaaaaaaaaa').shortId,
        '#aaaaaa',
      );
      expect(Order.fromJson(const {}, '').shortId, '—');
    });

    test('shows the exact payment method and status from the app', () {
      final gcash = Order.fromJson({
        'paymentMethod': 'GCash (Simulated)',
        'paymentStatus': 'Paid (GCash)',
      }, 'gcash-order');
      expect(gcash.paymentDisplay, 'GCash (Simulated)');
      expect(gcash.paymentStatusDisplay, 'Paid (GCash)');
      expect(gcash.isPaymentPaid, isTrue);

      final card = Order.fromJson({
        'paymentMethod': 'Credit/Debit Card (Simulated)',
        'paymentStatus': 'Paid (Card)',
      }, 'card-order');
      expect(card.paymentDisplay, 'Credit/Debit Card (Simulated)');
      expect(card.paymentStatusDisplay, 'Paid (Card)');
      expect(card.isPaymentPaid, isTrue);

      final cod = Order.fromJson({
        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'Unpaid (COD)',
      }, 'cod-order');
      expect(cod.paymentDisplay, 'Cash on Delivery');
      expect(cod.paymentStatusDisplay, 'Unpaid (COD)');
      expect(cod.isPaymentPaid, isFalse);
    });

    test('maps legacy payment keys onto the exact labels', () {
      expect(
        Order.fromJson({'paymentMethod': 'gcash'}, 'a').paymentDisplay,
        'GCash (Simulated)',
      );
      expect(
        Order.fromJson({'paymentMethod': 'credit_card'}, 'b').paymentDisplay,
        'Credit/Debit Card (Simulated)',
      );
      expect(
        Order.fromJson({'paymentMethod': 'cod'}, 'c').paymentDisplay,
        'Cash on Delivery',
      );
    });

    test('round-trips the payment status written by the app', () {
      final order = Order.fromJson({
        'paymentMethod': 'GCash (Simulated)',
        'paymentStatus': 'Paid (GCash)',
      }, 'LNT-1');

      final data = order.toJson();

      expect(data['paymentMethod'], 'GCash (Simulated)');
      expect(data['paymentStatus'], 'Paid (GCash)');
    });

    test('provides safe defaults for incomplete documents', () {
      final order = Order.fromJson(const {}, 'short');

      expect(order.fullName, 'LUNTI customer');
      expect(order.address, 'No address on file');
      expect(order.status, OrderStatus.pending);
      expect(order.itemCount, 0);
      expect(order.shortId, 'short');
    });

    test('aggregates stock quantities across duplicate product lines', () {
      final order = Order.fromJson({
        'items': [
          {'productId': 'phone-speaker', 'quantity': 1},
          {'productId': 'coaster', 'quantity': 2},
          {'productId': 'phone-speaker', 'quantity': 3},
          {'productId': '', 'quantity': 4},
          {'productId': 'coaster', 'quantity': 0},
          {'productId': 'missing-quantity'},
        ],
      }, 'order-1');

      expect(order.stockQuantities, {
        'phone-speaker': 4,
        'coaster': 2,
        'missing-quantity': 1,
      });
    });
  });

  group('AdminDatabase.shouldRestoreStock', () {
    test('restores only when entering Cancelled', () {
      expect(
        AdminDatabase.shouldRestoreStock(
          current: OrderStatus.pending,
          next: OrderStatus.cancelled,
          alreadyRestored: false,
        ),
        isTrue,
      );
      expect(
        AdminDatabase.shouldRestoreStock(
          current: OrderStatus.shipped,
          next: OrderStatus.cancelled,
          alreadyRestored: false,
        ),
        isTrue,
      );
      expect(
        AdminDatabase.shouldRestoreStock(
          current: OrderStatus.pending,
          next: OrderStatus.approved,
          alreadyRestored: false,
        ),
        isFalse,
      );
    });

    test('never restocks twice', () {
      expect(
        AdminDatabase.shouldRestoreStock(
          current: OrderStatus.cancelled,
          next: OrderStatus.cancelled,
          alreadyRestored: false,
        ),
        isFalse,
      );
      expect(
        AdminDatabase.shouldRestoreStock(
          current: OrderStatus.pending,
          next: OrderStatus.cancelled,
          alreadyRestored: true,
        ),
        isFalse,
      );
      // Re-opening a cancelled order must not arm a second restock.
      expect(
        AdminDatabase.shouldRestoreStock(
          current: OrderStatus.cancelled,
          next: OrderStatus.approved,
          alreadyRestored: true,
        ),
        isFalse,
      );
    });
  });

  group('AdminProduct', () {
    test('detects engraving support from options or price', () {
      final withOption = AdminProduct(
        id: 'a',
        name: 'Phone Speaker',
        description: '',
        category: 'customized',
        price: 450,
        stock: 8,
        engravingPrice: 0,
        availableEngravings: const ['Natural', 'Engraved'],
        imagePath: '',
        note: '',
        eyebrow: '',
        material: 'Bamboo',
        origin: '',
        care: '',
        gallery: const [],
      );
      final plain = AdminProduct(
        id: 'b',
        name: 'Coaster',
        description: '',
        category: 'engraving',
        price: 140,
        stock: 40,
        engravingPrice: 0,
        availableEngravings: const [],
        imagePath: '',
        note: '',
        eyebrow: '',
        material: 'Bamboo',
        origin: '',
        care: '',
        gallery: const [],
      );

      expect(withOption.supportsEngraving, isTrue);
      expect(plain.supportsEngraving, isFalse);
    });

    test('round-trips the Firestore field names used by mobile', () {
      final product = AdminProduct(
        id: 'phone-speaker',
        name: 'Phone Speaker',
        description: 'Bamboo speaker',
        category: 'customized',
        price: 450,
        stock: 8,
        engravingPrice: 100,
        availableEngravings: const ['Natural', 'Engraved'],
        imagePath: 'https://example.com/speaker.jpg',
        note: 'Natural bamboo',
        eyebrow: 'Bamboo everyday',
        material: 'Bamboo',
        origin: 'Cardona, Rizal, Philippines',
        care: 'Wipe gently; keep dry.',
        gallery: const ['https://example.com/speaker.jpg'],
      );

      final data = product.toFirestore();
      final restored = AdminProduct.fromDoc(product.id, data);

      expect(restored.name, product.name);
      expect(restored.price, product.price);
      expect(restored.availableEngravings, product.availableEngravings);
      expect(restored.imagePath, product.imagePath);
      expect(restored.supportsEngraving, isTrue);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });
  });
}
