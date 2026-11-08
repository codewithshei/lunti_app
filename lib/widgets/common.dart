import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// 48px-tall rounded search field matching the Figma search control.
/// Prototype state: tapping surfaces a note instead of navigating.
class LuntiSearchField extends StatelessWidget {
  const LuntiSearchField({super.key, required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.md),
        decoration: BoxDecoration(
          color: LuntiColors.white,
          borderRadius: BorderRadius.circular(LuntiRadii.sm),
          border: Border.all(color: LuntiColors.beige),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: LuntiColors.secondary),
            const SizedBox(width: LuntiSpacing.sm),
            Text(hint, style: LuntiTextStyles.body),
          ],
        ),
      ),
    );
  }
}

/// Playfair section title with an optional trailing action link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: LuntiTextStyles.sectionTitle)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(LuntiSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: LuntiTextStyles.cardTitle.copyWith(
                        color: LuntiColors.forest,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: LuntiColors.forest,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small uppercase eyebrow label used above headlines.
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel({super.key, required this.text, this.color = LuntiColors.ink});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: LuntiTextStyles.eyebrow.copyWith(color: color),
    );
  }
}
