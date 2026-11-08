import 'package:flutter/material.dart';

import '../screens/auth/auth_screen.dart';
import '../screens/shop/shop_flow.dart';

/// Root-level navigation helpers.
///
/// The Shop tab owns a nested [Navigator] so the bottom navigation stays
/// visible inside the shopping flow. Screens outside that flow (Home, Wishlist,
/// Profile) must not switch the Shop tab just to open the bag, so they push a
/// bag-only shop flow directly onto the root navigator. Back then returns to the
/// exact screen the customer came from, while Checkout, product details and
/// personalization keep working inside the pushed flow.
class AppRouter {
  const AppRouter._();

  /// Pushes the shopping bag onto the current root navigation stack.
  ///
  /// [flowKey] lets the caller return to the bag from deeper screens (for
  /// example a product opened from a bag line). [onContinueShopping] runs after
  /// the bag flow closes so the caller can open the normal Shop tab.
  static Future<void> openCart(
    BuildContext context, {
    required GlobalKey<NavigatorState> flowKey,
    required void Function(String action) onPrototypeAction,
    required VoidCallback onContinueShopping,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => ShopFlow(
          flowKey: flowKey,
          initialRoute: '/bag',
          handlesSystemBack: true,
          onPrototypeAction: onPrototypeAction,
          onExitFlow: () => Navigator.of(routeContext).maybePop(),
          onContinueShopping: () {
            Navigator.of(routeContext).pop();
            onContinueShopping();
          },
        ),
      ),
    );
  }

  /// Pushes the catalog, optionally filtered to one category, onto the root
  /// navigation stack.
  ///
  /// Home's category cards open the catalog as a real pushed route rather than
  /// switching to the Shop tab, so Back — and the app bar's back chevron —
  /// returns to the exact screen the customer came from (Home) instead of
  /// dropping them on the Shop tab's category landing.
  static Future<void> openCategory(
    BuildContext context, {
    String? categoryId,
    required void Function(String action) onPrototypeAction,
  }) {
    return Navigator.of(context).push<void>(
      slideFade(
        ShopFlow(
          initialRoute: '/catalog',
          initialCategoryId: categoryId,
          handlesSystemBack: true,
          onPrototypeAction: onPrototypeAction,
          onExitFlow: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  /// Slide-up + fade transition used for root-level pushes.
  static PageRouteBuilder<void> slideFade(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Pops every pushed route so the app returns to [RootScreen].
  ///
  /// Used after sign-out: [RootScreen] then selects its Home tab, and the auth
  /// stream rebuilds the Profile tab in guest mode. This deliberately does not
  /// open the sign-in screen.
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Opens the sign-in / create-account gate on the current navigator.
  ///
  /// Returns `true` when the customer is signed in, `false` when they chose to
  /// continue as a guest, and `false` when they backed out. Callers keep the
  /// local bag in shared state, so signing in never clears it.
  static Future<bool> openSignIn(
    BuildContext context, {
    String? title,
    String? subtitle,
    bool allowContinueAsGuest = false,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AuthScreen(
          title: title,
          subtitle: subtitle,
          allowContinueAsGuest: allowContinueAsGuest,
        ),
      ),
    );
    return result ?? false;
  }
}
