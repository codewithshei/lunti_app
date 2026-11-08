import 'package:flutter/material.dart';

import '../app/app_theme.dart';

enum LuntiTab { home, shop, wishlist, profile }

/// Cream bottom navigation with a sage pill around the active icon,
/// mirroring the Figma frame. Non-Home tabs show placeholder screens for now.
class LuntiNavBar extends StatelessWidget {
  const LuntiNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final LuntiTab currentTab;
  final ValueChanged<LuntiTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.lunti.background,
          border: Border(top: BorderSide(color: context.lunti.border, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(
          LuntiSpacing.xs,
          8,
          LuntiSpacing.xs,
          6,
        ),
        child: Row(
          children: [
            for (final tab in LuntiTab.values)
              Expanded(
                child: _NavItem(
                  tab: tab,
                  selected: tab == currentTab,
                  onTap: () => onTabSelected(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final LuntiTab tab;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (tab) {
      case LuntiTab.home:
        return Icons.home_outlined;
      case LuntiTab.shop:
        return Icons.grid_view_outlined;
      case LuntiTab.wishlist:
        return Icons.favorite_border;
      case LuntiTab.profile:
        return Icons.person_outline;
    }
  }

  String get _label {
    switch (tab) {
      case LuntiTab.home:
        return 'Home';
      case LuntiTab.shop:
        return 'Shop';
      case LuntiTab.wishlist:
        return 'Wishlist';
      case LuntiTab.profile:
        return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? context.lunti.accent : context.lunti.textFaint;
    final labelStyle = context.lunti.navLabel.copyWith(
      color: selected ? context.lunti.accent : context.lunti.textFaint,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 30,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: selected ? context.lunti.surfaceAlt : Colors.transparent,
                borderRadius: BorderRadius.circular(LuntiRadii.lg),
              ),
              child: Icon(_icon, size: 20, color: iconColor),
            ),
            Text(_label, style: labelStyle),
            const SizedBox(height: 2),
          ],
        ),
      );
  }
}
