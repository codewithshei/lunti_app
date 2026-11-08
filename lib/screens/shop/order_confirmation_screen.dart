import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/payment_method.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/payment_badge.dart';
import 'widgets/receipt_download_button.dart';

/// Receipt shown after a successful simulated payment or COD request.
///
/// The order handed over here is the source of truth for the ID, totals,
/// payment method and payment status, so the receipt can never disagree with
/// what was saved to Order History and Firestore.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.onBackHome,
    required this.onViewOrders,
  });

  final Order? order;
  final VoidCallback onBackHome;
  final VoidCallback onViewOrders;

  @override
  Widget build(BuildContext context) {
    final order = this.order;
    final method = PaymentMethodX.parse(order?.paymentMethod);
    final status = (order?.paymentStatus ?? '').trim().isEmpty
        ? method.paymentStatus
        : order!.paymentStatus;
    final isCod = method == PaymentMethod.cashOnDelivery;

    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: onBackHome,
              onBagPressed: () {},
              showBadge: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LuntiSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: LuntiSpacing.lg),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: LuntiColors.sage,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCod
                            ? Icons.payments_outlined
                            : Icons.check_rounded,
                        size: 40,
                        color: LuntiColors.forest,
                      ),
                    ),
                    const SizedBox(height: LuntiSpacing.md),
                    Text(
                      isCod ? 'Order request received' : 'Order confirmed',
                      style: LuntiTextStyles.display,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    Text(
                      isCod
                          ? 'Your COD request is in. Pay in cash when your '
                              'bamboo pieces arrive.'
                          : 'Your simulated payment is recorded. We\'re '
                              'getting your bamboo pieces ready.',
                      style: LuntiTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: LuntiSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(LuntiSpacing.md),
                      decoration: BoxDecoration(
                        color: LuntiColors.white,
                        borderRadius: BorderRadius.circular(LuntiRadii.md),
                      ),
                      child: Column(
                        children: [
                          _ReceiptRow(
                            label: 'Order ID',
                            value: order?.id ?? '—',
                          ),
                          const SizedBox(height: LuntiSpacing.xs),
                          _ReceiptRow(
                            label: 'Items',
                            value: order == null
                                ? '—'
                                : '${order.itemCount} '
                                    '${order.itemCount == 1 ? 'item' : 'items'}',
                          ),
                          const SizedBox(height: LuntiSpacing.sm),
                          const Divider(color: LuntiColors.beige, height: 1),
                          const SizedBox(height: LuntiSpacing.sm),
                          _ReceiptRow(
                            label: 'Subtotal',
                            value: '₱${order?.subtotal ?? 0}',
                          ),
                          const SizedBox(height: LuntiSpacing.xs),
                          _ReceiptRow(
                            label: 'Shipping',
                            value: '₱${order?.shippingFee ?? 0}',
                          ),
                          const SizedBox(height: LuntiSpacing.xs),
                          _ReceiptRow(
                            label: 'Total',
                            value: '₱${order?.total ?? 0}',
                            emphasised: true,
                          ),
                          const SizedBox(height: LuntiSpacing.sm),
                          const Divider(color: LuntiColors.beige, height: 1),
                          const SizedBox(height: LuntiSpacing.sm),
                          _ReceiptRow(
                            label: 'Payment method',
                            value: order?.paymentMethod.isNotEmpty == true
                                ? order!.paymentMethod
                                : method.label,
                          ),
                          const SizedBox(height: LuntiSpacing.sm),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Payment status',
                                  style: LuntiTextStyles.body,
                                ),
                              ),
                              PaymentStatusBadge(status: status),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: LuntiSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(LuntiSpacing.sm),
                      decoration: BoxDecoration(
                        color: LuntiColors.sage,
                        borderRadius: BorderRadius.circular(LuntiRadii.sm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCod
                                ? Icons.info_outline
                                : Icons.verified_outlined,
                            size: 18,
                            color: LuntiColors.forest,
                          ),
                          const SizedBox(width: LuntiSpacing.xs),
                          Expanded(
                            child: Text(
                              isCod
                                  ? 'Please prepare ₱${order?.total ?? 0} in '
                                      'cash for the rider on delivery.'
                                  : 'This is a prototype receipt. No real '
                                      'payment was processed and no card or '
                                      'wallet details were collected.',
                              style: LuntiTextStyles.body.copyWith(
                                color: LuntiColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: LuntiSpacing.lg),
                    PrimaryButton(
                      label: 'View order details',
                      expand: true,
                      onPressed: onViewOrders,
                    ),
                    if (order != null) ...[
                      const SizedBox(height: LuntiSpacing.sm),
                      ReceiptDownloadButton(order: order),
                    ],
                    const SizedBox(height: LuntiSpacing.sm),
                    OutlinedButton(
                      onPressed: onBackHome,
                      child: const Text('Back to home'),
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

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasised
                ? LuntiTextStyles.cardTitle
                : LuntiTextStyles.body,
          ),
        ),
        const SizedBox(width: LuntiSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: emphasised
                ? LuntiTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : LuntiTextStyles.body.copyWith(color: LuntiColors.ink),
          ),
        ),
      ],
    );
  }
}
