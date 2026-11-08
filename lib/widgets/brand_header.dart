import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'pressable.dart';

/// Circular icon action used in the header (shopping bag) and elsewhere.
class LuntiIconButton extends StatelessWidget {
  const LuntiIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.9,
      child: Material(
        color: context.lunti.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: context.lunti.text,
              semanticLabel: label,
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar used across LUNTI screens: optional back chevron, the LUNTI
/// leaf mark and wordmark (optionally with a location) and a bag action
/// with an optional item-count badge.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.onBagPressed,
    this.onBack,
    this.location,
    this.bagCount = 0,
    this.bagListenable,
    this.icon = Icons.shopping_bag_outlined,
    this.showBadge = true,
    this.actions = const <Widget>[],
  });

  /// Opens the shopping bag. Pass null on screens where the trailing icon is
  /// informational only (for example the Checkout lock), which renders a
  /// non-interactive status icon instead of a dead button.
  final VoidCallback? onBagPressed;
  final VoidCallback? onBack;
  final String? location;
  final int bagCount;

  /// Optional live bag counter so the badge updates reactively (SAMPLE
  /// MockAppState today, real cart state later). Overrides [bagCount].
  final ValueListenable<int>? bagListenable;

  /// Trailing icon: the bag on shop screens, a lock on Checkout (frame 11).
  final IconData icon;

  /// Whether the count badge shows (hidden on the Checkout lock).
  final bool showBadge;

  /// Extra header actions shown before the bag (for example the notification
  /// bell on Home and Catalog).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
      child: Row(
        children: [
          if (onBack != null) ...[
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: SizedBox(
                  width: 40,
                  height: 44,
                  child: Icon(
                    Icons.chevron_left,
                    size: 26,
                    color: context.lunti.text,
                    semanticLabel: 'Back',
                  ),
                ),
              ),
            ),
            const SizedBox(width: LuntiSpacing.xs),
          ],
          const _LuntiLeafMark(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUNTI',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                    color: context.lunti.text,
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 2),
                  Text(location!, style: context.lunti.caption),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            for (final action in actions) ...[
              action,
              const SizedBox(width: LuntiSpacing.xs),
            ],
          ],
          if (bagListenable != null)
            ValueListenableBuilder<int>(
              valueListenable: bagListenable!,
              builder: (context, count, _) => _BagButton(
                count: count,
                onPressed: onBagPressed,
                icon: icon,
                showBadge: showBadge,
              ),
            )
          else
            _BagButton(
              count: bagCount,
              onPressed: onBagPressed,
              icon: icon,
              showBadge: showBadge,
            ),
        ],
      ),
    );
  }
}

class _BagButton extends StatelessWidget {
  const _BagButton({
    required this.count,
    required this.onPressed,
    required this.icon,
    this.showBadge = true,
  });

  final int count;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final label =
        icon == Icons.lock_outline ? 'Protected checkout' : 'Shopping bag';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (onPressed != null)
          LuntiIconButton(
            icon: icon,
            label: label,
            onPressed: onPressed!,
          )
        else
          Semantics(
            label: label,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 20, color: context.lunti.text),
            ),
          ),
        if (showBadge && count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: context.lunti.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: context.lunti.navLabel.copyWith(
                  color: context.lunti.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact leaf mark that replaces the old "Hane" logo image, keeping the
/// header brand to a single green icon + LUNTI wordmark.
class _LuntiLeafMark extends StatelessWidget {
  const _LuntiLeafMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LUNTI leaf logo',
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.lunti.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.eco_rounded,
          size: 20,
          color: context.lunti.accent,
        ),
      ),
    );
  }
}
