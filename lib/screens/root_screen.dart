import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_theme.dart';
import '../app/router.dart';
import '../data/mock_app_state.dart';
import '../services/notification_service.dart';
import '../widgets/lunti_nav_bar.dart';
import 'auth/guest_account_screen.dart';
import 'craft_story_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'shop/order_details_screen.dart';
import 'shop/order_history_screen.dart';
import 'shop/order_tracking_screen.dart';
import 'shop/shop_flow.dart';
import 'wishlist_screen.dart';

/// Root screen managing the bottom navigation.
/// Home tab -> Home screen; Shop tab -> nested Categories/Catalog/Search
/// flow; Wishlist -> saved-products screen (frame 09); Profile is an
/// honest placeholder for the next screens.
///
/// Dev-only bootstrap: `--dart-define=LUNTI_START=shop|catalog|search`
/// launches straight into that destination (for visual checks/tests).
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  static const String _startKnob = String.fromEnvironment(
    'LUNTI_START',
    defaultValue: 'home',
  );

  LuntiTab get initialTab {
    switch (_startKnob) {
      case 'shop':
      case 'catalog':
      case 'search':
      case 'product':
      case 'personalize':
      case 'bag':
      case 'checkout':
      case 'payment':
      case 'orders':
        return LuntiTab.shop;
      case 'wishlist':
        return LuntiTab.wishlist;
      case 'profile':
        return LuntiTab.profile;
      default:
        return LuntiTab.home;
    }
  }

  String get _initialShopRoute {
    switch (_startKnob) {
      case 'catalog':
        return '/catalog';
      case 'search':
        return '/search';
      case 'product':
        return '/product';
      case 'personalize':
        return '/personalize';
      case 'bag':
        return '/bag';
      case 'checkout':
        return '/checkout';
      case 'payment':
        return '/payment';
      case 'orders':
        return '/order-history';
      default:
        return '/categories';
    }
  }

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  LuntiTab _tab = LuntiTab.home;
  final GlobalKey<NavigatorState> _shopFlowKey = GlobalKey<NavigatorState>();

  /// Navigator key for the bag-only flow pushed on the root stack.
  final GlobalKey<NavigatorState> _cartFlowKey = GlobalKey<NavigatorState>();

  /// Navigator key for the Profile tab's own stack (order history, order
  /// details, tracking). Keeping those screens inside the tab means the
  /// bottom navigation stays on Profile and Back returns to the account
  /// screen instead of dropping into the Shop tab.
  final GlobalKey<NavigatorState> _profileFlowKey = GlobalKey<NavigatorState>();

  /// Shop flow route: the bootstrap knob seeds it once at boot; any
  /// user-initiated tab switch afterwards resets to the category landing
  /// so "Explore shop" from Home can never land on a dev route (bag /
  /// checkout) from an earlier launch.
  late String _shopRoute = widget._initialShopRoute;

  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isEmpty) return;
    // Start watching order statuses as soon as an account is signed in so
    // approved / shipped updates become notifications even when the customer
    // never opens the notifications screen.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        NotificationService.instance.startOrderSync(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _switchToShopFresh() {
    setState(() {
      _tab = LuntiTab.shop;
      _shopRoute = '/categories';
    });
  }

  /// Every screen's bag button reports the "Shopping bag" action here.
  ///
  /// Inside the Shop tab the bag opens in the nested flow so the bottom
  /// navigation stays visible. From Home / Wishlist / Profile it is pushed
  /// straight onto the root stack: no tab switch, and Back returns to the
  /// screen the customer was on.
  void _openBag() {
    if (_tab != LuntiTab.shop) {
      AppRouter.openCart(
        context,
        flowKey: _cartFlowKey,
        onPrototypeAction: _onCartFlowAction,
        onContinueShopping: _switchToShopFresh,
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shopFlowKey.currentState?.pushNamed('/bag');
    });
  }

  /// Actions inside the root bag flow. Its bag button returns to the bag
  /// instead of pushing a second bag flow on top of the first one.
  void _onCartFlowAction(String action) {
    if (action == 'Shopping bag') {
      _cartFlowKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    _onPrototypeAction(action);
  }

  /// Home tiles open the real product page inside the shop flow.
  void _openProduct(String productId) {
    if (_tab != LuntiTab.shop) _switchToShopFresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shopFlowKey.currentState?.pushNamed('/product', arguments: productId);
    });
  }

  /// Home's search field opens the real Search screen inside the shop flow.
  void _openSearch() {
    if (_tab != LuntiTab.shop) _switchToShopFresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shopFlowKey.currentState?.pushNamed('/search');
    });
  }

  /// Home's story banner opens the full craft story on the root stack, then
  /// its sticky CTA returns to the shop catalog.
  void _openCraftStory() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CraftStoryScreen(
          onExploreCollection: () {
            Navigator.of(context).pop();
            _openCatalog();
          },
        ),
      ),
    );
  }

  /// Home's category cards and "Shop all" open the catalog as a pushed route on
  /// the root stack, so Back returns to the screen the customer came from
  /// (Home) rather than switching to the Shop tab. The pushed flow keeps its
  /// own nested navigator for products and search.
  void _openCatalog({String? categoryId}) {
    AppRouter.openCategory(
      context,
      categoryId: categoryId,
      onPrototypeAction: _onPrototypeAction,
    );
  }

  void _onPrototypeAction(String action) {
    if (action == 'Shopping bag') {
      _openBag();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action is not available in this prototype yet.'),
        backgroundColor: LuntiColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuntiRadii.sm),
        ),
      ),
    );
  }

  /// Android system back / back-gesture handling for the tab shell.
  ///
  /// [PopScope.canPop] is false for every tab except Home, so the system back
  /// is intercepted here instead of closing the app:
  ///
  /// 1. A deeper screen in the Profile or Shop tab's nested Navigator pops
  ///    first.
  /// 2. Any other tab (Shop landing, Wishlist, Profile) returns to Home.
  /// 3. Home is the primary root: back is allowed to leave the app.
  ///
  /// Routes pushed above [RootScreen] (craft story, catalog from Home, bag,
  /// auth, order flows) keep their own back behaviour and never reach this
  /// handler.
  void _handleSystemBack() {
    // A deeper screen in the Profile tab's nested Navigator pops first.
    final profileFlow = _profileFlowKey.currentState;
    if (_tab == LuntiTab.profile && (profileFlow?.canPop() ?? false)) {
      profileFlow!.maybePop();
      return;
    }
    final shopFlow = _shopFlowKey.currentState;
    if (_tab == LuntiTab.shop && (shopFlow?.canPop() ?? false)) {
      shopFlow!.maybePop();
      return;
    }
    if (_tab != LuntiTab.home) {
      setState(() => _tab = LuntiTab.home);
      return;
    }
    // Defensive fallback; with canPop true this is not normally reached.
    SystemNavigator.pop();
  }

  void _onTabSelected(LuntiTab tab) {
    setState(() => _tab = tab);
    if (tab == LuntiTab.shop) {
      // A fresh shop mount starts at categories; a mounted flow gets its
      // stack cleared to the same destination.
      _shopRoute = '/categories';
      _shopFlowKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  /// Opens the sign-in gate from the Profile tab. The auth stream in
  /// [_buildProfileTab] swaps in the real profile as soon as it succeeds.
  Future<void> _openSignIn() async {
    await AppRouter.openSignIn(
      context,
      title: 'Sign in to your account',
      subtitle: 'View your profile, saved addresses and order history.',
    );
  }

  /// Returns to the Home tab after sign-out, in guest mode.
  ///
  /// Any route pushed above the root (for example a saved-addresses screen)
  /// is cleared first. The Profile tab will show the guest prompt the next
  /// time it is opened; no login screen is shown automatically.
  void _onSignedOut() {
    if (!mounted) return;
    AppRouter.popToRoot(context);
    setState(() {
      _tab = LuntiTab.home;
      _shopRoute = '/categories';
    });
  }

  /// Routes inside the Profile tab's own navigator. Order history, its
  /// details page and the tracking page live here so they keep the Profile
  /// tab selected and pop back to the account screen.
  Route<dynamic>? _onGenerateProfileRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/order-history':
        return MaterialPageRoute<void>(
          builder: (context) => OrderHistoryScreen(
            onBack: () => Navigator.of(context).maybePop(),
            onViewOrder: (order) {
              Navigator.of(context)
                  .pushNamed('/order-details', arguments: order);
            },
            onBrowseShop: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              _switchToShopFresh();
            },
          ),
        );
      case '/order-details':
        return MaterialPageRoute<void>(
          builder: (context) => OrderDetailsScreen(
            order: settings.arguments! as Order,
            onBack: () => Navigator.of(context).maybePop(),
            onTrack: () {
              Navigator.of(context)
                  .pushNamed('/order-tracking', arguments: settings.arguments);
            },
          ),
        );
      case '/order-tracking':
        return MaterialPageRoute<void>(
          builder: (context) => OrderTrackingScreen(
            order: settings.arguments! as Order,
            onBack: () => Navigator.of(context).maybePop(),
          ),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (context) => _buildProfileTab(),
        );
    }
  }

  /// Profile tab: signed-in customers see their account; guests get a
  /// friendly prompt instead of a forced login at launch.
  Widget _buildProfileTab() {
    final profile = ProfileScreen(
      onBack: () => setState(() => _tab = LuntiTab.home),
      onOpenBag: _openBag,
      onViewOrders: () {
        // Push inside the Profile tab's own navigator so the bottom
        // navigation stays on Profile and Back returns to the account
        // screen instead of dropping into the Shop tab.
        _profileFlowKey.currentState?.pushNamed('/order-history');
      },
      onViewWishlist: () => setState(() => _tab = LuntiTab.wishlist),
      onSignedOut: _onSignedOut,
    );

    // Widget tests and offline previews run without Firebase; keep the local
    // prototype profile there.
    if (Firebase.apps.isEmpty) return profile;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Avoid flashing the guest gate for a returning signed-in customer.
          return profile;
        }
        if (snapshot.data != null) return profile;
        return GuestAccountScreen(
          onSignIn: _openSignIn,
          onBack: () => setState(() => _tab = LuntiTab.home),
          onBrowseShop: _switchToShopFresh,
          onOpenBag: _openBag,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Home is the only tab where back may leave the app. Everywhere else
      // the callback below pops the nested flow or returns to Home first.
      canPop: _tab == LuntiTab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        backgroundColor: LuntiColors.cream,
        body: switch (_tab) {
          LuntiTab.home => HomeScreen(
            onPrototypeAction: _onPrototypeAction,
            onOpenProduct: _openProduct,
            onOpenShop: _switchToShopFresh,
            onOpenShopAll: () => _openCatalog(),
            onOpenSearch: _openSearch,
            onOpenCraftStory: _openCraftStory,
            onOpenCategory: (categoryId) =>
                _openCatalog(categoryId: categoryId),
          ),
          LuntiTab.shop => ShopFlow(
            flowKey: _shopFlowKey,
            initialRoute: _shopRoute,
            onPrototypeAction: _onPrototypeAction,
          ),
          LuntiTab.wishlist => WishlistScreen(
            onBack: () => setState(() => _tab = LuntiTab.home),
            onExploreTheShop: () => setState(() => _tab = LuntiTab.shop),
            onPrototypeAction: _onPrototypeAction,
            onOpenProduct: _openProduct,
          ),
          LuntiTab.profile => Navigator(
            key: _profileFlowKey,
            initialRoute: '/profile',
            // Prime the history with exactly one route: the default
            // initial-route handling would stack a hidden "/" route under
            // "/profile" and make the system back appear to do nothing.
            onGenerateInitialRoutes: (_, initialRoute) {
              final route =
                  _onGenerateProfileRoute(RouteSettings(name: initialRoute));
              return <Route<dynamic>>[?route];
            },
            onGenerateRoute: _onGenerateProfileRoute,
          ),
        },
        bottomNavigationBar: LuntiNavBar(
          currentTab: _tab,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
