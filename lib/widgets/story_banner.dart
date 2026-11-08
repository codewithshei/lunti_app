import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'pressable.dart';

/// Dark forest "story" banner: workshop photo over the brand headline,
/// eyebrow and a Discover action, as laid out in the Figma Home frame.
class StoryBanner extends StatelessWidget {
  const StoryBanner({
    super.key,
    required this.eyebrow,
    required this.headline,
    required this.copy,
    required this.actionLabel,
    required this.imageUrl,
    required this.onAction,
  });

  final String eyebrow;
  final String headline;
  final String copy;
  final String actionLabel;
  final String imageUrl;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.985,
      onTap: onAction,
      child: Container(
        decoration: BoxDecoration(
          color: context.lunti.accent,
          borderRadius: BorderRadius.circular(LuntiRadii.lg),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(LuntiRadii.md),
            child: AspectRatio(
              aspectRatio: 342 / 132,
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              LuntiSpacing.md,
              14,
              10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: context.lunti.eyebrow.copyWith(
                    color: context.lunti.surfaceAlt,
                  ),
                ),
                const SizedBox(height: LuntiSpacing.sm),
                Text(
                  headline,
                  style: context.lunti.sectionTitle.copyWith(
                    color: context.lunti.background,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: LuntiSpacing.sm),
                Text(copy, style: context.lunti.onDarkBody),
                const SizedBox(height: LuntiSpacing.md),
                GestureDetector(
                  onTap: onAction,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        actionLabel,
                        style: context.lunti.cardTitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.lunti.surface,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.north_east,
                        size: 18,
                        color: context.lunti.surface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
