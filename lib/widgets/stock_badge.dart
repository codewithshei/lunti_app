import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Small "Out of Stock" pill shown over product photos.
class OutOfStockBadge extends StatelessWidget {
  const OutOfStockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Out of stock',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: LuntiColors.ink,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Out of Stock',
          style: LuntiTextStyles.caption.copyWith(
            color: LuntiColors.cream,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// Inline stock warning shared by the bag and checkout lines.
///
/// [available] is the stock left at the time of the check. A zero stock shows
/// "Out of stock"; otherwise the exact "Only X items available in stock"
/// wording is used everywhere.
class StockWarningText extends StatelessWidget {
  const StockWarningText({super.key, required this.available});

  final int available;

  @override
  Widget build(BuildContext context) {
    final text = available <= 0
        ? 'Out of stock'
        : 'Only $available items available in stock';
    return Text(
      text,
      style: LuntiTextStyles.caption.copyWith(
        color: LuntiColors.warning,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
