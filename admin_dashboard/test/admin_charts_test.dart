import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/widgets/admin_charts.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  final now = DateTime(2026, 11, 8, 12);

  group('AdminStatusChip', () {
    testWidgets('renders the matching icon for every status', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final status in OrderStatus.values)
                AdminStatusChip(status: status),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('exposes the status as semantics and tooltip', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          const AdminStatusChip(
            status: OrderStatus.packed,
            semanticsLabel: 'Packed and ready',
          ),
        ),
      );

      expect(find.byTooltip('Packed and ready'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Packed and ready'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('RevenueTrendChart', () {
    testWidgets('shows an empty state when there is no revenue', (tester) async {
      await tester.pumpWidget(
        _host(
          RevenueTrendChart(
            orders: [
              _order(
                id: 'c',
                status: OrderStatus.cancelled,
                createdAt: now,
                total: 9999,
              ),
            ],
            now: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No revenue to chart yet'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('plots the 14-day trend and ignores cancelled revenue', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          RevenueTrendChart(
            orders: [
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
            ],
            now: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No revenue to chart yet'), findsNothing);
      // The cancelled 9999 must never reach the chart or its total.
      expect(find.text('\u20B19,999'), findsNothing);
      expect(find.text('\u20B1500'), findsWidgets);
    });
  });

  group('OrderStatusDonutChart', () {
    testWidgets('shows an empty state with no orders', (tester) async {
      await tester.pumpWidget(_host(const OrderStatusDonutChart(orders: [])));
      await tester.pumpAndSettle();

      expect(find.text('No orders to chart yet'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('renders a section per status with a legend', (tester) async {
      await tester.pumpWidget(
        _host(
          OrderStatusDonutChart(
            orders: [
              _order(id: 'a', status: OrderStatus.pending, createdAt: now),
              _order(id: 'b', status: OrderStatus.pending, createdAt: now),
              _order(
                id: 'c',
                status: OrderStatus.cancelled,
                createdAt: now,
              ),
              _order(
                id: 'd',
                status: OrderStatus.completed,
                createdAt: now,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
