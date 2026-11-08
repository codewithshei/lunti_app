import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/sample_catalog.dart';
import '../../models/product_review.dart';
import '../../services/catalog_store.dart';
import '../../services/review_service.dart';
import '../../services/stock_service.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/lunti_product_image.dart';
import '../../widgets/lunti_skeleton.dart';
import '../../widgets/review_flow.dart';
import '../../widgets/stock_badge.dart';

/// Product Details, matching Figma frame "02 Product Details".
/// Style selection, quantity and the gallery/thumbnails work against the
/// sample data. Wishlist hearts, postcode check and the gift CTA are
/// prototype actions until Cart / Checkout exist. SAMPLE only: selecting
/// "Engraved" pushes the Personalization screen (frame 08), and add-to-bag
/// just bumps the mock bag counter.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final SampleProduct product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late int _page;
  bool _engravedSelected = false;
  int _quantity = 1;
  bool _wishlisted = false;

  SampleProduct get _product {
    for (final product in CatalogStore.instance.products.value) {
      if (product.id == widget.product.id) return product;
    }
    return widget.product;
  }

  int get _currentPrice => _engravedSelected
      ? _product.variantPricePeso ?? _product.pricePeso
      : _product.pricePeso;

  @override
  void initState() {
    super.initState();
    _page = 0;
    _wishlisted = MockAppState.isWishlisted(_product.id);
    // Record the view after this frame: the Home rail behind a pushed flow is
    // still mounted and listens to [MockAppState.recentlyViewed], so notifying
    // it from initState would mark it dirty in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MockAppState.markViewed(_product.id);
    });
  }

  void _toggleWishlist() {
    MockAppState.toggleWishlist(
      _product.id,
      variant: _engravedSelected ? _product.variantLabel : null,
    );
    setState(() => _wishlisted = MockAppState.isWishlisted(_product.id));
  }

  void _openPersonalization() {
    Navigator.of(context).pushNamed('/personalize', arguments: _product.id);
  }

  void _onAddToBag(int quantity) {
    final product = _product;
    final stock = product.stockLeft < 0 ? 0 : product.stockLeft;
    final inBag = StockService.quantityInBag(product.id);
    final remaining = stock - inBag;
    final available = remaining < 0 ? 0 : remaining;

    if (available <= 0) {
      _showSnack('Out of stock. Remove it from your bag to add a new one.');
      return;
    }

    final toAdd = quantity > available ? available : quantity;
    MockAppState.addLine(
      product.id,
      variant: _engravedSelected ? product.variantLabel : null,
      quantity: toAdd,
    );
    final message = toAdd < quantity
        ? 'Only $available items available in stock. Added $toAdd instead.'
        : 'Added $toAdd \u00D7 ${product.name} to bag (sample).';
    _showSnack(message);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the live catalog changes so a stock deduction or an
    // admin restock updates the badge and the add-to-bag button immediately.
    return ValueListenableBuilder<List<SampleProduct>>(
      valueListenable: CatalogStore.instance.products,
      builder: (context, catalog, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final gallery = _product.galleryImages;
    final page = _page.clamp(0, gallery.length - 1);
    final stock = _product.stockLeft < 0 ? 0 : _product.stockLeft;
    final outOfStock = stock <= 0;
    final maxQuantity = stock < 1 ? 1 : stock;
    final quantity = _quantity < 1
        ? 1
        : (_quantity > maxQuantity ? maxQuantity : _quantity);
    final styleLabelText = _engravedSelected
        ? '${_product.variantLabel} selected'
        : 'Natural selected';
    final styleSpecValue = _engravedSelected
        ? 'Engraved \u00B7 name or short message'
        : 'Natural \u00B7 no engraving';

    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: () => Navigator.of(context).maybePop(),
              onBagPressed: () => Navigator.of(context).pushNamed('/bag'),
            ),
            const SizedBox(height: LuntiSpacing.md),
            _GalleryCard(
              gallery: gallery,
              productId: _product.id,
              productName: _product.name,
              page: page,
              outOfStock: outOfStock,
              onPageChanged: (value) => setState(() => _page = value),
              onSelectThumb: (index) => setState(() => _page = index),
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.eyebrow.toUpperCase(),
                    style: LuntiTextStyles.eyebrow,
                  ),
                  const SizedBox(height: LuntiSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _product.name,
                          style: LuntiTextStyles.display.copyWith(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: LuntiSpacing.xs),
                      _WishButton(
                        selected: _wishlisted,
                        onPressed: _toggleWishlist,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _RatingSummaryLine(productId: _product.id),
                  const SizedBox(height: LuntiSpacing.xs),
                  Row(
                    children: [
                      Text(
                        _currentPriceLabel(),
                        style: LuntiTextStyles.sectionTitle.copyWith(
                          fontSize: 22,
                          color: LuntiColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _StockChip(stockLeft: _product.stockLeft),
                    ],
                  ),
                  const SizedBox(height: LuntiSpacing.sm),
                  Text(_product.description, style: LuntiTextStyles.body),
                  if (_product.variantLabel != null) ...[
                    const SizedBox(height: LuntiSpacing.lg),
                    Row(
                      children: [
                        const Text('Style', style: LuntiTextStyles.cardTitle),
                        const Spacer(),
                        Text(
                          styleLabelText,
                          style: LuntiTextStyles.caption.copyWith(
                            color: LuntiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    Row(
                      children: [
                        LuntiChoiceCard(
                          label: 'Natural',
                          priceLabel: _product.priceLabel,
                          selected: !_engravedSelected,
                          onTap: () =>
                              setState(() => _engravedSelected = false),
                        ),
                        const SizedBox(width: LuntiSpacing.sm),
                        LuntiChoiceCard(
                          label: _product.variantLabel!,
                          priceLabel: '\u20B1${_product.variantPricePeso}',
                          selected: _engravedSelected,
                          onTap: _openPersonalization,
                        ),
                      ],
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    Text(
                      'Make it yours: choose ${_product.variantLabel} to add a '
                      'name or short message.',
                      style: LuntiTextStyles.caption.copyWith(
                        color: LuntiColors.secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: LuntiSpacing.lg),
                  Row(
                    children: [
                      QuantityStepper(
                        value: quantity,
                        max: maxQuantity,
                        onChanged: (value) => setState(() {
                          _quantity = value < 1
                              ? 1
                              : (value > maxQuantity ? maxQuantity : value);
                        }),
                      ),
                      const SizedBox(width: LuntiSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: outOfStock
                              ? 'Out of stock'
                              : 'Add to bag \u00B7 ${_totalLabel(quantity)}',
                          height: 48,
                          onPressed: outOfStock
                              ? null
                              : () => _onAddToBag(quantity),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  _DeliveryCard(
                    onCheck: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Delivery options are part of Cart & Checkout.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      ),
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  Text(
                    'Made with character',
                    style: LuntiTextStyles.sectionTitle.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: LuntiSpacing.sm),
                  SpecRow(label: 'Material', value: _product.material),
                  SpecRow(label: 'Style', value: styleSpecValue),
                  SpecRow(label: 'Origin', value: _product.origin),
                  SpecRow(label: 'Care', value: _product.care),
                  const SizedBox(height: LuntiSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: LuntiColors.secondary,
                      ),
                      const SizedBox(width: LuntiSpacing.xs),
                      Expanded(
                        child: Text(
                          'Check phone and case fit with LUNTI before ordering.',
                          style: LuntiTextStyles.caption.copyWith(
                            color: LuntiColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_product.variantLabel != null) ...[
                    Divider(color: LuntiColors.beige, thickness: 0.5),
                    const SizedBox(height: LuntiSpacing.xs),
                    LinkRow(
                      title: 'Planning a personalized gift?',
                      subtitle: 'Ask about engraving and bulk orders.',
                      onTap: _openPersonalization,
                    ),
                  ],
                  const SizedBox(height: LuntiSpacing.lg),
                  _ReviewsSection(product: _product),
                  const SizedBox(height: LuntiSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currentPriceLabel() => '\u20B1$_currentPrice';

  String _totalLabel(int quantity) => '\u20B1${_currentPrice * quantity}';
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.gallery,
    required this.productId,
    required this.productName,
    required this.page,
    required this.outOfStock,
    required this.onPageChanged,
    required this.onSelectThumb,
  });

  final List<String> gallery;
  final String productId;
  final String productName;
  final int page;
  final bool outOfStock;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSelectThumb;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: LuntiColors.white,
              borderRadius: BorderRadius.circular(LuntiRadii.lg),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: gallery.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      final image = LuntiProductImage(
                        image: gallery[index],
                        semanticLabel: productName,
                      );
                      return Padding(
                        padding: const EdgeInsets.all(LuntiSpacing.sm),
                        child: Center(
                          child: index == 0
                              ? Hero(
                                  tag: 'product-image-$productId',
                                  child: image,
                                )
                              : image,
                        ),
                      );
                    },
                  ),
                ),
                if (outOfStock)
                  const Positioned(
                    left: LuntiSpacing.sm,
                    top: LuntiSpacing.sm,
                    child: OutOfStockBadge(),
                  ),
                Positioned(
                  right: LuntiSpacing.sm,
                  bottom: LuntiSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LuntiColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: LuntiColors.beige),
                    ),
                    child: Text(
                      '${page + 1} / ${gallery.length}',
                      style: LuntiTextStyles.caption.copyWith(
                        color: LuntiColors.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < gallery.length; i++) ...[
                if (i > 0) const SizedBox(width: LuntiSpacing.xs),
                _GalleryThumb(
                  image: gallery[i],
                  selected: i == page,
                  onTap: () => onSelectThumb(i),
                ),
              ],
              const SizedBox(width: LuntiSpacing.sm),
              Expanded(
                child: Text(
                  'Natural grain. Every piece is unique.',
                  style: LuntiTextStyles.caption.copyWith(
                    color: LuntiColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LuntiColors.sage,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        side: BorderSide(
          color: selected ? LuntiColors.ink : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        child: Container(
          width: 64,
          height: 56,
          padding: const EdgeInsets.all(4),
          child: LuntiProductImage(
            image: image,
            semanticLabel: 'Product photo',
          ),
        ),
      ),
    );
  }
}

class _WishButton extends StatelessWidget {
  const _WishButton({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LuntiIconButton(
      icon: selected ? Icons.favorite : Icons.favorite_outline,
      label: 'Add to wishlist',
      onPressed: onPressed,
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.stockLeft});

  final int stockLeft;

  @override
  Widget build(BuildContext context) {
    final outOfStock = stockLeft <= 0;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: outOfStock ? LuntiColors.warning : const Color(0xFF4A7C59),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          outOfStock ? 'Out of stock' : 'In stock \u00B7 $stockLeft left',
          style: LuntiTextStyles.caption.copyWith(
            color: outOfStock ? LuntiColors.warning : LuntiColors.secondary,
            fontWeight: outOfStock ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(LuntiRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: LuntiColors.ink,
              ),
              const SizedBox(width: LuntiSpacing.sm),
              Expanded(
                child: Text(
                  'From Cardona to your doorstep',
                  style: LuntiTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          const Text(
            'Enter your postcode for delivery options and an estimated '
            'arrival.',
            style: LuntiTextStyles.body,
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.md),
            decoration: BoxDecoration(
              color: LuntiColors.white,
              borderRadius: BorderRadius.circular(LuntiRadii.md),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Enter postcode', style: LuntiTextStyles.caption),
                ),
                GestureDetector(
                  onTap: onCheck,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: LuntiSpacing.sm),
                    child: Text('Check', style: LuntiTextStyles.cardTitle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Shipping cost calculated at checkout.',
            style: LuntiTextStyles.caption.copyWith(
              color: LuntiColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "★ 4.8 (12 reviews)" line shown under the product title.
class _RatingSummaryLine extends StatelessWidget {
  const _RatingSummaryLine({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReviewSummary>(
      valueListenable: ReviewService.instance.summaryFor(productId),
      builder: (context, summary, _) {
        if (!summary.hasReviews) {
          return Text(
            'No reviews yet',
            style: LuntiTextStyles.caption.copyWith(
              color: LuntiColors.secondary,
            ),
          );
        }
        return Semantics(
          label:
              'Rated ${summary.averageLabel} out of 5 from ${summary.count} reviews',
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: Color(0xFFC58A2B),
              ),
              const SizedBox(width: 4),
              Text(
                '${summary.averageLabel} '
                '(${summary.count} review${summary.count == 1 ? '' : 's'})',
                style: LuntiTextStyles.caption.copyWith(
                  color: LuntiColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Reviews list plus the verified-customer submission entry point.
class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.product});

  final SampleProduct product;

  Future<void> _writeReview(BuildContext context) {
    return startProductReview(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: LuntiTextStyles.sectionTitle.copyWith(fontSize: 22),
        ),
        const SizedBox(height: LuntiSpacing.sm),
        StreamBuilder<List<ProductReview>>(
          stream: ReviewService.instance.watchReviews(product.id),
          builder: (context, snapshot) {
            final reviews = snapshot.data ?? const <ProductReview>[];
            if (snapshot.connectionState == ConnectionState.waiting &&
                reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: LuntiSpacing.md),
                child: LuntiShimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 150, height: 13),
                      SizedBox(height: 8),
                      SkeletonBox(width: double.infinity, height: 12),
                      SizedBox(height: 6),
                      SkeletonBox(width: 220, height: 12),
                    ],
                  ),
                ),
              );
            }
            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(LuntiSpacing.md),
                decoration: BoxDecoration(
                  color: LuntiColors.sage,
                  borderRadius: BorderRadius.circular(LuntiRadii.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No reviews yet',
                      style: LuntiTextStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bought this piece? Share how it looks in your home.',
                      style: LuntiTextStyles.body,
                    ),
                  ],
                ),
              );
            }

            final total = reviews.fold<int>(
              0,
              (sum, review) => sum + review.rating,
            );
            final average = total / reviews.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(LuntiSpacing.md),
                  decoration: BoxDecoration(
                    color: LuntiColors.sage,
                    borderRadius: BorderRadius.circular(LuntiRadii.md),
                  ),
                  child: Row(
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: LuntiTextStyles.display.copyWith(fontSize: 34),
                      ),
                      const SizedBox(width: LuntiSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Stars(rating: average, size: 18),
                          const SizedBox(height: 2),
                          Text(
                            '${reviews.length} '
                            'review${reviews.length == 1 ? '' : 's'}',
                            style: LuntiTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LuntiSpacing.md),
                for (final review in reviews) ...[
                  _ReviewCard(review: review),
                  const SizedBox(height: LuntiSpacing.sm),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: LuntiSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _writeReview(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: LuntiColors.forest,
            side: const BorderSide(color: LuntiColors.forest),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuntiRadii.sm),
            ),
          ),
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: const Text('Write a review'),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            rating >= i + 1
                ? Icons.star_rounded
                : (rating >= i + 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_border_rounded),
            size: size,
            color: const Color(0xFFC58A2B),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: LuntiTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _dateLabel(review.createdAt),
                style: LuntiTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _Stars(rating: review.rating.toDouble(), size: 14),
              const SizedBox(width: LuntiSpacing.xs),
              const Icon(
                Icons.verified_outlined,
                size: 13,
                color: LuntiColors.forest,
              ),
              const SizedBox(width: 3),
              Text('Verified purchase', style: LuntiTextStyles.caption),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(review.text, style: LuntiTextStyles.body),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
