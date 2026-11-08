import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/payment_method.dart';

/// Small pill that explains whether a method is simulated or a real COD
/// payment. Shared by Checkout, the payment picker and the receipt.
class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final real = !method.isSimulated;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: real ? LuntiColors.forest : LuntiColors.sage,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: real ? LuntiColors.forest : LuntiColors.beige,
        ),
      ),
      child: Text(
        method.badgeLabel,
        style: LuntiTextStyles.caption.copyWith(
          color: real ? LuntiColors.cream : LuntiColors.forest,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Receipt badge for the saved payment status, e.g. "Paid (GCash)" or
/// "Unpaid (COD)".
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  bool get _isPaid => status.trim().toLowerCase().startsWith('paid');

  @override
  Widget build(BuildContext context) {
    final color = _isPaid ? LuntiColors.forest : LuntiColors.warning;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.isEmpty ? 'Not recorded' : status,
        style: LuntiTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 9 : 11,
        ),
      ),
    );
  }
}
