import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';

Order _order({String id = 'LNT-17941234'}) {
  return Order(
    id: id,
    userId: 'u1',
    items: const <Map<String, dynamic>>[],
    subtotal: 0,
    shippingFee: 0,
    total: 0,
    fullName: 'Maya Santos',
    address: 'Cardona, Rizal',
    phone: '0917',
    paymentMethod: 'Cash on Delivery',
    status: OrderStatus.pending,
    createdAt: DateTime(2026, 11, 8),
  );
}

void main() {
  group('orderStatusErrorMessage', () {
    test('explains permission-denied and names the fix', () {
      final message = orderStatusErrorMessage(
        _order(),
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      expect(message, contains('LNT-1234'));
      expect(message, contains('permission-denied'));
      expect(message, contains('redeploy firestore.rules'));
    });

    test('includes the Firestore error code for other failures', () {
      final message = orderStatusErrorMessage(
        _order(),
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(message, contains('unavailable'));
      expect(message, contains('LNT-1234'));
      expect(message, isNot(contains('permission-denied')));
    });

    test('falls back to the raw error for non-Firestore exceptions', () {
      final message = orderStatusErrorMessage(
        _order(),
        StateError('Order LNT-1794abcd was not found.'),
      );

      expect(message, contains('LNT-1234'));
      expect(message, contains('was not found'));
    });

    test('uses the full id when it is short enough to be unambiguous', () {
      final message = orderStatusErrorMessage(
        _order(id: 'LNT-1794'),
        StateError('nope'),
      );

      expect(message, contains('LNT-1794'));
      expect(message, isNot(contains('#')));
    });
  });
}
