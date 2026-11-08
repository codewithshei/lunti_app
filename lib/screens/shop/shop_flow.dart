import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/payment_method.dart';
import '../../data/product_repository.dart';
import '../../data/sample_catalog.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../widgets/lunti_skeleton.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'checkout_screen.dart';
import 'order_confirmation_screen.dart';
import 'order_details_screen.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';
import 'payment_screen.dart';
import 'personalization_screen.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';

/// Shop tab flow: Categories (root) -> Catalog / Search, pushed with a
/// nested Navigator so the LUNTI bottom navigation stays visible above.
/// Product Details / Personalization (frames 02/08) are resolved from a
/// product id through the ProductRepository seam.
class ShopFlow extends StatelessWidget {
  const ShopFlow({
    super.key,
    required this.onPrototypeAction,
    this.flowKey,
    this.initialRoute = '/categories',
    this.initialProductId = 'phone-speaker',
    this.initialCategoryId,
    this.onExitFlow,
    this.onContinueShopping,
    this.handlesSystemBack = false,
  });

  /// Real navigation key: applied to the inner [Navigator] so outside
  /// code (root tab handling, bag opens) can push/pop the shop stack.
  final GlobalKey<NavigatorState>? flowKey;

  final void Function(String action) onPrototypeAction;
  final String initialRoute;

  /// Dev/bootstrap seed only: lets --dart-define launch directly into the
  /// product or personalization route without navigation arguments.
  final String initialProductId;

  /// Category the catalog opens pre-filtered to. Only applied when the catalog
  /// is the flow's first route — a catalog pushed from Home's category cards.
  final String? initialCategoryId;

  /// Set when this flow was pushed on the root navigator just to show the bag.
  /// The bag's Back then exits the flow instead of leaving an empty cart route.
  final VoidCallback? onExitFlow;

  /// Set with [onExitFlow] so "Continue shopping" leaves the bag flow and
  /// opens the normal shop tab.
  final VoidCallback? onContinueShopping;

  /// Whether this flow owns the Android system back while it is on screen.
  ///
  /// Set when the flow is pushed as a route on the root navigator (catalog
  /// from Home, bag-only flow). Back then pops a deeper screen inside this
  /// nested [Navigator] first and only leaves the flow once it is at its root.
  ///
  /// The Shop tab leaves this false: `RootScreen` already handles system back
  /// for the whole tab shell, and two handlers on the same route would fire
  /// twice.
  final bool handlesSystemBack;

  @override
  Widget build(BuildContext context) {
    return _ShopFlowNavigator(
      flowKey: flowKey,
      initialRoute: initialRoute,
      handlesSystemBack: handlesSystemBack,
      onGenerateRoute: (settings) {
        final isFirstRoute = settings.name == initialRoute;
        final args = settings.arguments;
        final EngravingEditSeed? seed = args is EngravingEditSeed ? args : null;
        final productId =
            (args is String ? args : null) ??
            (isFirstRoute ? initialProductId : null);
        switch (settings.name) {
          case '/bag':
            return MaterialPageRoute<void>(
              builder: (context) => CartScreen(
                onBack: isFirstRoute ? onExitFlow : null,
                onContinueShopping: isFirstRoute ? onContinueShopping : null,
              ),
            );
          case '/checkout':
            return MaterialPageRoute<void>(
              builder: (context) => CheckoutScreen(
                onPlaceOrder: () async {
                  final lines = List<BagLine>.from(MockAppState.bag.value);

                  // Totals come from the live catalog only — never from a
                  // hardcoded fallback price.
                  final products = {
                    for (final p
                        in await ProductRepositoryHolder.I.listProducts())
                      p.id: p,
                  };
                  var subtotal = 0;
                  var itemCount = 0;
                  for (final line in lines) {
                    itemCount += line.quantity;
                    final product = products[line.productId];
                    if (product == null) {
                      return const CheckoutOrderResult.failed(
                        'An item in your bag is no longer available. '
                        'Please review your bag and try again.',
                      );
                    }
                    subtotal +=
                        BagPricing.unitPrice(product, line) * line.quantity;
                  }
                  final shipping = itemCount == 0
                      ? 0
                      : BagPricing.shippingFeePeso;
                  final total = subtotal + shipping;
                  final user = OrderService.isAvailable
                      ? FirebaseAuth.instance.currentUser
                      : null;

                  // Load saved address from Firestore. Checkout blocks
                  // placing an order until an address exists, so there is no
                  // invented fallback address here.
                  String addressLine1 = '';
                  String addressLine2 = '';
                  String phone = '';
                  String customerName = 'LUNTI customer';
                  String email = '';

                  if (user != null) {
                    try {
                      final dbService = DatabaseService();
                      final address = await dbService.getUserAddress(user.uid);
                      final street = address['street'] ?? '';
                      final barangay = address['barangay'] ?? '';
                      final city = address['city'] ?? '';
                      final province = address['province'] ?? '';
                      final postalCode = address['postalCode'] ?? '';
                      phone = address['phone'] ?? '';

                      // Build full address from saved fields
                      final parts = [
                        street,
                        barangay,
                        city,
                        province,
                        postalCode,
                      ].where((p) => p.toString().trim().isNotEmpty).toList();
                      addressLine1 = parts.isNotEmpty ? parts.first : '';
                      addressLine2 = parts.length > 1
                          ? parts.skip(1).join(', ')
                          : '';

                      customerName = user.displayName?.trim().isNotEmpty == true
                          ? user.displayName!.trim()
                          : 'LUNTI customer';
                      email = user.email ?? '';
                    } catch (e) {
                      // Checkout already requires a saved address; if the
                      // read fails the order keeps empty address fields
                      // rather than inventing one.
                    }
                  }

                  final method = MockAppState.paymentMethod.value;
                  final order = MockAppState.buildOrder(
                    items: lines,
                    subtotal: subtotal,
                    shippingFee: shipping,
                    total: total,
                    paymentMethod: method.label,
                    paymentStatus: method.paymentStatus,
                    customerName: customerName,
                    email: email,
                    addressLine1: addressLine1,
                    addressLine2: addressLine2,
                    phone: phone,
                    userId: user?.uid ?? '',
                  );

                  // Stock validation, stock deduction and the order document
                  // are written in one Firestore transaction, so a failure
                  // leaves neither reserved stock nor a lost bag behind.
                  final placed = await OrderService.instance.placeOrder(order);
                  if (!placed.isSuccess) {
                    return placed.conflicts.isNotEmpty
                        ? CheckoutOrderResult.insufficient(placed.conflicts)
                        : CheckoutOrderResult.failed(
                            placed.error ?? 'Could not place your order.',
                          );
                  }

                  // Committed locally only after the order is safely stored.
                  MockAppState.commitOrder(order);

                  if (user != null) {
                    NotificationService.instance.startOrderSync(user.uid);
                  }
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamed('/order-confirmation', arguments: order);
                  }
                  return const CheckoutOrderResult.success();
                },
              ),
            );
          case '/payment':
            return MaterialPageRoute<void>(
              builder: (context) => const PaymentScreen(),
            );
          case '/order-confirmation':
            final order = args is Order ? args : null;
            return MaterialPageRoute<void>(
              builder: (context) => OrderConfirmationScreen(
                order: order,
                onBackHome:
                    onExitFlow ??
                    () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                onViewOrders: () {
                  Navigator.of(context).pushNamed('/order-history');
                },
              ),
            );
          case '/order-history':
            return MaterialPageRoute<void>(
              builder: (context) => OrderHistoryScreen(
                onBack: () => Navigator.of(context).maybePop(),
                onViewOrder: (order) {
                  Navigator.of(
                    context,
                  ).pushNamed('/order-details', arguments: order);
                },
                onBrowseShop: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            );
          case '/order-details':
            final order = args as Order;
            return MaterialPageRoute<void>(
              builder: (context) => OrderDetailsScreen(
                order: order,
                onBack: () => Navigator.of(context).maybePop(),
                onTrack: () {
                  Navigator.of(
                    context,
                  ).pushNamed('/order-tracking', arguments: order);
                },
              ),
            );
          case '/order-tracking':
            final order = args as Order;
            return MaterialPageRoute<void>(
              builder: (context) => OrderTrackingScreen(
                order: order,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            );
          case '/catalog':
            return MaterialPageRoute<void>(
              builder: (context) => CatalogScreen(
                onPrototypeAction: onPrototypeAction,
                onOpenSearch: () => Navigator.of(context).pushNamed('/search'),
                initialCategoryId:
                    args as String? ??
                    (isFirstRoute ? initialCategoryId : null),
                onExitFlow: isFirstRoute ? onExitFlow : null,
              ),
            );
          case '/search':
            return MaterialPageRoute<void>(
              builder: (context) =>
                  SearchScreen(onPrototypeAction: onPrototypeAction),
            );
          case '/product':
            return MaterialPageRoute<void>(
              builder: (context) => FutureBuilder<SampleProduct?>(
                future: productId == null
                    ? Future<SampleProduct?>.value(null)
                    : ProductRepositoryHolder.I.findById(productId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done &&
                      !snapshot.hasData) {
                    return const ProductDetailsSkeleton();
                  }
                  final product = snapshot.data;
                  if (product == null) {
                    return Scaffold(
                      backgroundColor: context.lunti.background,
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Product not found.',
                              style: context.lunti.cardTitle,
                            ),
                            const SizedBox(height: LuntiSpacing.sm),
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Go back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ProductDetailsScreen(product: product);
                },
              ),
            );
          case '/personalize':
            final seedId = seed?.productId ?? productId;
            return MaterialPageRoute<void>(
              builder: (context) => FutureBuilder<SampleProduct?>(
                future: seedId == null
                    ? Future<SampleProduct?>.value(null)
                    : ProductRepositoryHolder.I.findById(seedId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done &&
                      !snapshot.hasData) {
                    return const ProductDetailsSkeleton();
                  }
                  final product = snapshot.data;
                  if (product == null) {
                    return Scaffold(
                      backgroundColor: context.lunti.background,
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Product not found.',
                              style: context.lunti.cardTitle,
                            ),
                            const SizedBox(height: LuntiSpacing.sm),
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Go back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return PersonalizationScreen(
                    product: product,
                    initialEngraving: seed?.engravingText,
                    replaceLineKey: seed?.replaceLineKey,
                  );
                },
              ),
            );
          case '/categories':
          default:
            return MaterialPageRoute<void>(
              builder: (context) => CategoriesScreen(
                onPrototypeAction: onPrototypeAction,
                onOpenCatalog: (categoryId) => Navigator.of(
                  context,
                ).pushNamed('/catalog', arguments: categoryId),
                onOpenSearch: () => Navigator.of(context).pushNamed('/search'),
              ),
            );
        }
      },
    );
  }
}

/// Hosts the flow's nested [Navigator] and, when pushed on the root stack,
/// lets the Android system back pop it before the enclosing route.
///
/// [NavigatorPopHandler] listens to the nested navigator's
/// [NavigationNotification]: while it can pop, the system back is consumed
/// here; once it reaches its first route the parent route pops normally.
class _ShopFlowNavigator extends StatefulWidget {
  const _ShopFlowNavigator({
    required this.flowKey,
    required this.initialRoute,
    required this.handlesSystemBack,
    required this.onGenerateRoute,
  });

  final GlobalKey<NavigatorState>? flowKey;
  final String initialRoute;
  final bool handlesSystemBack;
  final RouteFactory onGenerateRoute;

  @override
  State<_ShopFlowNavigator> createState() => _ShopFlowNavigatorState();
}

class _ShopFlowNavigatorState extends State<_ShopFlowNavigator> {
  /// Callers that need to push into the flow pass their own key; the pushed
  /// catalog from Home does not, so this state owns a stable fallback.
  late final GlobalKey<NavigatorState> _navigatorKey =
      widget.flowKey ?? GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator(
      key: _navigatorKey,
      initialRoute: widget.initialRoute,
      // The default initial-route handling treats "/catalog" as a deep link
      // and stacks a hidden "/" route underneath it. That extra route made the
      // system back appear to do nothing (or to open Categories behind a
      // pushed catalog) before it could leave the flow. A flow only ever has
      // one starting destination, so prime the history with exactly one route.
      onGenerateInitialRoutes: (_, initialRoute) {
        final route = widget.onGenerateRoute(RouteSettings(name: initialRoute));
        return <Route<dynamic>>[?route];
      },
      onGenerateRoute: widget.onGenerateRoute,
    );

    if (!widget.handlesSystemBack) return navigator;

    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
      child: navigator,
    );
  }
}
