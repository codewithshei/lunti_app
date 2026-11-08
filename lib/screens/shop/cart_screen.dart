import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/router.dart';
import '../../data/mock_app_state.dart';
import '../../data/sample_catalog.dart';
import '../../services/catalog_store.dart';
import '../../services/stock_service.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/lunti_product_image.dart';
import '../../widgets/lunti_states.dart';
import '../../widgets/stock_badge.dart';

/// Shopping bag ("Your bag"), matching Figma frame "10 Cart":
/// one white card of bag lines (thumb, style + quantity, price,
/// stepper / Edit / Remove), a sage totals card, a continue-shopping
/// row and a sticky Checkout button. SAMPLE only: totals are computed
/// from the mock bag lines.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.onBack, this.onContinueShopping});

  /// Optional override used when the bag is opened on the root navigator.
  /// Without it the cart pops the navigator that contains it.
  final VoidCallback? onBack;

  /// Optional override for "Continue shopping". The shop flow defaults to
  /// returning to its first route.
  final VoidCallback? onContinueShopping;

  /// Guests can browse and fill a bag, but placing an order needs an account.
  ///
  /// Widget tests and offline previews run without Firebase; there is no auth
  /// state to check then, so the prototype goes straight to Checkout.
  static bool get _requiresSignIn {
    if (Firebase.apps.isEmpty) return false;
    return FirebaseAuth.instance.currentUser == null;
  }

  /// Runs the auth gate, then continues to Checkout with the same bag.
  Future<void> _startCheckout(BuildContext context) async {
    if (!_requiresSignIn) {
      Navigator.of(context).pushNamed('/checkout');
      return;
    }

    final signedIn = await AppRouter.openSignIn(
      context,
      title: 'Sign in to check out',
      subtitle:
          'Your bag is saved. Sign in to place your order and follow its '
          'progress.',
      allowContinueAsGuest: true,
    );

    // Continue browsing as guest leaves the customer on the bag with every
    // line untouched.
    if (!signedIn || !context.mounted) return;
    Navigator.of(context).pushNamed('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SampleProduct>>(
      valueListenable: CatalogStore.instance.products,
      builder: (context, catalog, _) {
        final products = {for (final p in catalog) p.id: p};
        return Scaffold(
          backgroundColor: LuntiColors.cream,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _CartBody(
                    products: products,
                    onBack: onBack,
                    onContinueShopping: onContinueShopping,
                  ),
                ),
                ValueListenableBuilder<List<BagLine>>(
                  valueListenable: MockAppState.bag,
                  builder: (context, lines, _) {
                    final hasStockIssue = _hasStockIssue(lines, products);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        LuntiSpacing.gutter,
                        LuntiSpacing.sm,
                        LuntiSpacing.gutter,
                        LuntiSpacing.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasStockIssue)
                            const Padding(
                              padding: EdgeInsets.only(bottom: LuntiSpacing.xs),
                              child: Text(
                                'Reduce the highlighted items to continue to '
                                'checkout.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: LuntiColors.warning,
                                ),
                              ),
                            ),
                          PrimaryButton(
                            label: 'Checkout',
                            expand: true,
                            onPressed: lines.isEmpty || hasStockIssue
                                ? null
                                : () => _startCheckout(context),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// True when the combined quantity for any product exceeds its stock.
  ///
  /// Natural and engraved bag lines share the same product stock, so they are
  /// summed before comparing.
  static bool _hasStockIssue(
    List<BagLine> lines,
    Map<String, SampleProduct> products,
  ) {
    final requested = StockService.requestedQuantities(lines);
    for (final entry in requested.entries) {
      final product = products[entry.key];
      if (product == null) continue;
      if (entry.value > StockService.availableFor(product)) return true;
    }
    return false;
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({
    required this.products,
    this.onBack,
    this.onContinueShopping,
  });

  final Map<String, SampleProduct> products;
  final VoidCallback? onBack;
  final VoidCallback? onContinueShopping;

  static String _subtitleFor(int count) {
    switch (count) {
      case 0:
        return 'Nothing in here yet.';
      case 1:
        return 'One little piece of everyday warmth.';
      case 2:
        return 'Two little pieces of everyday warmth.';
      default:
        return '$count little pieces of everyday warmth.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BagLine>>(
      valueListenable: MockAppState.bag,
      builder: (context, lines, _) {
        var subtotal = 0;
        for (final line in lines) {
          final product = products[line.productId];
          if (product == null) continue;
          subtotal += BagPricing.unitPrice(product, line) * line.quantity;
        }
        final itemCount =
            lines.fold<int>(0, (n, line) => n + line.quantity);
        final requested = StockService.requestedQuantities(lines);

        return ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: onBack ?? () => Navigator.of(context).maybePop(),
              onBagPressed: null,
            ),
            const SizedBox(height: LuntiSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text('Your bag', style: LuntiTextStyles.display),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: Text(
                _subtitleFor(itemCount),
                style: LuntiTextStyles.body,
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.md,
                  vertical: lines.isEmpty ? LuntiSpacing.md : 8,
                ),
                decoration: BoxDecoration(
                  color: LuntiColors.white,
                  borderRadius: BorderRadius.circular(LuntiRadii.md),
                ),
                child: lines.isEmpty
                    ? LuntiEmptyState(
                        compact: true,
                        icon: Icons.shopping_bag_outlined,
                        title: 'Your bag is empty',
                        message:
                            'Pieces you add will appear here, ready for '
                            'checkout.',
                        actionLabel: 'Continue shopping',
                        onAction: onContinueShopping,
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < lines.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                color: LuntiColors.beige,
                                height: 1,
                              ),
                            _BagLineRow(
                              line: lines[i],
                              product: products[lines[i].productId],
                              requestedQuantity: requested[lines[i].productId] ??
                                  lines[i].quantity,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: _TotalsCard(
                subtotal: subtotal,
                itemCount: itemCount,
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            GestureDetector(
              onTap: onContinueShopping ??
                  () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.gutter,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue shopping',
                            style: LuntiTextStyles.cardTitle,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Explore more bamboo crafts',
                            style: LuntiTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 26,
                      color: LuntiColors.ink,
                      semanticLabel: 'Back to the shop',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LuntiSpacing.sm),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text(
                'Prices and order details are illustrative samples.',
                style: LuntiTextStyles.caption,
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
          ],
        );
      },
    );
  }
}

class _BagLineRow extends StatelessWidget {
  const _BagLineRow({
    required this.line,
    required this.product,
    required this.requestedQuantity,
  });

  final BagLine line;
  final SampleProduct? product;

  /// Combined quantity for this product across every bag line.
  final int requestedQuantity;

  @override
  Widget build(BuildContext context) {
    final product = this.product;
    if (product == null) {
      return Opacity(
        opacity: 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LuntiSpacing.md),
          child: Text(
            'Unknown product (${line.productId})',
            style: LuntiTextStyles.body,
          ),
        ),
      );
    }

    final index = MockAppState.bag.value.indexOf(line);
    final unitPrice = BagPricing.unitPrice(product, line);
    final styleText = BagPricing.styleText(product, line);
    final stock = StockService.availableFor(product);
    final overStock = requestedQuantity > stock;
    final isEngraved =
        line.variant != null && line.variant == product.variantLabel;
    final engraving = isEngraved ? (line.engravingText ?? '') : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuntiSpacing.md),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed('/product', arguments: product.id),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 74,
                  height: 64,
                  decoration: const BoxDecoration(color: LuntiColors.white),
                  child: LuntiProductImage(
                    image: product.image,
                    semanticLabel: product.name,
                  ),
                ),
              ),
              const SizedBox(width: LuntiSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: LuntiTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      '$styleText \u00B7 Quantity ${line.quantity}',
                      style: LuntiTextStyles.caption,
                    ),
                    if (engraving.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Engraved: "$engraving"',
                        style: LuntiTextStyles.caption.copyWith(
                          color: LuntiColors.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text('\u20B1$unitPrice', style: LuntiTextStyles.price),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Row(
            children: [
              QuantityStepper(
                value: line.quantity,
                max: stock < 1 ? 1 : stock,
                onChanged: (value) => MockAppState.setLineQuantity(index, value),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  isEngraved ? '/personalize' : '/product',
                  arguments: isEngraved
                      ? EngravingEditSeed(
                          product.id,
                          line.engravingText,
                          line.lineKey,
                        )
                      : product.id,
                ),
                behavior: HitTestBehavior.opaque,
                child: const Text(
                  'Edit',
                  style: LuntiTextStyles.body,
                ),
              ),
              const SizedBox(width: LuntiSpacing.lg),
              GestureDetector(
                onTap: () {
                  MockAppState.removeLine(index);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('${product.name} removed from bag.'),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () => MockAppState.restoreLine(line),
                        ),
                      ),
                    );
                },
                behavior: HitTestBehavior.opaque,
                child: const Text(
                  'Remove',
                  style: LuntiTextStyles.body,
                ),
              ),
            ],
          ),
          if (overStock) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: StockWarningText(available: stock),
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.subtotal, required this.itemCount});

  final int subtotal;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Subtotal', style: LuntiTextStyles.body),
              const Spacer(),
              Text('\u20B1$subtotal', style: LuntiTextStyles.body),
            ],
          ),
          const Row(
            children: [
              Text('Standard shipping', style: LuntiTextStyles.body),
              Spacer(),
              Text(
                'At checkout',
                style: LuntiTextStyles.body,
              ),
            ],
          ),
          const Divider(color: LuntiColors.beige, height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subtotal \u00B7 $itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: LuntiTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '\u20B1$subtotal',
                style: LuntiTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Shipping is calculated in checkout. No engraving is included '
              'in this bag.',
              style: LuntiTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}
