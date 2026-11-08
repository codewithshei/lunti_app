import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/sample_catalog.dart';
import '../../services/catalog_store.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/common.dart';
import '../../widgets/controls.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/product_card.dart';

/// Catalog screen, matching Figma frame "04 Catalog".
/// Category chips, wishlist hearts, Filters and Sort are functional against
/// the sample data; product details push the real product page.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({
    super.key,
    required this.onPrototypeAction,
    required this.onOpenSearch,
    this.initialCategoryId,
    this.onExitFlow,
  });

  final void Function(String action) onPrototypeAction;
  final VoidCallback onOpenSearch;

  /// Optional category filter from a category tile / link (e.g. `home`).
  final String? initialCategoryId;

  /// Set when the catalog is the first route of a flow pushed on the root
  /// navigator (Home's category cards). Back then leaves the flow entirely,
  /// returning to the screen the customer came from.
  final VoidCallback? onExitFlow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: _CatalogBody(
          onPrototypeAction: onPrototypeAction,
          onOpenSearch: onOpenSearch,
          initialCategoryId: initialCategoryId,
          onExitFlow: onExitFlow,
        ),
      ),
    );
  }
}

class _CatalogBody extends StatefulWidget {
  const _CatalogBody({
    required this.onPrototypeAction,
    required this.onOpenSearch,
    this.initialCategoryId,
    this.onExitFlow,
  });

  final void Function(String action) onPrototypeAction;
  final VoidCallback onOpenSearch;
  final String? initialCategoryId;
  final VoidCallback? onExitFlow;

  @override
  State<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends State<_CatalogBody> {
  String _selectedCategoryId = 'all';
  bool _engravedOnly = false;
  final Set<String> _priceBands = {};
  String _sortMode = 'recommended';

  @override
  void initState() {
    super.initState();
    final category = widget.initialCategoryId;
    if (category != null && category.isNotEmpty) {
      final known = sampleCategories.any((entry) => entry.id == category);
      _selectedCategoryId = known ? category : 'all';
    }
  }

  List<SampleProduct> get _visibleProducts {
    final catalog = CatalogStore.instance.products.value;
    var products = _selectedCategoryId == 'all'
        ? List.of(catalog)
        : catalog.where((p) => p.categoryId == _selectedCategoryId).toList();

    if (_engravedOnly) {
      products = products.where((p) => p.variantLabel != null).toList();
    }
    if (_priceBands.isNotEmpty) {
      bool inBand(SampleProduct p) =>
          (_priceBands.contains('under500') && p.pricePeso < 500) ||
          (_priceBands.contains('mid500') &&
              p.pricePeso >= 500 &&
              p.pricePeso <= 1200) ||
          (_priceBands.contains('over1200') && p.pricePeso > 1200);
      products = products.where(inBand).toList();
    }

    switch (_sortMode) {
      case 'priceLow':
        products.sort((a, b) => a.pricePeso.compareTo(b.pricePeso));
      case 'priceHigh':
        products.sort((a, b) => b.pricePeso.compareTo(a.pricePeso));
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
      default:
        break;
    }
    return products;
  }

  int get _activeFilters {
    var count = _priceBands.length;
    if (_engravedOnly) count += 1;
    if (_selectedCategoryId != 'all') count += 1;
    return count;
  }

  static const _sortLabels = {
    'recommended': 'Recommended',
    'priceLow': 'Price low to high',
    'priceHigh': 'Price high to low',
    'name': 'Name A to Z',
  };

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<({bool engraved, Set<String> bands})>(
      context: context,
      backgroundColor: LuntiColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuntiRadii.lg)),
      ),
      builder: (sheetContext) {
        // Declared outside the builder so StatefulBuilder rebuilds keep
        // the tapped values instead of re-initializing them.
        var engravedOnly = _engravedOnly;
        var priceBands = {..._priceBands};
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
          void toggleBand(String band) => setSheetState(() {
                if (!priceBands.remove(band)) priceBands.add(band);
              });
          return Padding(
            padding: EdgeInsets.only(
              left: LuntiSpacing.gutter,
              right: LuntiSpacing.gutter,
              top: LuntiSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child:
                            Text('Filters', style: LuntiTextStyles.sectionTitle),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setSheetState(() {
                          engravedOnly = false;
                          priceBands.clear();
                        }),
                        child: const Text(
                          'Reset',
                          style: LuntiTextStyles.cardTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuntiSpacing.md),
                  const Text('Price', style: LuntiTextStyles.eyebrow),
                  const SizedBox(height: LuntiSpacing.xs),
                  Wrap(
                    spacing: LuntiSpacing.xs,
                    children: [
                      LuntiChip(
                        label: 'Under \u20B1500',
                        selected: priceBands.contains('under500'),
                        onTap: () => toggleBand('under500'),
                      ),
                      LuntiChip(
                        label: '\u20B1500 to \u20B11,200',
                        selected: priceBands.contains('mid500'),
                        onTap: () => toggleBand('mid500'),
                      ),
                      LuntiChip(
                        label: 'Over \u20B11,200',
                        selected: priceBands.contains('over1200'),
                        onTap: () => toggleBand('over1200'),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuntiSpacing.md),
                  const Text('Style', style: LuntiTextStyles.eyebrow),
                  const SizedBox(height: LuntiSpacing.xs),
                  Wrap(
                    spacing: LuntiSpacing.xs,
                    children: [
                      LuntiChip(
                        label: 'Engraved styles available',
                        selected: engravedOnly,
                        onTap:
                            () => setSheetState(() => engravedOnly = !engravedOnly),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  PrimaryButton(
                    label: 'Show pieces',
                    expand: true,
                    onPressed: () => Navigator.of(sheetContext).pop((
                      engraved: engravedOnly,
                      bands: priceBands,
                    )),
                  ),
                  SizedBox(height: LuntiSpacing.lg),
                ],
              ),
            ),
          );
          }, // StatefulBuilder builder
        );
      }, // outer sheet builder
    ).then((result) {
      if (result == null) return;
      setState(() {
        _engravedOnly = result.engraved;
        _priceBands
          ..clear()
          ..addAll(result.bands);
      });
    });
  }

  Future<void> _showSortSheet() async {
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: LuntiColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuntiRadii.lg)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.only(
          left: LuntiSpacing.gutter,
          right: LuntiSpacing.gutter,
          top: LuntiSpacing.lg,
          bottom: LuntiSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort', style: LuntiTextStyles.sectionTitle),
            const SizedBox(height: LuntiSpacing.md),
            RadioGroup<String>(
              groupValue: _sortMode,
              onChanged: (mode) {
                if (mode != null) Navigator.of(sheetContext).pop(mode);
              },
              child: Column(
                children: [
                  for (final entry in _sortLabels.entries)
                    RadioListTile<String>(
                      value: entry.key,
                      title: Text(entry.value, style: LuntiTextStyles.body),
                      activeColor: LuntiColors.forest,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((mode) {
      if (mode != null) setState(() => _sortMode = mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SampleProduct>>(
      valueListenable: CatalogStore.instance.products,
      builder: (context, _, _) {
        final products = _visibleProducts;

        return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        BrandHeader(
          bagListenable: MockAppState.bagCount,
          onBack: widget.onExitFlow ?? () => Navigator.of(context).maybePop(),
          onBagPressed: () => widget.onPrototypeAction('Shopping bag'),
          actions: const [NotificationBell()],
        ),
        const SizedBox(height: LuntiSpacing.md),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Text('The bamboo collection', style: LuntiTextStyles.display),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Text(
            'Handcrafted pieces, rooted in Cardona.',
            style: LuntiTextStyles.body,
          ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: LuntiSearchField(
            hint: 'Search bamboo crafts',
            onTap: widget.onOpenSearch,
          ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Wrap(
            spacing: LuntiSpacing.xs,
            runSpacing: LuntiSpacing.xs,
            children: [
              LuntiChip(
                label: 'All',
                selected: _selectedCategoryId == 'all',
                onTap: () => setState(() => _selectedCategoryId = 'all'),
              ),
              for (final category in sampleCategories)
                LuntiChip(
                  label: category.shopLabel,
                  selected: _selectedCategoryId == category.id,
                  onTap: () =>
                      setState(() => _selectedCategoryId = category.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: LuntiSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Wrap(
            spacing: LuntiSpacing.xs,
            children: [
              LuntiChip(
                label: _activeFilters > 0 ? 'Filters \u00B7 $_activeFilters' : 'Filters',
                onTap: _showFilterSheet,
              ),
              LuntiChip(
                label: 'Sort \u00B7 ${_sortLabels[_sortMode]}',
                onTap: _showSortSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: products.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: LuntiSpacing.lg),
                  child: Text(
                    _engravedOnly || _priceBands.isNotEmpty
                        ? 'Nothing matches these filters \u2014 try resetting them.'
                        : 'No sample pieces in this craft yet.',
                    style: LuntiTextStyles.caption,
                  ),
                )
              : ValueListenableBuilder<WishlistEntry>(
                  valueListenable: MockAppState.wishlist,
                  builder: (context, wishlist, _) => GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: LuntiSpacing.md,
                    crossAxisSpacing: LuntiSpacing.xs,
                    // 0.66 leaves headroom for the photo well, one-line
                    // name, price/heart row and "Bamboo craft" caption at
                    // the 390px design width (167/232 overflowed by 11px).
                    childAspectRatio: 0.66,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final product in products)
                        CatalogProductCard(
                          product: product,
                          onTap: () => Navigator.of(context)
                              .pushNamed('/product', arguments: product.id),
                          isWishlisted: wishlist.containsKey(product.id),
                          onWishlistToggle: () => MockAppState.toggleWishlist(
                            product.id,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Text(
            'Phone Speaker also available Engraved \u00B7 \u20B1550.',
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
