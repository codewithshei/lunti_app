import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminDatabase.nextStatuses', () {
    test('fulfilment advances one step at a time', () {
      expect(AdminDatabase.nextStatuses(OrderStatus.pending), {
        OrderStatus.approved,
        OrderStatus.cancelled,
      });
      expect(AdminDatabase.nextStatuses(OrderStatus.approved), {
        OrderStatus.packed,
        OrderStatus.cancelled,
      });
      expect(AdminDatabase.nextStatuses(OrderStatus.packed), {
        OrderStatus.shipped,
        OrderStatus.cancelled,
      });
      expect(AdminDatabase.nextStatuses(OrderStatus.shipped), {
        OrderStatus.completed,
        OrderStatus.cancelled,
      });
      expect(
        AdminDatabase.nextStatuses(OrderStatus.completed),
        {OrderStatus.cancelled},
      );
      expect(AdminDatabase.nextStatuses(OrderStatus.cancelled), isEmpty);
    });

    test('rejects skipping or reversing the happy path', () {
      expect(
        AdminDatabase.canTransition(OrderStatus.pending, OrderStatus.completed),
        isFalse,
      );
      expect(
        AdminDatabase.canTransition(OrderStatus.cancelled, OrderStatus.pending),
        isFalse,
      );
      expect(
        AdminDatabase.canTransition(OrderStatus.completed, OrderStatus.pending),
        isFalse,
      );
      expect(
        AdminDatabase.canTransition(OrderStatus.pending, OrderStatus.approved),
        isTrue,
      );
      expect(
        AdminDatabase.canTransition(OrderStatus.shipped, OrderStatus.cancelled),
        isTrue,
      );
    });
  });

  group('Order.statusHistory', () {
    test('parses entries oldest first with their actor', () {
      final order = Order.fromJson(<String, dynamic>{
        'status': 'packed',
        'statusHistory': <dynamic>[
          <String, dynamic>{
            'status': 'pending',
            'at': Timestamp.fromDate(DateTime(2026, 11, 8, 9)),
            'by': 'admin-1',
          },
          <String, dynamic>{
            'status': 'approved',
            'at': Timestamp.fromDate(DateTime(2026, 11, 8, 10)),
          },
          <String, dynamic>{
            'status': 'packed',
            'at': Timestamp.fromDate(DateTime(2026, 11, 8, 11)),
          },
        ],
      }, 'LNT-1');

      expect(order.statusHistory, hasLength(3));
      expect(order.statusHistory.first.status, OrderStatus.pending);
      expect(order.statusHistory.first.by, 'admin-1');
      expect(order.statusHistory.last.status, OrderStatus.packed);
      expect(order.statusHistory.last.by, '');
    });

    test('defaults to empty for legacy documents', () {
      final order = Order.fromJson(<String, dynamic>{'status': 'pending'}, 'LNT-2');
      expect(order.statusHistory, isEmpty);
    });

    test('round-trips through toJson', () {
      final order = Order(
        id: 'LNT-3',
        userId: 'u1',
        items: const <Map<String, dynamic>>[],
        subtotal: 0,
        shippingFee: 0,
        total: 0,
        fullName: 'Maya Santos',
        address: 'Cardona, Rizal',
        phone: '0917',
        paymentMethod: 'Cash on Delivery',
        status: OrderStatus.shipped,
        createdAt: DateTime(2026, 11, 8, 9),
        statusHistory: <OrderStatusHistoryEntry>[
          OrderStatusHistoryEntry(
            status: OrderStatus.shipped,
            at: DateTime(2026, 11, 8, 12),
            by: 'admin-2',
          ),
        ],
      );

      final raw = (order.toJson()['statusHistory'] as List<dynamic>)
          .single as Map<String, dynamic>;
      expect(raw['status'], 'shipped');
      expect(raw['by'], 'admin-2');
    });
  });

  group('AdminDatabase.shouldMarkPaid', () {
    test('only completion settles the payment, and only once', () {
      expect(
        AdminDatabase.shouldMarkPaid(
          next: OrderStatus.completed,
          alreadyPaid: false,
        ),
        isTrue,
      );
      expect(
        AdminDatabase.shouldMarkPaid(
          next: OrderStatus.completed,
          alreadyPaid: true,
        ),
        isFalse,
      );
      for (final next in [
        OrderStatus.pending,
        OrderStatus.approved,
        OrderStatus.packed,
        OrderStatus.shipped,
        OrderStatus.cancelled,
      ]) {
        expect(
          AdminDatabase.shouldMarkPaid(next: next, alreadyPaid: false),
          isFalse,
          reason: '$next must not settle payment',
        );
      }
    });
  });

  group('paidPaymentStatus', () {
    test('maps each method onto its paid variant', () {
      expect(paidPaymentStatus('Cash on Delivery'), 'Paid (COD)');
      expect(paidPaymentStatus('cash_on_delivery'), 'Paid (COD)');
      expect(paidPaymentStatus('COD'), 'Paid (COD)');
      expect(paidPaymentStatus('GCash (Simulated)'), 'Paid (GCash)');
      expect(paidPaymentStatus('Credit/Debit Card (Simulated)'), 'Paid (Card)');
    });

    test('falls back to a plain Paid for anything unrecognised', () {
      expect(paidPaymentStatus(''), 'Paid');
      expect(paidPaymentStatus(null), 'Paid');
      expect(paidPaymentStatus('Bank transfer'), 'Paid');
    });
  });

  group('Order payment status display', () {
    test('a completed COD order reads as paid even when stored unpaid', () {
      final order = Order.fromJson(<String, dynamic>{
        'status': 'completed',
        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'Unpaid (COD)',
      }, 'LNT-4');

      expect(order.hasPaidOnRecord, isFalse);
      expect(order.isPaymentPaid, isTrue);
      expect(order.paymentStatusDisplay, 'Paid (COD)');
    });

    test('an unfinished COD order stays unpaid', () {
      final order = Order.fromJson(<String, dynamic>{
        'status': 'shipped',
        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'Unpaid (COD)',
      }, 'LNT-5');

      expect(order.isPaymentPaid, isFalse);
      expect(order.paymentStatusDisplay, 'Unpaid (COD)');
    });

    test('a paid wallet order keeps its own label', () {
      final order = Order.fromJson(<String, dynamic>{
        'status': 'completed',
        'paymentMethod': 'GCash (Simulated)',
        'paymentStatus': 'Paid (GCash)',
      }, 'LNT-6');

      expect(order.paymentStatusDisplay, 'Paid (GCash)');
    });

    test('a completed order with no stored status derives one', () {
      final order = Order.fromJson(<String, dynamic>{
        'status': 'completed',
        'paymentMethod': 'Cash on Delivery',
      }, 'LNT-7');

      expect(order.paymentStatusDisplay, 'Paid (COD)');
    });

    test('an unfinished order with no stored status still reports it', () {
      final order = Order.fromJson(<String, dynamic>{
        'status': 'pending',
        'paymentMethod': 'Cash on Delivery',
      }, 'LNT-8');

      expect(order.paymentStatusDisplay, 'Not recorded');
    });
  });
}
