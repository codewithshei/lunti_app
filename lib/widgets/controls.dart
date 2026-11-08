import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'pressable.dart';

/// Pill-shaped chip used for category filters, sort and suggestions.
class LuntiChip extends StatelessWidget {
  const LuntiChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.96,
      child: Material(
        color: selected ? LuntiColors.forest : LuntiColors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? LuntiColors.forest : LuntiColors.beige,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LuntiSpacing.md,
              vertical: 10,
            ),
            child: Text(
              label,
              style: LuntiTextStyles.cardTitle.copyWith(
                color: selected ? LuntiColors.cream : LuntiColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width (or inline) dark forest filled button, matching the
/// "Explore all products" / "View product" controls in Figma.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 52,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = PressableScale(
      pressedScale: 0.97,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: LuntiColors.forest,
          foregroundColor: LuntiColors.white,
          minimumSize: Size(expand ? double.infinity : 0, height),
          textStyle: LuntiTextStyles.cardTitle.copyWith(
            fontWeight: FontWeight.w600,
            color: LuntiColors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.md),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
    return button;
  }
}

/// Quantity stepper matching Figma frames 02/08: - value + inside a
/// bordered white container.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
        border: Border.all(color: LuntiColors.beige),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            label: 'Decrease quantity',
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: LuntiTextStyles.cardTitle,
            ),
          ),
          _StepButton(
            icon: Icons.add,
            label: 'Increase quantity',
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? LuntiColors.secondary : LuntiColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Selectable style card used on Product Details (check indicator) and
/// Personalization (radio indicator), matching Figma frames 02/08.
class LuntiChoiceCard extends StatelessWidget {
  const LuntiChoiceCard({
    super.key,
    required this.label,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
    this.indicator = LuntiChoiceIndicator.check,
  });

  final String label;
  final String priceLabel;
  final bool selected;
  final VoidCallback onTap;
  final LuntiChoiceIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? LuntiColors.sage : LuntiColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuntiRadii.md),
          side: BorderSide(
            color: selected ? LuntiColors.forest : LuntiColors.beige,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuntiRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LuntiSpacing.md,
              vertical: LuntiSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: LuntiTextStyles.cardTitle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        priceLabel,
                        style: LuntiTextStyles.caption.copyWith(
                          color: LuntiColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LuntiSpacing.xs),
                if (indicator == LuntiChoiceIndicator.check)
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: selected ? LuntiColors.forest : LuntiColors.beige,
                  )
                else
                  _RadioDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum LuntiChoiceIndicator { check, radio }

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? LuntiColors.forest : LuntiColors.beige,
          width: selected ? 6 : 1.5,
        ),
      ),
    );
  }
}

/// Key–value row with a hairline divider for the "Made with character"
/// spec table on Product Details.
class SpecRow extends StatelessWidget {
  const SpecRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: LuntiSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: LuntiColors.beige, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: LuntiTextStyles.caption.copyWith(
                color: LuntiColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: LuntiTextStyles.cardTitle),
          ),
        ],
      ),
    );
  }
}

/// Category list row used on the Categories screen: shop label, tagline
/// and a trailing chevron.
class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuntiSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LuntiTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: LuntiTextStyles.caption),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: LuntiColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
