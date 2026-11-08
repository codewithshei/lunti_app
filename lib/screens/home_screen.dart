import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/mock_app_state.dart';
import '../data/sample_catalog.dart';
import '../services/catalog_store.dart';
import '../widgets/brand_header.dart';
import '../widgets/category_tile.dart';
import '../widgets/common.dart';
import '../widgets/home_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/story_banner.dart';
import '../widgets/controls.dart';
import '../widgets/notification_bell.dart';

/// LUNTI Home screen, matching Figma frame "01 Home".
/// Categories and the story banner surface prototype notes; the search
/// field, featured products and category tiles open the real destinations
/// (search / product page / shop catalog) through the router callbacks.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onPrototypeAction,
    this.onOpenProduct,
    this.onOpenShop,
    this.onOpenShopAll,
    this.onOpenSearch,
    this.onOpenCraftStory,
    this.onOpenCategory,
  });

  final void Function(String action) onPrototypeAction;

  /// Opens a product's real Product Details in the shop flow.
  final void Function(String productId)? onOpenProduct;

  /// Opens the shop tab's category landing.
  final VoidCallback? onOpenShop;

  /// Opens the full shop catalog (all products) from "Shop all".
  final VoidCallback? onOpenShopAll;

  /// Opens the real Search screen in the shop flow.
  final VoidCallback? onOpenSearch;

  /// Opens the full "Our Craft & Artisans" story screen.
  final VoidCallback? onOpenCraftStory;

  /// Opens the catalog filtered to one category id.
  final void Function(String categoryId)? onOpenCategory;

  void _openCategory(String categoryId) {
    if (onOpenCategory != null) {
      onOpenCategory!(categoryId);
    } else if (onOpenShop != null) {
      onOpenShop!();
    } else {
      onPrototypeAction('Category catalog');
    }
  }

  void _showCraftStory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuntiColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuntiRadii.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(LuntiSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(LuntiRadii.md),
                  child: AspectRatio(
                    aspectRatio: 342 / 150,
                    child: Image.asset(
                      'assets/images/story_photo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: LuntiSpacing.md),
                const Text(
                  'FROM CARDONA, RIZAL',
                  style: LuntiTextStyles.eyebrow,
                ),
                const SizedBox(height: LuntiSpacing.sm),
                Text(
                  'Local hands.\nLasting character.',
                  style: LuntiTextStyles.display,
                ),
                const SizedBox(height: LuntiSpacing.sm),
                const Text(
                  'Meet LUNTi handcrafted bamboo by local artisans, with room '
                  'for your own personal touch.',
                  style: LuntiTextStyles.body,
                ),
                const SizedBox(height: LuntiSpacing.lg),
                PrimaryButton(
                  label: 'Explore the collection',
                  expand: true,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    (onOpenShop ?? () => onPrototypeAction('Explore shop'))();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carouselSlides = <HomeCarouselSlide>[
      HomeCarouselSlide(
        image: 'assets/images/carousel_craft_1.jpg',
        eyebrow: 'From Cardona, Rizal',
        headline: 'Cut, shaped and\nfinished by hand.',
        actionLabel: 'Explore shop',
        onTap: onOpenShop ?? () => onPrototypeAction('Explore shop'),
      ),
      HomeCarouselSlide(
        image: 'assets/images/carousel_craft_2.jpg',
        eyebrow: 'Meet the makers',
        headline: 'Generations of\nbamboo craft.',
        actionLabel: 'Our craft story',
        onTap: onOpenCraftStory ?? () => _showCraftStory(context),
      ),
      HomeCarouselSlide(
        image: 'assets/images/carousel_craft_3.jpg',
        eyebrow: 'Made personal',
        headline: 'Small details,\nmade to last.',
        actionLabel: 'Discover the craft',
        onTap: onOpenCraftStory ?? () => _showCraftStory(context),
      ),
      HomeCarouselSlide(
        image: 'assets/images/carousel_craft_4.jpg',
        eyebrow: 'Everyday bamboo',
        headline: 'Natural materials.\nThoughtful design.',
        actionLabel: 'Read the story',
        onTap: onOpenCraftStory ?? () => _showCraftStory(context),
      ),
    ];

    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            BrandHeader(
              location: 'Cardona, Rizal',
              bagListenable: MockAppState.bagCount,
              onBagPressed: () => onPrototypeAction('Shopping bag'),
              actions: const [NotificationBell()],
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: LuntiSearchField(
                hint: 'Search bamboo crafts',
                onTap: onOpenSearch ?? () => onPrototypeAction('Search'),
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: EyebrowLabel(text: 'Rooted in craft'),
            ),
            const SizedBox(height: LuntiSpacing.sm),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text(
                'A little nature.\nA lot of character.',
                style: LuntiTextStyles.display,
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            HomeCarousel(slides: carouselSlides),
            const SizedBox(height: LuntiSpacing.lg),
            const SectionHeader(title: 'Shop by craft'),
            const SizedBox(height: LuntiSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: LuntiSpacing.xs,
                crossAxisSpacing: LuntiSpacing.xs,
                // Full-bleed category photos read better tall: ~180px per card
                // instead of the old 106px sage tile.
                mainAxisExtent: 180,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final category in sampleCategories)
                    CategoryHeroTile(
                      category: category,
                      onTap: () => _openCategory(category.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
            SectionHeader(
              title: 'Thoughtfully picked',
              actionLabel: 'Shop all',
              onAction: onOpenShopAll ??
                  onOpenShop ??
                  () => onPrototypeAction('Shop all'),
            ),
            const SizedBox(height: LuntiSpacing.sm),
            SizedBox(
              height: 216,
              child: ValueListenableBuilder<List<SampleProduct>>(
                valueListenable: CatalogStore.instance.products,
                builder: (context, products, _) =>
                    ValueListenableBuilder<WishlistEntry>(
                  valueListenable: MockAppState.wishlist,
                  builder: (context, wishlist, _) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    itemCount: products.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: LuntiSpacing.sm),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return SizedBox(
                        width: 152,
                        child: ProductCard(
                          product: product,
                          heroTag: 'product-image-${product.id}',
                          isWishlisted: wishlist.containsKey(product.id),
                          onWishlistToggle: () =>
                              MockAppState.toggleWishlist(product.id),
                          onTap: () => onOpenProduct != null
                              ? onOpenProduct!(product.id)
                              : onPrototypeAction(
                                  'Product details: ${product.name}',
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            _RecentlyViewedSection(
              onOpenProduct: onOpenProduct,
              onPrototypeAction: onPrototypeAction,
            ),
            const SizedBox(height: LuntiSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: StoryBanner(
                eyebrow: 'From Cardona, Rizal',
                headline: 'Local hands.\nLasting character.',
                copy:
                    'Meet LUNTi handcrafted bamboo by local artisans, with '
                    'room for your own personal touch.',
                actionLabel: 'Discover our craft',
                imageUrl: 'assets/images/story_banner.jpg',
                onAction: onOpenCraftStory ?? () => _showCraftStory(context),
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _RecentlyViewedSection extends StatelessWidget {
  const _RecentlyViewedSection({
    required this.onOpenProduct,
    required this.onPrototypeAction,
  });

  final void Function(String productId)? onOpenProduct;
  final void Function(String action) onPrototypeAction;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: MockAppState.recentlyViewed,
      builder: (context, recentIds, _) {
        if (recentIds.isEmpty) return const SizedBox.shrink();
        return ValueListenableBuilder<List<SampleProduct>>(
          valueListenable: CatalogStore.instance.products,
          builder: (context, catalog, _) {
            final products = <SampleProduct>[];
            for (final id in recentIds) {
              for (final product in catalog) {
                if (product.id == id) {
                  products.add(product);
                  break;
                }
              }
            }
            if (products.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: LuntiSpacing.lg),
                const SectionHeader(title: 'Recently viewed'),
                const SizedBox(height: LuntiSpacing.sm),
                SizedBox(
                  height: 216,
                  child: ValueListenableBuilder<WishlistEntry>(
                    valueListenable: MockAppState.wishlist,
                    builder: (context, wishlist, _) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: LuntiSpacing.gutter,
                      ),
                      itemCount: products.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: LuntiSpacing.sm),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return SizedBox(
                          width: 152,
                          child: ProductCard(
                            product: product,
                            isWishlisted: wishlist.containsKey(product.id),
                            onWishlistToggle: () =>
                                MockAppState.toggleWishlist(product.id),
                            onTap: () => onOpenProduct != null
                                ? onOpenProduct!(product.id)
                                : onPrototypeAction(
                                    'Product details: ${product.name}',
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
