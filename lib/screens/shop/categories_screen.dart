import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/sample_catalog.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/controls.dart';
import '../../widgets/common.dart';

/// Categories screen, matching Figma frame "03 Categories".
/// Root destination of the Shop tab.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
    super.key,
    required this.onPrototypeAction,
    required this.onOpenCatalog,
    required this.onOpenSearch,
  });

  final void Function(String action) onPrototypeAction;

  /// Opens the catalog, optionally filtered to a category id.
  final void Function(String? categoryId) onOpenCatalog;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBagPressed: () => onPrototypeAction('Shopping bag'),
            ),
            const SizedBox(height: LuntiSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: EyebrowLabel(text: 'The LUNTI shop'),
            ),
            const SizedBox(height: LuntiSpacing.xs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text('Shop by craft', style: context.lunti.display),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text(
                'Small details. Everyday character.',
                style: context.lunti.body,
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: LuntiSearchField(
                hint: 'Search bamboo crafts',
                onTap: onOpenSearch,
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text('Discover', style: context.lunti.sectionTitle),
            ),
            const SizedBox(height: LuntiSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: LuntiSpacing.xs,
                crossAxisSpacing: LuntiSpacing.xs,
                // Same full-bleed hero cards as Home's "Shop by craft".
                mainAxisExtent: 180,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final category in sampleCategories)
                    CategoryHeroTile(
                      category: category,
                      useShopLabel: true,
                      onTap: () => onOpenCatalog(category.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: Column(
                children: [
                  for (final category in sampleCategories)
                    LinkRow(
                      title: category.shopLabel,
                      subtitle: category.tagline,
                      onTap: () => onOpenCatalog(category.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuntiSpacing.gutter,
              ),
              child: PrimaryButton(
                label: 'Explore all products',
                expand: true,
                onPressed: () => onOpenCatalog(null),
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
          ],
        ),
      ),
    );
  }
}
