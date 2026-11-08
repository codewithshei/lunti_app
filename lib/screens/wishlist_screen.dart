import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/mock_app_state.dart';
import '../data/sample_catalog.dart';
import '../services/catalog_store.dart';
import '../services/stock_service.dart';
import '../widgets/brand_header.dart';
import '../widgets/controls.dart';
import '../widgets/lunti_product_image.dart';
import '../widgets/lunti_states.dart';
import '../widgets/pressable.dart';
import '../widgets/stock_badge.dart';

/// Wishlist tab, matching Figma frame "09 Wishlist":
/// saved products as cards (thumbnail, title with saved style, price,
/// Remove + bookmark) with a per-card Add to bag and a sage
/// "Keep exploring the shop" action at the bottom. SAMPLE only: the list
/// reads MockAppState.wishlist; Add to bag just bumps the mock counter.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({
    super.key,
    required this.onBack,
    required this.onExploreTheShop,
    required this.onPrototypeAction,
    this.onOpenProduct,
  });

  final VoidCallback onBack;
  final VoidCallback onExploreTheShop;
  final void Function(String action) onPrototypeAction;

  /// Opens the saved product's real Product Details.
  final void Function(String productId)? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<List<SampleProduct>>(
          valueListenable: CatalogStore.instance.products,
          builder: (context, products, _) {
            return _WishlistBody(
              products: products,
              onBack: onBack,
              onExploreTheShop: onExploreTheShop,
              onPrototypeAction: onPrototypeAction,
              onOpenProduct: onOpenProduct,
            );
          },
        ),
      ),
    );
  }
}

class _WishlistBody extends StatelessWidget {
  const _WishlistBody({
    required this.products,
    required this.onBack,
    required this.onExploreTheShop,
    required this.onPrototypeAction,
    this.onOpenProduct,
  });

  final List<SampleProduct> products;
  final VoidCallback onBack;
  final VoidCallback onExploreTheShop;
  final void Function(String action) onPrototypeAction;
  final void Function(String productId)? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WishlistEntry>(
      valueListenable: MockAppState.wishlist,
      builder: (context, wishlist, _) {
        final saved = <(SampleProduct, String?)>[];
        for (final entry in wishlist.entries) {
          for (final product in products) {
            if (product.id == entry.key) {
              saved.add((product, entry.value));
              break;
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: onBack,
              onBagPressed: () => onPrototypeAction('Shopping bag'),
            ),
            const SizedBox(height: LuntiSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text(
                'Worth coming back to',
                style: LuntiTextStyles.display,
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text(
                'Your saved bamboo pieces.',
                style: LuntiTextStyles.body,
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            if (saved.isEmpty)
              const LuntiEmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'No saved pieces yet',
                message:
                    'Tap the heart on any product to keep it here for later.',
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.gutter,
                ),
                child: Column(
                  children: [
                    for (final (product, variant) in saved) ...[
                      _WishlistCard(
                        product: product,
                        variant: variant,
                        onPrototypeAction: onPrototypeAction,
                        onOpenProduct: onOpenProduct,
                      ),
                      const SizedBox(height: LuntiSpacing.md),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: _KeepExploringButton(onTap: onExploreTheShop),
            ),
            const SizedBox(height: LuntiSpacing.lg),
          ],
        );
      },
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.product,
    required this.variant,
    required this.onPrototypeAction,
    this.onOpenProduct,
  });

  final SampleProduct product;
  final String? variant;
  final void Function(String action) onPrototypeAction;
  final void Function(String productId)? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final title =
        variant == null ? product.name : '${product.name} \u00B7 $variant';
    final stock = StockService.availableFor(product);
    final inBag = StockService.quantityInBag(product.id);
    final remaining = stock - inBag;
    final available = remaining < 0 ? 0 : remaining;
    final outOfStock = stock <= 0;
    void openDetails() {
      if (onOpenProduct != null) {
        onOpenProduct!(product.id);
      } else {
        onPrototypeAction('Product details: ${product.name}');
      }
    }

    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: openDetails,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 78,
                      decoration: BoxDecoration(
                        color: LuntiColors.white,
                        borderRadius: BorderRadius.circular(LuntiRadii.sm),
                      ),
                      child: LuntiProductImage(
                        image: product.image,
                        semanticLabel: product.name,
                      ),
                    ),
                    if (outOfStock)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Transform.scale(
                          scale: 0.7,
                          alignment: Alignment.topLeft,
                          child: const OutOfStockBadge(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: LuntiSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: openDetails,
                      behavior: HitTestBehavior.opaque,
                      child: Text(title, style: LuntiTextStyles.cardTitle),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Saved to your wishlist',
                      style: LuntiTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Text(product.priceLabel, style: LuntiTextStyles.price),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        MockAppState.removeFromWishlist(product.id);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('$title removed from wishlist.'),
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () => MockAppState.restoreWishlist(
                                  product.id,
                                  variant,
                                ),
                              ),
                            ),
                          );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: LuntiColors.ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(left: LuntiSpacing.xs),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    size: 24,
                    color: LuntiColors.ink,
                    semanticLabel: 'Saved to wishlist',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.md),
          PrimaryButton(
            label: outOfStock ? 'Out of stock' : 'Add to bag',
            expand: true,
            onPressed: available <= 0
                ? null
                : () {
                    MockAppState.addLine(
                      product.id,
                      variant: variant,
                      quantity: 1,
                    );
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added ${product.name} to bag (sample).',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                  },
          ),
          if (outOfStock) ...[
            const SizedBox(height: LuntiSpacing.xs),
            const StockWarningText(available: 0),
          ],
        ],
      ),
    );
  }
}

class _KeepExploringButton extends StatelessWidget {
  const _KeepExploringButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.97,
      child: Material(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              'Keep exploring the shop',
              style: LuntiTextStyles.cardTitle.copyWith(
                fontWeight: FontWeight.w600,
                color: LuntiColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
