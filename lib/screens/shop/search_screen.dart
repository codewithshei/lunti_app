import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/sample_catalog.dart';
import '../../services/catalog_store.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/lunti_product_image.dart';
import '../../widgets/lunti_states.dart';

/// Search screen, matching Figma frame "05 Search": the first match gets
/// the designed result card, any further matches list as compact rows,
/// recent chips and explore chips work, and empty queries fall back to the
/// "Recently searched" state. Matching runs against name, note and
/// description in the sample data.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, required this.onPrototypeAction});

  final void Function(String action) onPrototypeAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: _SearchBody(onPrototypeAction: onPrototypeAction),
      ),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody({required this.onPrototypeAction});

  final void Function(String action) onPrototypeAction;

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  late final TextEditingController _controller;
  final List<String> _recent = [...sampleRecentlySearched];

  @override
  void initState() {
    super.initState();
    // Start empty so the customer types their own query; the Figma "speaker"
    // result is still reachable through the recent-search chip.
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SampleProduct> _matches(String query) {
    if (query.isEmpty) return const [];
    final q = query.trim().toLowerCase();
    return [
      for (final product in CatalogStore.instance.products.value)
        if (product.name.toLowerCase().contains(q) ||
            product.note.toLowerCase().contains(q) ||
            product.description.toLowerCase().contains(q))
          product,
    ];
  }

  void _setQuery(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _rememberQuery(value);
    setState(() {});
  }

  void _onQueryChanged(String value) {
    // Filtering happens on every keystroke.
    setState(() {});
  }

  void _onSubmitted(String value) {
    _rememberQuery(value);
    setState(() {});
  }

  void _rememberQuery(String value) {
    final term = value.trim();
    if (term.isEmpty) return;
    final next = [
      term,
      ..._recent.where(
        (entry) => entry.toLowerCase() != term.toLowerCase(),
      ),
    ];
    _recent
      ..clear()
      ..addAll(next.take(4));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ValueListenableBuilder<List<SampleProduct>>(
          valueListenable: CatalogStore.instance.products,
          builder: (context, _, _) {
            final query = _controller.text.trim().toLowerCase();
            final matches = _matches(query);
            return ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: () => Navigator.of(context).maybePop(),
              onBagPressed: () => widget.onPrototypeAction('Shopping bag'),
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text(
                'Find a little character',
                style: context.lunti.display,
              ),
            ),
            const SizedBox(height: LuntiSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: _QueryField(
                controller: _controller,
                onClear: _clearQuery,
                onChanged: _onQueryChanged,
                onSubmitted: _onSubmitted,
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
            if (matches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.gutter,
                ),
                child: Text(
                  matches.length == 1
                      ? 'Result for \u201C${_controller.text.trim()}\u201D'
                      : '${matches.length} results for \u201C${_controller.text.trim()}\u201D',
                  style: context.lunti.eyebrow,
                ),
              ),
              const SizedBox(height: LuntiSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.gutter,
                ),
                child: _ResultCard(
                  product: matches.first,
                ),
              ),
              if (matches.length > 1) ...[
                const SizedBox(height: LuntiSpacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
                  child: Text('More matches', style: context.lunti.sectionTitle),
                ),
                const SizedBox(height: LuntiSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LuntiSpacing.gutter,
                  ),
                  child: Column(
                    children: [
                      for (final product in matches.skip(1))
                        _MoreMatchRow(product: product),
                    ],
                  ),
                ),
              ],
            ] else if (query.isNotEmpty) ...[
              LuntiEmptyState(
                compact: true,
                icon: Icons.search_off_rounded,
                title: 'No matches yet',
                message: 'Try another word or explore the crafts below.',
              ),
            ],
            const SizedBox(height: LuntiSpacing.lg),
            if (_recent.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
                child: Text(
                  'Recently searched',
                  style: context.lunti.sectionTitle,
                ),
              ),
              const SizedBox(height: LuntiSpacing.xs),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
                child: Column(
                  children: [
                    for (final term in _recent)
                      LinkRow(
                        title: term,
                        subtitle: 'Tap to search again',
                        onTap: () => _setQuery(term),
                      ),
                  ],
                ),
              ),
              Divider(
                color: context.lunti.border,
                thickness: 0.5,
                indent: LuntiSpacing.gutter,
                endIndent: LuntiSpacing.gutter,
              ),
              const SizedBox(height: LuntiSpacing.sm),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Text('More to explore', style: context.lunti.cardTitle),
            ),
            const SizedBox(height: LuntiSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
              child: Wrap(
                spacing: LuntiSpacing.xs,
                children: [
                  for (final chip in sampleExploreChips)
                    LuntiChip(label: chip, onTap: () => _setQuery(chip)),
                ],
              ),
            ),
            const SizedBox(height: LuntiSpacing.lg),
          ],
        );
          },
        );
      },
    );
  }

  void _clearQuery() {
    setState(() => _controller.clear());
  }
}

class _QueryField extends StatelessWidget {
  const _QueryField({
    required this.controller,
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
        border: Border.all(color: context.lunti.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: context.lunti.textFaint),
          const SizedBox(width: LuntiSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: context.lunti.body.copyWith(color: context.lunti.text),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Try "speaker", "coaster" or "engraving"',
                hintStyle: context.lunti.caption,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.close,
                size: 20,
                color: context.lunti.textFaint,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.product});

  final SampleProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.lg),
      ),
      padding: const EdgeInsets.all(LuntiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 342 / 220,
            child: LuntiProductImage(
              image: product.image,
              semanticLabel: product.name,
            ),
          ),
          const SizedBox(height: LuntiSpacing.md),
          Text(
            product.name,
            style: context.lunti.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            '${product.note} \u00B7 ${product.priceLabel}',
            style: context.lunti.cardTitle,
          ),
          const SizedBox(height: 2),
          if (product.variantLabel != null)
            Text(
              '${product.variantLabel} option \u00B7 \u20B1${product.variantPricePeso}',
              style: context.lunti.caption,
            ),
          const SizedBox(height: LuntiSpacing.md),
          PrimaryButton(
            label: 'View product',
            expand: true,
            onPressed: () =>
                Navigator.of(context).pushNamed('/product', arguments: product.id),
          ),
        ],
      ),
    );
  }
}

/// Compact row listing for additional search matches: thumbnail, name and
/// price, tappable through to the product page.
class _MoreMatchRow extends StatelessWidget {
  const _MoreMatchRow({required this.product});

  final SampleProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LuntiSpacing.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            Navigator.of(context).pushNamed('/product', arguments: product.id),
        child: Container(
          padding: const EdgeInsets.all(LuntiSpacing.sm),
          decoration: BoxDecoration(
            color: context.lunti.surface,
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: LuntiProductImage(
                  image: product.image,
                  semanticLabel: product.name,
                ),
              ),
              const SizedBox(width: LuntiSpacing.sm),
              Expanded(
                child: Text(
                  product.name,
                  style: context.lunti.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('\u20B1${product.pricePeso}', style: context.lunti.price),
            ],
          ),
        ),
      ),
    );
  }
}
