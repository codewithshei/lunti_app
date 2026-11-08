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
          color: context.lunti.surface,
          borderRadius: BorderRadius.circular(LuntiRadii.sm),
          border: Border.all(color: context.lunti.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: context.lunti.textFaint),
            const SizedBox(width: LuntiSpacing.sm),
            Text(hint, style: context.lunti.body),
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
          Expanded(child: Text(title, style: context.lunti.sectionTitle)),
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
                      style: context.lunti.cardTitle.copyWith(
                        color: context.lunti.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: context.lunti.accent,
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
  const EyebrowLabel({super.key, required this.text, this.color});

  final String text;

  /// Optional override; defaults to the palette's primary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.lunti.eyebrow.copyWith(color: color),
    );
  }
}
