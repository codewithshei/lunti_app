import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/sample_catalog.dart';
import '../../services/catalog_store.dart';
import '../../services/stock_service.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/lunti_product_image.dart';
import '../../widgets/stock_badge.dart';

/// Personalization, matching Figma frame "08 Personalization": the
/// "Engraved" variant flow with a name/message field and live engraving
/// copy. The text must be non-blank and is capped at
/// [_maxEngravingLength] characters; add-to-bag creates a real bag line
/// (with the engraving text attached), and Natural returns to Product
/// Details. Opened with an [EngravingEditSeed] to edit a bag line.
class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({
    super.key,
    required this.product,
    this.initialEngraving,
    this.replaceLineKey,
  });

  final SampleProduct product;

  /// Reopening an existing engraving: prefill text (null = "Maya" sample).
  final String? initialEngraving;

  /// When set, adding replaces the matching bag line instead of adding
  /// on top of its quantity (bag Edit flow).
  final String? replaceLineKey;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  static const int _maxEngravingLength = 20;

  late final TextEditingController _engravingController;
  late final Listenable _refresh;
  final bool _engravedSelected = true;
  int _quantity = 1;

  SampleProduct get _product {
    for (final product in CatalogStore.instance.products.value) {
      if (product.id == widget.product.id) return product;
    }
    return widget.product;
  }

  int get _engravedPrice =>
      _product.variantPricePeso ?? _product.pricePeso;

  bool get _engravingIsValid => _engravingController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // SAMPLE: starts prefilled with the line's text, or "Maya" to mirror
    // the designed state.
    _engravingController = TextEditingController(
      text: widget.initialEngraving ?? 'Maya',
    );
    // Rebuild for live catalog changes so a stock deduction or admin restock
    // updates the stepper and the add-to-bag button immediately.
    _refresh = Listenable.merge([
      _engravingController,
      CatalogStore.instance.products,
    ]);
  }

  @override
  void dispose() {
    _engravingController.dispose();
    super.dispose();
  }

  void _onBackToNatural() {
    Navigator.of(context).pop();
  }

  void _onAddToBag(int quantity) {
    final engraving = _engravingController.text.trim();
    if (engraving.isEmpty) return;

    final product = _product;
    final inBag = StockService.quantityInBag(
      product.id,
      ignoreLineKey: widget.replaceLineKey,
    );
    final remaining = StockService.availableFor(product) - inBag;
    final available = remaining < 0 ? 0 : remaining;

    if (available <= 0) {
      _showSnack('Out of stock. Remove it from your bag to add a new one.');
      return;
    }

    final toAdd = quantity > available ? available : quantity;
    MockAppState.addLine(
      product.id,
      variant: product.variantLabel,
      quantity: toAdd,
      engravingText: engraving,
      replaceLineKey: widget.replaceLineKey,
    );
    final message = toAdd < quantity
        ? 'Only $available items available in stock. Added $toAdd instead.'
        : 'Added $toAdd \u00D7 ${product.name} '
              '(${product.variantLabel}) to bag (sample).';
    _showSnack(message);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = _engravingController.text.trim();

    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _refresh,
          builder: (context, _) {
            final stock = StockService.availableFor(_product);
            final inBag = StockService.quantityInBag(
              _product.id,
              ignoreLineKey: widget.replaceLineKey,
            );
            final remaining = stock - inBag;
            final available = remaining < 0 ? 0 : remaining;
            final maxQuantity = available < 1 ? 1 : available;
            final quantity =
                _quantity > maxQuantity ? maxQuantity : _quantity;
            final outOfStock = available <= 0;

            return ListView(
              padding: const EdgeInsets.only(top: 12),
              children: [
                BrandHeader(
                  bagListenable: MockAppState.bagCount,
                  onBack: () => Navigator.of(context).maybePop(),
                  onBagPressed: () => Navigator.of(context).pushNamed('/bag'),
                ),
                const SizedBox(height: LuntiSpacing.md),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make it yours',
                        style: LuntiTextStyles.display,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'A personal touch, shaped in bamboo.',
                        style: LuntiTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LuntiSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: LuntiColors.white,
                          borderRadius: BorderRadius.circular(LuntiRadii.lg),
                        ),
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.all(LuntiSpacing.sm),
                        alignment: Alignment.center,
                        height: 220,
                        width: double.infinity,
                        child: LuntiProductImage(
                          image: _product.image,
                          semanticLabel: _product.name,
                        ),
                      ),
                      if (outOfStock)
                        const Positioned(
                          left: LuntiSpacing.sm,
                          top: LuntiSpacing.sm,
                          child: OutOfStockBadge(),
                        ),
                    ],
                  ),
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
                        _product.name,
                        style: LuntiTextStyles.sectionTitle.copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\u20B1$_engravedPrice',
                        style: LuntiTextStyles.sectionTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: LuntiColors.ink,
                        ),
                      ),
                      const SizedBox(height: LuntiSpacing.xs),
                      Text(
                        'Original product photo \u00B7 natural grain shown. '
                        'Engraving is not previewed on this image.',
                        style: LuntiTextStyles.caption.copyWith(
                          color: LuntiColors.secondary,
                        ),
                      ),
                      const SizedBox(height: LuntiSpacing.lg),
                      const Text('Style', style: LuntiTextStyles.cardTitle),
                      const SizedBox(height: LuntiSpacing.sm),
                      Row(
                        children: [
                          LuntiChoiceCard(
                            label: 'Natural',
                            priceLabel: _product.priceLabel,
                            selected: !_engravedSelected,
                            indicator: LuntiChoiceIndicator.radio,
                            onTap: _onBackToNatural,
                          ),
                          const SizedBox(width: LuntiSpacing.sm),
                          LuntiChoiceCard(
                            label: _product.variantLabel ?? 'Engraved',
                            priceLabel: '\u20B1$_engravedPrice',
                            selected: _engravedSelected,
                            indicator: LuntiChoiceIndicator.radio,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: LuntiSpacing.lg),
                      const Text(
                        'Name or short message',
                        style: LuntiTextStyles.cardTitle,
                      ),
                      const SizedBox(height: LuntiSpacing.xs),
                      _EngravingField(
                        controller: _engravingController,
                        maxLength: _maxEngravingLength,
                      ),
                      const SizedBox(height: LuntiSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _engravingIsValid
                                  ? 'Text to engrave: $text. '
                                      'Please check spelling before adding '
                                      'to your bag.'
                                  : 'Enter the text to engrave before adding '
                                      'to your bag.',
                              style: LuntiTextStyles.caption.copyWith(
                                color: LuntiColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: LuntiSpacing.xs),
                          Text(
                            '${_engravingController.text.length}/'
                            '$_maxEngravingLength',
                            style: LuntiTextStyles.caption.copyWith(
                              color: LuntiColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: LuntiSpacing.lg),
                      Text('Quantity', style: LuntiTextStyles.cardTitle),
                      const SizedBox(height: LuntiSpacing.sm),
                      QuantityStepper(
                        value: quantity,
                        max: maxQuantity,
                        onChanged: (value) => setState(() {
                          _quantity = value < 1
                              ? 1
                              : (value > maxQuantity ? maxQuantity : value);
                        }),
                      ),
                      if (outOfStock) ...[
                        const SizedBox(height: LuntiSpacing.xs),
                        const StockWarningText(available: 0),
                      ],
                      const SizedBox(height: LuntiSpacing.lg),
                      PrimaryButton(
                        label: outOfStock
                            ? 'Out of stock'
                            : 'Add to bag \u00B7 \u20B1${_engravedPrice * quantity}',
                        height: 48,
                        expand: true,
                        onPressed: _engravingIsValid && !outOfStock
                            ? () => _onAddToBag(quantity)
                            : null,
                      ),
                      const SizedBox(height: LuntiSpacing.lg),
                      _PersonalNoteCard(),
                      const SizedBox(height: LuntiSpacing.lg),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EngravingField extends StatelessWidget {
  const _EngravingField({
    required this.controller,
    required this.maxLength,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
        border: Border.all(color: LuntiColors.beige),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        style: LuntiTextStyles.body.copyWith(color: LuntiColors.ink),
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          counterText: '',
          hintText: 'e.g. A name or short message',
          hintStyle: LuntiTextStyles.caption,
        ),
      ),
    );
  }
}

class _PersonalNoteCard extends StatelessWidget {
  const _PersonalNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(LuntiRadii.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A note on your personal piece',
            style: LuntiTextStyles.cardTitle,
          ),
          SizedBox(height: LuntiSpacing.xs),
          Text(
            'Engraving is finished by hand, so placement and depth can vary '
            'slightly from piece to piece.',
            style: LuntiTextStyles.body,
          ),
        ],
      ),
    );
  }
}
