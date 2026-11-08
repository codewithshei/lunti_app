import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'pressable.dart';

/// The single card surface used across LUNTI.
///
/// Every card shares the same white fill, hairline beige border, corner radius
/// and resting shadow, so the catalog, orders, profile and checkout read as one
/// system rather than each screen hand-rolling its own decoration.
class LuntiCard extends StatelessWidget {
  const LuntiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LuntiSpacing.md),
    this.radius = LuntiRadii.md,
    this.color,
    this.borderColor,
    this.shadow = LuntiShadows.card,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  /// A card with no border and no shadow, for content nested inside another
  /// surface (list rows, inner panels, tiles on tinted backgrounds).
  const LuntiCard.flat({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LuntiSpacing.md),
    this.radius = LuntiRadii.md,
    this.color,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  }) : shadow = const <BoxShadow>[];

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow> shadow;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color ?? LuntiColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? LuntiColors.beige),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap == null) return surface;
    return PressableScale(onTap: onTap!, pressedScale: 0.98, child: surface);
  }
}

/// A row of summary content inside a [LuntiCard]: label on the left, value on
/// the right, separated by a hairline.
class LuntiSummaryRow extends StatelessWidget {
  const LuntiSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final style = emphasis
        ? LuntiTextStyles.price.copyWith(
            fontSize: 14,
            color: valueColor ?? LuntiColors.ink,
          )
        : LuntiTextStyles.body.copyWith(
            color: valueColor ?? LuntiColors.ink,
            fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: LuntiTextStyles.body)),
          const SizedBox(width: LuntiSpacing.sm),
          Text(value, style: style, textAlign: TextAlign.right),
        ],
      ),
    );
  }
}
