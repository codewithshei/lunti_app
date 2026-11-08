import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Neutral placeholder block used inside [LuntiShimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 10,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E7DB),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A soft, moving highlight over its child.
///
/// Put the opaque background (a white card, the page) outside this widget so
/// only the placeholder blocks receive the shimmer tint.
class LuntiShimmer extends StatefulWidget {
  const LuntiShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<LuntiShimmer> createState() => _LuntiShimmerState();
}

class _LuntiShimmerState extends State<LuntiShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = _controller.value * 4 - 2;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(position - 1, 0),
            end: Alignment(position + 1, 0),
            colors: const [
              Color(0xFFE4E7DB),
              Color(0xFFF7F8F2),
              Color(0xFFE4E7DB),
            ],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// White product-card placeholder that matches the real card proportions.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F27372D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LuntiShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AspectRatio(
              aspectRatio: 1.15,
              child: SkeletonBox(width: double.infinity, radius: 12),
            ),
            const SizedBox(height: 10),
            const SkeletonBox(width: 108, height: 12),
            const SizedBox(height: 6),
            const SkeletonBox(width: 64, height: 14),
            const SizedBox(height: 6),
            const SkeletonBox(width: 82, height: 10),
          ],
        ),
      ),
    );
  }
}

/// Two-column skeleton grid for catalog-style loading states.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: LuntiSpacing.md,
      crossAxisSpacing: LuntiSpacing.xs,
      childAspectRatio: 0.72,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < itemCount; i++) const ProductCardSkeleton(),
      ],
    );
  }
}

/// Full-page placeholder used while a product route resolves its data.
class ProductDetailsSkeleton extends StatelessWidget {
  const ProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: LuntiShimmer(
                child: Row(
                  children: [
                    const SkeletonBox(width: 40, height: 44, radius: 22),
                    const Spacer(),
                    const SkeletonBox(width: 44, height: 44, radius: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: LuntiShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(
                      width: double.infinity,
                      height: 260,
                      radius: LuntiRadii.lg,
                    ),
                    const SizedBox(height: LuntiSpacing.md),
                    const SkeletonBox(width: 92, height: 11),
                    const SizedBox(height: 10),
                    const SkeletonBox(width: 218, height: 26),
                    const SizedBox(height: 12),
                    const SkeletonBox(width: 124, height: 15),
                    const SizedBox(height: 18),
                    const SkeletonBox(
                      width: double.infinity,
                      height: 13,
                    ),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 286, height: 13),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: SkeletonBox(height: 52, radius: 12),
                        ),
                        const SizedBox(width: LuntiSpacing.sm),
                        const Expanded(
                          child: SkeletonBox(height: 52, radius: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple skeleton row used by list screens (orders, notifications).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: LuntiShimmer(
        child: Row(
          children: [
            const SkeletonBox(width: 56, height: 56, radius: 12),
            const SizedBox(width: LuntiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 150, height: 13),
                  SizedBox(height: 8),
                  SkeletonBox(width: 96, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
