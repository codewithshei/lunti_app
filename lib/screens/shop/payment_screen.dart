import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/payment_method.dart';
import '../../data/sample_catalog.dart';
import '../../services/catalog_store.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/payment_badge.dart';

/// Payment methods, matching Figma frame "12 Payment methods": order total
/// banner, the three payment choices and a sticky confirm button that returns
/// to Checkout.
///
/// GCash and card are simulations; Cash on Delivery is collected by the rider.
/// No wallet number, card number or credential is collected anywhere.
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<List<SampleProduct>>(
          valueListenable: CatalogStore.instance.products,
          builder: (context, catalog, _) {
            final products = {for (final p in catalog) p.id: p};
            return ValueListenableBuilder<List<BagLine>>(
              valueListenable: MockAppState.bag,
              builder: (context, lines, _) => _PaymentBody(
                products: products,
                lines: lines,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentBody extends StatelessWidget {
  const _PaymentBody({
    required this.products,
    required this.lines,
  });

  final Map<String, SampleProduct> products;
  final List<BagLine> lines;

  int get _subtotal {
    var total = 0;
    for (final line in lines) {
      final product = products[line.productId];
      if (product == null) continue;
      total += BagPricing.unitPrice(product, line) * line.quantity;
    }
    return total;
  }

  int get _itemCount => lines.fold(0, (n, line) => n + line.quantity);

  @override
  Widget build(BuildContext context) {
    final total = _subtotal + (_itemCount == 0 ? 0 : BagPricing.shippingFeePeso);
    final itemCount = _itemCount;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 12),
            children: [
              BrandHeader(
                onBack: () => Navigator.of(context).maybePop(),
                onBagPressed: null,
                icon: Icons.lock_outline,
                showBadge: false,
              ),
              const SizedBox(height: LuntiSpacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
                child: Text(
                  'How would you like to pay?',
                  style: context.lunti.display,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
                child: Text(
                  'Delivery \u2192 Payment \u2192 Review',
                  style: context.lunti.body,
                ),
              ),
              const SizedBox(height: LuntiSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.gutter,
                ),
                child: Container(
                  padding: const EdgeInsets.all(LuntiSpacing.md),
                  decoration: BoxDecoration(
                    color: context.lunti.surfaceAlt,
                    borderRadius: BorderRadius.circular(LuntiRadii.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order total \u00B7 \u20B1$total',
                        style: context.lunti.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$itemCount '
                        '${itemCount == 1 ? 'item' : 'items'} \u00B7 '
                        'Standard shipping included',
                        style: context.lunti.body,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LuntiSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.gutter,
                ),
                child: ValueListenableBuilder<PaymentMethod>(
                  valueListenable: MockAppState.paymentMethod,
                  builder: (context, selected, _) => Column(
                    children: [
                      for (final method in PaymentMethod.values) ...[
                        _MethodCard(
                          method: method,
                          selected: selected == method,
                          onTap: () =>
                              MockAppState.paymentMethod.value = method,
                        ),
                        const SizedBox(height: LuntiSpacing.sm),
                      ],
                      Container(
                        padding: const EdgeInsets.all(LuntiSpacing.md),
                        decoration: BoxDecoration(
                          color: context.lunti.surface,
                          borderRadius: BorderRadius.circular(LuntiRadii.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: LuntiSpacing.xs,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  selected.label,
                                  style: context.lunti.cardTitle,
                                ),
                                PaymentMethodBadge(method: selected),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selected.isSimulated
                                  ? 'No wallet number or card details are '
                                      'saved. This simulation never processes '
                                      'a real payment.'
                                  : 'You will pay the rider in cash when '
                                      'your order is delivered.',
                              style: context.lunti.body,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: LuntiSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "You'll return to checkout to review the total "
                          'and place your order.',
                          style: context.lunti.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LuntiSpacing.md),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LuntiSpacing.gutter,
            LuntiSpacing.sm,
            LuntiSpacing.gutter,
            LuntiSpacing.sm,
          ),
          child: ValueListenableBuilder<PaymentMethod>(
            valueListenable: MockAppState.paymentMethod,
            builder: (context, selected, _) => PrimaryButton(
              label: 'Use ${selected.shortLabel}',
              expand: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ],
    );
  }
}

/// One payment option radio card (frame 12): white tile, dark border +
/// filled dot when selected, plus the REAL/SIMULATION badge.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return Icons.payments_outlined;
      case PaymentMethod.gcash:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuntiSpacing.md,
          vertical: LuntiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.lunti.surface,
          borderRadius: BorderRadius.circular(LuntiRadii.sm),
          border: Border.all(
            color: selected ? context.lunti.text : context.lunti.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.lunti.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 22, color: context.lunti.accent),
            ),
            const SizedBox(width: LuntiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(method.label, style: context.lunti.cardTitle),
                      PaymentMethodBadge(method: method),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(method.caption, style: context.lunti.caption),
                ],
              ),
            ),
            const SizedBox(width: LuntiSpacing.sm),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// Radio dot matching the Checkout shipping-choice indicator.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.lunti.textFaint, width: 2),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.lunti.accent,
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: context.lunti.surfaceAlt,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
