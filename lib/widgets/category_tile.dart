import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/sample_catalog.dart';
import 'pressable.dart';

/// Sage category tile with a white image well and centred label.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    this.useShopLabel = false,
  });

  final SampleCategory category;
  final VoidCallback onTap;

  /// Categories screen (frame 03) shows the wider shop labels.
  final bool useShopLabel;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.97,
      child: Material(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(LuntiRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: LuntiColors.white,
                      borderRadius: BorderRadius.circular(LuntiRadii.sm),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(LuntiSpacing.sm),
                    child: Image.asset(
                      category.image,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    useShopLabel ? category.shopLabel : category.label,
                    style: LuntiTextStyles.cardTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed category card used by Home's "Shop by craft" rail.
///
/// The category photo fills the whole card, a bottom-up gradient keeps the
/// white title readable over any image, and the label sits directly on the
/// photo instead of in a separate bar.
class CategoryHeroTile extends StatelessWidget {
  const CategoryHeroTile({
    super.key,
    required this.category,
    required this.onTap,
    this.useShopLabel = false,
  });

  final SampleCategory category;
  final VoidCallback onTap;

  /// Categories screen (frame 03) shows the wider shop labels.
  final bool useShopLabel;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.97,
      child: Material(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(LuntiRadii.md),
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                category.image,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              // Subtle bottom-up scrim so the white title stays readable over
              // both light and dark product photos.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.55, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(0x2E27372D),
                      Color(0xD927372D),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(LuntiSpacing.md),
                  child: Text(
                    useShopLabel ? category.shopLabel : category.label,
                    style: LuntiTextStyles.cardTitle.copyWith(
                      color: LuntiColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
