import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';

/// Shown instead of the Profile tab for signed-out guests.
///
/// Guest browsing is intentional: this is the only place (besides Checkout)
/// where LUNTI asks for an account, because saved addresses, order history and
/// wishlist syncing all belong to a customer account.
class GuestAccountScreen extends StatelessWidget {
  const GuestAccountScreen({
    super.key,
    required this.onSignIn,
    required this.onBack,
    this.onBrowseShop,
    this.onOpenBag,
  });

  final VoidCallback onSignIn;
  final VoidCallback onBack;

  /// Optional shortcut into the shop while staying signed out.
  final VoidCallback? onBrowseShop;

  final VoidCallback? onOpenBag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: onBack,
              onBagPressed: onOpenBag,
              showBadge: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(LuntiSpacing.gutter),
                children: [
                  Text('Your account', style: LuntiTextStyles.display),
                  const SizedBox(height: LuntiSpacing.xs),
                  Text(
                    'LUNTI keeps your details, addresses and orders in one '
                    'place.',
                    style: LuntiTextStyles.body,
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(LuntiSpacing.lg),
                    decoration: BoxDecoration(
                      color: LuntiColors.white,
                      borderRadius: BorderRadius.circular(LuntiRadii.md),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: LuntiColors.sage,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 32,
                            color: LuntiColors.forest,
                          ),
                        ),
                        const SizedBox(height: LuntiSpacing.md),
                        Text(
                          'Sign in to view your profile and order history',
                          style: LuntiTextStyles.sectionTitle.copyWith(
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: LuntiSpacing.xs),
                        Text(
                          'You can keep browsing, adding pieces to your bag '
                          'and saving favourites as a guest.',
                          style: LuntiTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: LuntiSpacing.lg),
                        PrimaryButton(
                          label: 'Sign In',
                          expand: true,
                          onPressed: onSignIn,
                        ),
                        if (onBrowseShop != null) ...[
                          const SizedBox(height: LuntiSpacing.sm),
                          TextButton(
                            onPressed: onBrowseShop,
                            child: Text(
                              'Continue browsing',
                              style: LuntiTextStyles.cardTitle.copyWith(
                                color: LuntiColors.forest,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  const _GuestPerk(
                    icon: Icons.favorite_border,
                    title: 'Saved wishlist',
                    body: 'Keep the pieces you love in one list.',
                  ),
                  const SizedBox(height: LuntiSpacing.sm),
                  const _GuestPerk(
                    icon: Icons.location_on_outlined,
                    title: 'Saved addresses',
                    body: 'Checkout fills in your delivery details for you.',
                  ),
                  const SizedBox(height: LuntiSpacing.sm),
                  const _GuestPerk(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order history',
                    body: 'Follow every order from workshop to doorstep.',
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestPerk extends StatelessWidget {
  const _GuestPerk({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: LuntiColors.forest),
          const SizedBox(width: LuntiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LuntiTextStyles.cardTitle),
                Text(body, style: LuntiTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
