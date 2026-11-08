import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'controls.dart';
import 'lunti_card.dart';

/// Friendly empty state: icon in a sage circle, a title, supporting copy and an
/// optional call to action.
///
/// Replaces the bare one-line "Nothing here yet" placeholders so an empty
/// screen still explains what the section is for and where to go next.
class LuntiEmptyState extends StatelessWidget {
  const LuntiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Smaller icon and padding, for empty regions inside a scroll view.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 52 : 68,
              height: compact ? 52 : 68,
              decoration: BoxDecoration(
                color: context.lunti.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 24 : 30,
                color: context.lunti.accent,
              ),
            ),
            SizedBox(height: compact ? LuntiSpacing.sm : LuntiSpacing.md),
            Text(
              title,
              style: context.lunti.sectionTitle.copyWith(
                fontSize: compact ? 17 : 21,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message,
                style: context.lunti.body,
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: LuntiSpacing.md),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                height: 44,
              ),
            ],
          ],
        );

        final padded = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: LuntiSpacing.lg,
            vertical: compact ? LuntiSpacing.md : LuntiSpacing.lg,
          ),
          child: content,
        );

        // Inside a scroll view the height is unbounded, so vertical centering
        // is impossible — just lay the content out from the top.
        if (!constraints.maxHeight.isFinite) return padded;
        return Center(child: padded);
      },
    );
  }
}

/// Full-screen loading placeholder.
///
/// Shows a branded skeleton with a short label instead of a bare spinner, so
/// the shape of the arriving content is visible while it loads.
class LuntiLoadingState extends StatelessWidget {
  const LuntiLoadingState({
    super.key,
    this.label = 'Loading…',
    this.rows = 3,
  });

  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LuntiCard(
          padding: const EdgeInsets.all(LuntiSpacing.lg),
          child: Column(
            children: [
              for (var i = 0; i < rows; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuntiSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.lunti.surfaceAlt,
                          borderRadius: BorderRadius.circular(LuntiRadii.sm),
                        ),
                      ),
                      const SizedBox(width: LuntiSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: context.lunti.surfaceAlt,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 96,
                              height: 10,
                              decoration: BoxDecoration(
                                color: context.lunti.border,
                                borderRadius: BorderRadius.circular(5),
                              ),
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
        const SizedBox(height: LuntiSpacing.md),
        Text(label, style: context.lunti.caption),
      ],
    );
  }
}

/// Error state with a retry action, used when a stream or fetch fails.
class LuntiErrorState extends StatelessWidget {
  const LuntiErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return LuntiEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
    );
  }
}
