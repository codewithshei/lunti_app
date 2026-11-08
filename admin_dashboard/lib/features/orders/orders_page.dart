import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/features/auth/services/auth_service.dart';
import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_data_table.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _database = AdminDatabase();
  OrderStatus? _filter;
  String? _updatingId;

  List<Order> _visible(List<Order> orders) {
    if (_filter == null) return orders;
    return orders.where((order) => order.status == _filter).toList();
  }

  Future<void> _updateStatus(Order order, OrderStatus status) async {
    if (!AdminDatabase.canTransition(order.status, status)) {
      _showMessage(
        'Cannot move ${order.shortId} from ${order.status.label} to '
        '${status.label}.',
      );
      return;
    }

    if (status == OrderStatus.cancelled) {
      final confirmed = await confirmOrderCancellation(context, order);
      if (!confirmed) return;
    }

    setState(() => _updatingId = order.id);
    try {
      await _database.updateOrderStatus(
        order.id,
        status,
        actor: AuthService.instance.currentUser?.uid ?? '',
      );
      if (!mounted) return;
      _showMessage('${order.shortId} marked ${status.label.toLowerCase()}.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(orderStatusErrorMessage(order, error));
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _database.getAllOrders(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <Order>[];
        final orders = _visible(all);
        final loading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          children: [
            AdminPageHeader(
              title: 'Orders',
              subtitle:
                  'Filter incoming orders and move each one through fulfilment.',
              trailing: OutlinedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('Overview'),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: all.length,
                    selected: _filter == null,
                    onSelected: () => setState(() => _filter = null),
                  ),
                  for (final status in OrderStatus.values) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: status.label,
                      count: all.where((o) => o.status == status).length,
                      selected: _filter == status,
                      onSelected: () => setState(() => _filter = status),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              AdminCard(
                child: Text(
                  'Could not load orders.\n${snapshot.error}',
                  style: const TextStyle(color: AdminColors.danger),
                ),
              )
            else if (loading)
              const AdminCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (orders.isEmpty)
              AdminEmptyState(
                icon: Icons.receipt_long_outlined,
                title: all.isEmpty ? 'No orders yet' : 'Nothing in this status',
                message: all.isEmpty
                    ? 'Orders placed in the LUNTI mobile app appear here in '
                          'real time.'
                    : 'Try another filter to see the rest of the queue.',
              )
            else
              AdminCard(
                padding: EdgeInsets.zero,
                child: AdminDataTable(
                  columns: const [
                    AdminTableColumn('Order'),
                    AdminTableColumn('Customer'),
                    AdminTableColumn('Placed'),
                    AdminTableColumn('Items'),
                    AdminTableColumn('Total'),
                    AdminTableColumn('Payment'),
                    AdminTableColumn('Status'),
                    AdminTableColumn('Actions'),
                  ],
                  rows: [
                    for (final order in orders)
                      AdminTableRow([
                        Tooltip(
                          message: 'Order ID: ${order.id}',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AdminColors.mint,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Text(
                              order.shortId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 190),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${order.itemCount} item(s)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AdminColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            formatDate(order.createdAt),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 210),
                          child: Text(
                            _itemSummary(order),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          formatPeso(order.total),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        AdminPaymentChip(status: order.paymentStatusDisplay),
                        AdminStatusChip(status: order.status),
                        _OrderActions(
                          order: order,
                          updating: _updatingId == order.id,
                          onOpen: () =>
                              context.go('/orders/detail/${order.id}'),
                          onUpdate: (status) => _updateStatus(order, status),
                        ),
                      ]),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static String _itemSummary(Order order) {
    if (order.items.isEmpty) return 'No items recorded';
    final names = order.items
        .map((item) => '${item['productName'] ?? item['productId'] ?? 'Item'}')
        .take(2)
        .toList();
    final extra = order.items.length - names.length;
    return '${names.join(', ')}${extra > 0 ? ' +$extra more' : ''}';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AdminColors.sage : AdminColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AdminColors.sage : AdminColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AdminColors.ink : AdminColors.text,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AdminColors.ink.withValues(alpha: 0.12)
                    : AdminColors.surfaceAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? AdminColors.ink : AdminColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row-level actions: open the detail page, cancel, or advance fulfilment.
class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.updating,
    required this.onOpen,
    required this.onUpdate,
  });

  final Order order;
  final bool updating;
  final VoidCallback onOpen;
  final ValueChanged<OrderStatus> onUpdate;

  OrderStatus? get _nextStatus {
    switch (order.status) {
      case OrderStatus.pending:
        return OrderStatus.approved;
      case OrderStatus.approved:
        return OrderStatus.packed;
      case OrderStatus.packed:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.completed;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus;
    final canCancel =
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.completed;

    if (updating) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onOpen,
          style: TextButton.styleFrom(
            foregroundColor: AdminColors.forest,
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Details'),
        ),
        if (canCancel) ...[
          OutlinedButton(
            onPressed: () => onUpdate(OrderStatus.cancelled),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.danger,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
        ],
        if (next != null)
          FilledButton(
            onPressed: () => onUpdate(next),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text('Mark ${next.label.toLowerCase()}'),
          ),
      ],
    );
  }
}
