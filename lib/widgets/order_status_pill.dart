import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/mock_app_state.dart';

/// Small status chip shared by Order History and Order Details so the same
/// canonical status always reads the same way across the app.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.cancelled => LuntiColors.warning,
      OrderStatus.completed => LuntiColors.forest,
      OrderStatus.pending => LuntiColors.secondary,
      _ => LuntiColors.forest,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: LuntiTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
