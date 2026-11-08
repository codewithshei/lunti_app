import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/models/admin_product.dart';
import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_charts.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _database = AdminDatabase();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _database.getAllOrders(),
      builder: (context, orderSnapshot) {
        final orders = orderSnapshot.data ?? const <Order>[];
        return StreamBuilder<List<AdminProduct>>(
          stream: _database.watchProducts(),
          builder: (context, productSnapshot) {
            final products = productSnapshot.data ?? const <AdminProduct>[];
            return _DashboardBody(
              orders: orders,
              productCount: products.length,
              loading:
                  orderSnapshot.connectionState == ConnectionState.waiting &&
                  !orderSnapshot.hasData,
            );
          },
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.orders,
    required this.productCount,
    required this.loading,
  });

  final List<Order> orders;
  final int productCount;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;
    final completed = orders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final revenue = orders.fold<int>(0, (sum, order) => sum + order.total);
    final recent = orders.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      children: [
        AdminPageHeader(
          title: 'Dashboard',
          subtitle: 'Live orders and catalog health for the LUNTI shop.',
          trailing: FilledButton.icon(
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Open orders'),
          ),
        ),
        const SizedBox(height: 24),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _KpiCard(
              label: 'Total orders',
              value: '${orders.length}',
              caption: '$completed completed',
              icon: Icons.receipt_long_outlined,
              color: AdminColors.info,
            ),
            _KpiCard(
              label: 'Order value',
              value: formatPeso(revenue),
              caption: 'Across all statuses',
              icon: Icons.payments_outlined,
              color: AdminColors.success,
            ),
            _KpiCard(
              label: 'Needs action',
              value: '$pending',
              caption: pending == 1 ? 'Pending order' : 'Pending orders',
              icon: Icons.pending_actions_outlined,
              color: AdminColors.warning,
            ),
            _KpiCard(
              label: 'Products live',
              value: '$productCount',
              caption: 'In the mobile catalog',
              icon: Icons.inventory_2_outlined,
              color: AdminColors.violet,
            ),
          ],
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final revenue = RevenueTrendChart(orders: orders);
            final status = OrderStatusDonutChart(orders: orders);
            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: revenue),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: status),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [revenue, const SizedBox(height: 16), status],
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent orders',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/orders'),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          const AdminEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message:
                'Place an order from the LUNTI mobile app and it will appear '
                'here in real time.',
          )
        else
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _RecentOrderRow(order: recent[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 218,
      child: AdminCard(
        tint: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.9,
                    color: AdminColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: AdminColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: const TextStyle(color: AdminColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/orders/detail/${order.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.shortId} \u00B7 ${order.itemCount} item(s)',
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatPeso(order.total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            AdminStatusChip(status: order.status),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AdminColors.muted),
          ],
        ),
      ),
    );
  }
}
