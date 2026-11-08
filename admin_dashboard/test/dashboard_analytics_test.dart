import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/services/dashboard_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

Order _order({
  required String id,
  required OrderStatus status,
  required DateTime createdAt,
  int total = 100,
}) {
  return Order(
    id: id,
    userId: 'u-$id',
    items: const <Map<String, dynamic>>[],
    subtotal: total,
    shippingFee: 0,
    total: total,
    fullName: 'Maya Santos',
    address: 'Cardona, Rizal',
    phone: '0917',
    paymentMethod: 'Cash on Delivery',
    status: status,
    createdAt: createdAt,
  );
}

void main() {
  final now = DateTime(2026, 11, 8, 12);

  group('buildRevenueTrend', () {
    test('excludes cancelled orders entirely', () {
      final trend = buildRevenueTrend(
        [
          _order(
            id: 'a',
            status: OrderStatus.completed,
            createdAt: DateTime(2026, 11, 8, 9),
            total: 500,
          ),
          _order(
            id: 'b',
            status: OrderStatus.cancelled,
            createdAt: DateTime(2026, 11, 8, 10),
            total: 9999,
          ),
          _order(
            id: 'c',
            status: OrderStatus.shipped,
            createdAt: DateTime(2026, 11, 7, 23, 59),
            total: 250,
          ),
        ],
        now: now,
        days: 14,
      );

      expect(trend, hasLength(14));
      expect(trend.last.total, 500, reason: 'cancelled 9999 must not count');
      expect(trend[12].total, 250);
      expect(
        trend.fold<int>(0, (sum, day) => sum + day.total),
        750,
      );
    });

    test('keeps a continuous 14-day window with zero-fill for quiet days', () {
      final trend = buildRevenueTrend(
        [
          _order(
            id: 'a',
            status: OrderStatus.completed,
            createdAt: DateTime(2026, 11, 8),
            total: 100,
          ),
        ],
        now: now,
        days: 14,
      );

      expect(trend, hasLength(14));
      expect(trend.first.date, DateTime(2026, 10, 26));
      expect(trend.last.date, DateTime(2026, 11, 8));
      expect(
        trend.where((day) => day.total == 0),
        hasLength(13),
        reason: 'only the day with an order may be non-zero',
      );
    });

    test('drops orders older than the window', () {
      final trend = buildRevenueTrend(
        [
          _order(
            id: 'old',
            status: OrderStatus.completed,
            createdAt: DateTime(2026, 10, 25, 23),
            total: 4000,
          ),
        ],
        now: now,
        days: 14,
      );

      expect(
        trend.fold<int>(0, (sum, day) => sum + day.total),
        0,
      );
    });
  });

  group('hasRevenueData', () {
    test('is false when every order is cancelled', () {
      expect(
        hasRevenueData([
          _order(
            id: 'c',
            status: OrderStatus.cancelled,
            createdAt: now,
            total: 500,
          ),
        ]),
        isFalse,
      );
    });

    test('is true when any order contributes', () {
      expect(
        hasRevenueData([
          _order(
            id: 'c',
            status: OrderStatus.cancelled,
            createdAt: now,
            total: 500,
          ),
          _order(
            id: 'p',
            status: OrderStatus.pending,
            createdAt: now,
            total: 500,
          ),
        ]),
        isTrue,
      );
    });
  });

  group('countOrdersByStatus', () {
    test('counts every status including cancelled', () {
      final counts = countOrdersByStatus([
        _order(id: 'a', status: OrderStatus.pending, createdAt: now),
        _order(id: 'b', status: OrderStatus.pending, createdAt: now),
        _order(id: 'c', status: OrderStatus.cancelled, createdAt: now),
        _order(id: 'd', status: OrderStatus.completed, createdAt: now),
      ]);

      expect(counts[OrderStatus.pending], 2);
      expect(counts[OrderStatus.completed], 1);
      expect(counts[OrderStatus.cancelled], 1);
      expect(counts[OrderStatus.approved], 0);
      expect(counts[OrderStatus.packed], 0);
      expect(counts[OrderStatus.shipped], 0);
      expect(counts.values.fold<int>(0, (sum, value) => sum + value), 4);
    });
  });
}
