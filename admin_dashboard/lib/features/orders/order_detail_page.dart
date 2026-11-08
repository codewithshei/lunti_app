import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/features/auth/services/auth_service.dart';
import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _database = AdminDatabase();
  bool _updating = false;

  Future<void> _setStatus(Order order, OrderStatus status) async {
    if (!AdminDatabase.canTransition(order.status, status)) {
      _showMessage(
        'Cannot move ${order.shortId} from ${order.status.label} to '
        '${status.label}.',
      );
      return;
    }

    if (status == OrderStatus.cancelled) {
      final confirmed = await _confirmCancel(order);
      if (!confirmed) return;
    }

    setState(() => _updating = true);
    try {
      await _database.updateOrderStatus(
        widget.orderId,
        status,
        actor: AuthService.instance.currentUser?.uid ?? '',
      );
      if (!mounted) return;
      _showMessage('Order marked ${status.label.toLowerCase()}.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(orderStatusErrorMessage(order, error));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// Cancelling returns stock to the shelf, so it always asks first.
  Future<bool> _confirmCancel(Order order) =>
      confirmOrderCancellation(context, order);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order?>(
      stream: _database.watchOrder(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MissingOrder(
            message: 'Could not load this order.',
            detail: snapshot.error.toString(),
          );
        }
        final order = snapshot.data;
        if (order == null) {
          return const _MissingOrder(
            message: 'Order not found',
            detail: 'It may have been removed from Firestore.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          children: [
            AdminPageHeader(
              title: 'Order ${order.shortId}',
              subtitle:
                  'Placed ${formatDate(order.createdAt)} \u00B7 ${order.itemCount} item(s)',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminStatusChip(status: order.status),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/orders'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Orders'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final customer = _CustomerCard(order: order);
                final items = _ItemsCard(order: order);
                if (!wide) {
                  return Column(
                    children: [customer, const SizedBox(height: 16), items],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: customer),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: items),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PAYMENT SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TotalRow(
                    label: 'Subtotal',
                    value: formatPeso(order.subtotal),
                  ),
                  const SizedBox(height: 8),
                  _TotalRow(
                    label: 'Shipping',
                    value: formatPeso(order.shippingFee),
                  ),
                  const Divider(height: 26),
                  _TotalRow(
                    label: 'Total',
                    value: formatPeso(order.total),
                    bold: true,
                  ),
                  const SizedBox(height: 8),
                  _TotalRow(
                    label: 'Payment method',
                    value: order.paymentDisplay,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Payment status',
                        style: TextStyle(color: AdminColors.muted),
                      ),
                      const Spacer(),
                      AdminPaymentChip(status: order.paymentStatusDisplay),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UPDATE STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The customer\'s tracking screen updates in real time.',
                    style: TextStyle(color: AdminColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final status in OrderStatus.values)
                        _StatusButton(
                          status: status,
                          current: order.status == status,
                          // Highlight the next fulfilment step so the obvious
                          // action is the one that stands out.
                          primary: status != OrderStatus.cancelled &&
                              AdminDatabase.canTransition(order.status, status),
                          enabled:
                              !_updating &&
                              AdminDatabase.canTransition(order.status, status),
                          onPressed: () => _setStatus(order, status),
                        ),
                      if (_updating)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  if (order.statusHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const Text(
                      'STATUS HISTORY',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: AdminColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final entry in order.statusHistory)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            AdminStatusChip(status: entry.status),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.by.isEmpty
                                    ? formatDate(entry.at)
                                    : '${formatDate(entry.at)} · ${entry.by}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AdminColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMER',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AdminColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AdminColors.sage,
                child: Text(
                  _initials(order.fullName),
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _InfoLabel('Delivery address'),
          const SizedBox(height: 4),
          Text(order.address, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 14),
          const _InfoLabel('Phone'),
          const SizedBox(height: 4),
          Text(order.phone.isEmpty ? 'Not provided' : order.phone),
          const SizedBox(height: 14),
          const _InfoLabel('Payment'),
          const SizedBox(height: 4),
          Text(order.paymentDisplay),
          const SizedBox(height: 6),
          AdminPaymentChip(status: order.paymentStatusDisplay),
          if (order.userId.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _InfoLabel('Customer account'),
            const SizedBox(height: 4),
            Text(
              order.userId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'L';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ITEMS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AdminColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (order.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No line items were recorded for this order.',
                style: TextStyle(color: AdminColors.muted),
              ),
            )
          else
            for (var i = 0; i < order.items.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _ItemRow(item: order.items[i]),
            ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = '${item['productName'] ?? item['productId'] ?? 'Item'}';
    final variant = '${item['variant'] ?? ''}'.trim();
    final engraving = '${item['engravingText'] ?? ''}'.trim();
    final quantity = item['quantity'] ?? 1;
    final unitPrice = item['unitPrice'];
    final lineTotal = item['lineTotal'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AdminColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.spa_outlined,
            size: 18,
            color: AdminColors.forest,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                [
                  if (variant.isNotEmpty) variant,
                  'Qty $quantity',
                  if (unitPrice != null) formatPeso(_asInt(unitPrice)),
                ].join(' \u00B7 '),
                style: const TextStyle(color: AdminColors.muted, fontSize: 12),
              ),
              if (engraving.isNotEmpty)
                Text(
                  'Engraved: "$engraving"',
                  style: const TextStyle(
                    color: AdminColors.forest,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Text(
          lineTotal == null ? '' : formatPeso(_asInt(lineTotal)),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AdminColors.ink : AdminColors.muted,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AdminColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.current,
    required this.primary,
    required this.enabled,
    required this.onPressed,
  });

  final OrderStatus status;
  final bool current;

  /// Whether this is the next step in fulfilment, rendered as the solid
  /// primary action so the obvious move is the one that stands out.
  final bool primary;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    if (current) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          '${status.label} (current)',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (primary) {
      return FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(status.label),
      );
    }

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: status == OrderStatus.cancelled
            ? AdminColors.danger
            : AdminColors.forest,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(status.label),
    );
  }
}

class _MissingOrder extends StatelessWidget {
  const _MissingOrder({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/orders'),
            child: const Text('Back to orders'),
          ),
        ],
      ),
    );
  }
}
