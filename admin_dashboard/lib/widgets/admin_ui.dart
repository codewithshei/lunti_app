import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';

import 'package:admin_dashboard/models/order.dart';
import 'package:admin_dashboard/theme.dart';

/// Human-readable, actionable message for a failed order status update.
///
/// A `permission-denied` here almost always means the rules deployed on the
/// project predate a field this write sends — the `statusHistory` audit trail
/// is the usual culprit — so point at the fix instead of reporting a bare
/// failure that gives the admin nothing to act on.
String orderStatusErrorMessage(Order order, Object error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Firestore rejected the update on ${order.shortId} '
          '(permission-denied). The deployed firestore.rules do not allow '
          'every field this write sends — redeploy firestore.rules.';
    }
    return 'Could not update ${order.shortId} (${error.code}).';
  }
  return 'Could not update ${order.shortId}: $error';
}

String formatPeso(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}\u20B1$buffer';
}

String formatDate(DateTime date) {
  const months = [
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
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${months[date.month - 1]} ${date.day}, ${date.year} '
      '\u00B7 $hour:$minute $suffix';
}

Color statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AdminColors.warning;
    case OrderStatus.approved:
      return AdminColors.info;
    case OrderStatus.packed:
      return AdminColors.violet;
    case OrderStatus.shipped:
      return AdminColors.teal;
    case OrderStatus.completed:
      return AdminColors.success;
    case OrderStatus.cancelled:
      return AdminColors.danger;
  }
}

/// Icon paired with each [OrderStatus] on the status badge.
///
/// [statusColor] already gives every status its own colour, which the donut
/// chart needs so no two slices look alike. The glyph is added on top so a
/// colour-blind admin (or a dense table) can still tell statuses apart.
IconData statusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.schedule;
    case OrderStatus.approved:
      return Icons.check_circle_outline;
    case OrderStatus.packed:
      return Icons.inventory_2;
    case OrderStatus.shipped:
      return Icons.local_shipping;
    case OrderStatus.completed:
      return Icons.task_alt;
    case OrderStatus.cancelled:
      return Icons.cancel;
  }
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AdminColors.muted),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Optional pastel accent. When set, the card gets a soft tinted gradient
  /// instead of a flat white surface, keeping the dashboard airy and dreamy.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final accent = tint;
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent == null ? AdminColors.surface : null,
        gradient: accent == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.18),
                    AdminColors.surface,
                  ),
                  AdminColors.surface,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: AdminColors.shadow,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x0A233A2A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Asks the admin to confirm cancelling [order].
///
/// Cancelling returns every item to stock, so it is always destructive.
Future<bool> confirmOrderCancellation(BuildContext context, Order order) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this order?'),
      content: Text(
        '${order.shortId} will be marked cancelled and its items returned '
        'to stock. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep order'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AdminColors.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel order'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Compact status badge: status icon + label on a tinted pill.
///
/// The tint is the status colour at 15% over the white card surface and the
/// border is the same colour at 50%, so the darkened semantic label keeps a
/// comfortable contrast ratio against its pastel background.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status, this.semanticsLabel});

  final OrderStatus status;

  /// Optional screen-reader/tooltip text. Defaults to [OrderStatus.label].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final label = semanticsLabel ?? status.label;
    return Tooltip(
      message: label,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon(status), size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                status.label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payment status badge shared by the order list and order detail page.
class AdminPaymentChip extends StatelessWidget {
  const AdminPaymentChip({super.key, required this.status});

  final String status;

  bool get _isPaid => status.trim().toLowerCase().startsWith('paid');

  @override
  Widget build(BuildContext context) {
    final color = _isPaid ? AdminColors.success : AdminColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AdminColors.muted),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AdminColors.muted),
          ),
        ],
      ),
    );
  }
}
