import 'package:admin_dashboard/models/order.dart';

/// Revenue collected on a single calendar day.
class DailyRevenue {
  const DailyRevenue({required this.date, required this.total});

  /// Midnight of the day this bucket covers.
  final DateTime date;

  /// Sum of `Order.total` for that day, in pesos.
  final int total;
}

/// Daily revenue for the trailing [days] days, oldest first.
///
/// Cancelled orders are excluded: a cancelled sale never became revenue, so it
/// must not lift the trend line. Days with no contributing orders stay in the
/// series with a zero total so the x-axis stays continuous.
///
/// [now] is injectable so tests are not tied to the wall clock.
List<DailyRevenue> buildRevenueTrend(
  List<Order> orders, {
  DateTime? now,
  int days = 14,
}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final window = days < 1 ? 1 : days;

  final totals = <DateTime, int>{};
  for (var i = window - 1; i >= 0; i--) {
    totals[DateTime(today.year, today.month, today.day - i)] = 0;
  }

  for (final order in orders) {
    if (order.status == OrderStatus.cancelled) continue;
    final day = DateTime(
      order.createdAt.year,
      order.createdAt.month,
      order.createdAt.day,
    );
    if (!totals.containsKey(day)) continue;
    totals[day] = totals[day]! + order.total;
  }

  final daysInOrder = totals.keys.toList()..sort();
  return [
    for (final day in daysInOrder) DailyRevenue(date: day, total: totals[day]!),
  ];
}

/// Whether at least one order in [orders] contributes to the revenue trend.
///
/// A list made only of cancelled orders has nothing to plot, so the chart
/// shows its empty state instead of a flat zero line.
bool hasRevenueData(List<Order> orders) => orders.any(
      (order) => order.status != OrderStatus.cancelled,
    );

/// Count of orders per status, including cancelled.
Map<OrderStatus, int> countOrdersByStatus(List<Order> orders) {
  final counts = <OrderStatus, int>{};
  for (final status in OrderStatus.values) {
    counts[status] = 0;
  }
  for (final order in orders) {
    counts[order.status] = (counts[order.status] ?? 0) + 1;
  }
  return counts;
}
