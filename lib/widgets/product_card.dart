import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/sample_catalog.dart';
import '../models/product_review.dart';
import '../services/review_service.dart';
import 'lunti_card.dart';
import 'lunti_product_image.dart';
import 'pressable.dart';
import 'stock_badge.dart';

/// Height taken by the name / price / note block plus the gap above it.
///
/// Used to shrink the photo well instead of letting a short grid cell overflow
/// on very narrow layouts (small phones and the desktop review pane).
const double _productCardTextBlock = 74;

/// Keeps the natural photo ratio whenever it fits, and returns a shorter ratio
/// only when the card height cannot hold the photo plus the text block.
double _fittedPhotoRatio(
  BoxConstraints constraints, {
  required double natural,
  required double reserved,
}) {
  final width = constraints.maxWidth;
  final height = constraints.maxHeight;
  if (width <= 0 || !height.isFinite) return natural;
  if (width / natural + reserved <= height) return natural;
  final fittedHeight = height - reserved;
  if (fittedHeight <= 0) return natural;
  return (width / fittedHeight).clamp(natural, 2.4);
}

/// Product card for the Home grid and horizontal rails.
///
/// White rounded surface, soft shadow, wishlist heart at the top-right of the
/// photo, out-of-stock badge at the top-left and the rating pill tucked into
/// the bottom-left corner so nothing overlaps.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isWishlisted = false,
    this.onWishlistToggle,
    this.heroTag,
  });

  final SampleProduct product;
  final VoidCallback onTap;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  /// Optional Hero tag. Pass null when the same product may also appear in a
  /// second rail on the same screen (duplicate Hero tags are not allowed).
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return LuntiCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductPhoto(
              product: product,
              aspectRatio: _fittedPhotoRatio(
                constraints,
                natural: 1.15,
                reserved: _productCardTextBlock,
              ),
              heroTag: heroTag,
              isWishlisted: isWishlisted,
              onWishlistToggle: onWishlistToggle,
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: LuntiTextStyles.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              product.priceLabel,
              style: LuntiTextStyles.price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              product.note,
              style: LuntiTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Catalog grid card per Figma frame 04, updated to the white-card style.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  final SampleProduct product;
  final VoidCallback onTap;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    return LuntiCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductPhoto(
              product: product,
              aspectRatio: _fittedPhotoRatio(
                constraints,
                natural: 1.05,
                reserved: _productCardTextBlock,
              ),
              heroTag: 'product-image-${product.id}',
              isWishlisted: isWishlisted,
              onWishlistToggle: onWishlistToggle,
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: LuntiTextStyles.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              product.priceLabel,
              style: LuntiTextStyles.price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Bamboo craft',
              style: LuntiTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared photo well with the three corner overlays.
class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({
    required this.product,
    required this.aspectRatio,
    required this.heroTag,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  final SampleProduct product;
  final double aspectRatio;
  final String? heroTag;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    Widget image = LuntiProductImage(
      image: product.image,
      semanticLabel: product.name,
    );
    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LuntiRadii.sm),
              child: Container(
                color: LuntiColors.cream,
                padding: const EdgeInsets.all(6),
                child: image,
              ),
            ),
          ),
          if (product.isOutOfStock)
            Positioned(
              left: 6,
              top: 6,
              child: Transform.scale(
                scale: 0.86,
                alignment: Alignment.topLeft,
                child: const OutOfStockBadge(),
              ),
            ),
          if (onWishlistToggle != null)
            Positioned(
              right: 4,
              top: 4,
              child: _WishlistHeart(
                product: product,
                isWishlisted: isWishlisted,
                onToggle: onWishlistToggle!,
              ),
            ),
          Positioned(
            left: 6,
            bottom: 6,
            child: _RatingBadge(productId: product.id),
          ),
        ],
      ),
    );
  }
}

class _WishlistHeart extends StatelessWidget {
  const _WishlistHeart({
    required this.product,
    required this.isWishlisted,
    required this.onToggle,
  });

  final SampleProduct product;
  final bool isWishlisted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onToggle,
      pressedScale: 0.8,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xF2FFFFFF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A27372D),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 18,
          color: isWishlisted ? LuntiColors.forest : LuntiColors.ink,
          semanticLabel: isWishlisted
              ? 'Remove ${product.name} from wishlist'
              : 'Add ${product.name} to wishlist',
        ),
      ),
    );
  }
}

/// Compact average-rating pill shown over the product photo. It listens to the
/// shared review summary so a newly submitted review updates every card.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReviewSummary>(
      valueListenable: ReviewService.instance.summaryFor(productId),
      builder: (context, summary, _) {
        if (!summary.hasReviews) return const SizedBox.shrink();
        return Semantics(
          label: 'Rated ${summary.averageLabel} out of 5',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1427372D),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: Color(0xFFC58A2B),
                ),
                const SizedBox(width: 2),
                Text(
                  summary.averageLabel,
                  style: LuntiTextStyles.caption.copyWith(
                    color: LuntiColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
