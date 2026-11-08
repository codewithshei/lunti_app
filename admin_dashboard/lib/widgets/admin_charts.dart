import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/services/dashboard_analytics.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

const List<String> _monthShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Revenue trend over the trailing [days] days.
///
/// Cancelled orders are never counted: [buildRevenueTrend] drops them before
/// bucketing, so a cancelled sale cannot lift the line. When nothing in the
/// window contributes revenue the card shows a friendly empty state instead of
/// a blank chart.
class RevenueTrendChart extends StatelessWidget {
  const RevenueTrendChart({
    super.key,
    required this.orders,
    this.days = 14,
    this.now,
  });

  final List<Order> orders;
  final int days;

  /// Injectable clock for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final series = buildRevenueTrend(orders, now: now, days: days);
    final total = series.fold<int>(0, (sum, day) => sum + day.total);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeading(
            title: 'Revenue trend',
            subtitle: 'Daily revenue · last $days days · cancelled excluded',
            trailing: total <= 0
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPeso(total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$days-day total',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AdminColors.muted,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          if (!hasRevenueData(orders))
            _ChartEmptyState(
              icon: Icons.show_chart_outlined,
              title: 'No revenue to chart yet',
              message:
                  'Revenue from the last $days days will be plotted here. '
                  'Cancelled orders are never counted.',
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(_buildLineChartData(series)),
            ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(List<DailyRevenue> series) {
    final lineColor = AdminColors.sageDeep;
    final maxValue = series.fold<double>(
      0,
      (max, day) => day.total > max ? day.total.toDouble() : max,
    );
    // A flat series still needs a usable axis range, otherwise fl_chart draws
    // the single value against a zero-height plot.
    final maxY = maxValue <= 0 ? 1000.0 : maxValue * 1.25;

    return LineChartData(
      minX: 0,
      maxX: (series.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      backgroundColor: Colors.transparent,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AdminColors.border.withValues(alpha: 0.55),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (value, meta) => Text(
              _formatAxisPeso(value),
              style: const TextStyle(color: AdminColors.muted, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 3,
            maxIncluded: false,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= series.length) {
                return const SizedBox.shrink();
              }
              return Text(
                _formatDayLabel(series[index].date),
                style: const TextStyle(color: AdminColors.muted, fontSize: 10),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < series.length; i++)
              FlSpot(i.toDouble(), series[i].total.toDouble()),
          ],
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: lineColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.28),
                lineColor.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => AdminColors.surfaceAlt,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipBorder: const BorderSide(color: AdminColors.border),
          getTooltipItems: (touchedSpots) => [
            for (final spot in touchedSpots)
              if (spot.spotIndex >= 0 && spot.spotIndex < series.length)
                LineTooltipItem(
                  '${_formatDayLabel(series[spot.spotIndex].date)}\n'
                  '${formatPeso(spot.y.round())}',
                  const TextStyle(
                    color: AdminColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Donut of order counts per status, with a legend that includes cancelled.
class OrderStatusDonutChart extends StatelessWidget {
  const OrderStatusDonutChart({super.key, required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final counts = countOrdersByStatus(orders);
    final total = orders.length;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeading(
            title: 'Orders by status',
            subtitle: 'All $total orders · including cancelled',
          ),
          const SizedBox(height: 20),
          if (total == 0)
            const _ChartEmptyState(
              icon: Icons.donut_small_outlined,
              title: 'No orders to chart yet',
              message:
                  'Order statuses will appear here once the shop receives its '
                  'first order.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final donut = _StatusDonut(counts: counts);
                final legend = _StatusLegend(counts: counts, total: total);
                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: donut),
                      const SizedBox(height: 20),
                      legend,
                    ],
                  );
                }
                return Row(
                  children: [
                    donut,
                    const SizedBox(width: 24),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatusDonut extends StatelessWidget {
  const _StatusDonut({required this.counts});

  final Map<OrderStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      height: 164,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 48,
          sectionsSpace: 2,
          sections: [
            for (final status in OrderStatus.values)
              PieChartSectionData(
                value: counts[status]!.toDouble(),
                color: statusColor(status),
                radius: 24,
                showTitle: false,
                borderSide: BorderSide.none,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend({required this.counts, required this.total});

  final Map<OrderStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < OrderStatus.values.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _LegendRow(
            status: OrderStatus.values[i],
            count: counts[OrderStatus.values[i]] ?? 0,
            total: total,
          ),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.status,
    required this.count,
    required this.total,
  });

  final OrderStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final empty = count == 0;
    final color = empty ? AdminColors.border : statusColor(status);
    final labelColor = empty ? AdminColors.muted : AdminColors.text;
    final percent = total == 0 ? 0 : (count / total * 100).round();

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            status.label,
            style: TextStyle(fontSize: 13, color: labelColor),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: AdminColors.muted),
          ),
        ),
      ],
    );
  }
}

class _ChartHeading extends StatelessWidget {
  const _ChartHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AdminColors.muted),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AdminColors.muted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDayLabel(DateTime date) =>
    '${date.day} ${_monthShort[date.month - 1]}';

String _formatAxisPeso(double value) {
  final rounded = value.round();
  if (rounded >= 1000000) {
    return '\u20B1${(rounded / 1000000).toStringAsFixed(1)}M';
  }
  if (rounded >= 10000) {
    return '\u20B1${(rounded / 1000).round()}k';
  }
  if (rounded >= 1000) {
    return '\u20B1${(rounded / 1000).toStringAsFixed(1)}k';
  }
  return '\u20B1$rounded';
}
