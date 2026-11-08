import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/sample_catalog.dart';
import '../../services/catalog_store.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../utils/order_display.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/lunti_product_image.dart';
import '../../widgets/order_status_pill.dart';
import '../../widgets/payment_badge.dart';
import '../../widgets/review_flow.dart';
import '../support_chat_screen.dart';

/// Order details for one placed order.
///
/// The screen starts from the order handed over by Order History, then follows
/// the live Firestore document when Firebase is available so an admin status
/// change appears without leaving the page. Pending orders can be cancelled by
/// the customer; the cancellation transaction also restores product stock.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.onBack,
    required this.onTrack,
  });

  final Order order;
  final VoidCallback onBack;
  final VoidCallback onTrack;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Order _order;
  StreamSubscription<Order?>? _subscription;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (Firebase.apps.isEmpty) return;
    _subscription = OrderService.instance.watchOrder(widget.order.id).listen(
      (latest) {
        if (!mounted || latest == null) return;
        setState(() => _order = latest);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    if (_isCancelling || _order.status != OrderStatus.pending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuntiColors.cream,
        title: const Text(
          'Cancel this order?',
          style: LuntiTextStyles.sectionTitle,
        ),
        content: Text(
          'Are you sure you want to cancel Order ${_order.id}?',
          style: LuntiTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final result = await OrderService.instance.cancelOrder(_order);
    if (!mounted) return;
    setState(() {
      _isCancelling = false;
      if (result.isSuccess) _order.status = OrderStatus.cancelled;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess
                ? 'Order ${_order.id} cancelled. Stock restored.'
                : result.error ?? 'Could not cancel this order.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: widget.onBack,
              onBagPressed: null,
              showBadge: false,
            ),
            Expanded(
              child: ValueListenableBuilder<List<SampleProduct>>(
                valueListenable: CatalogStore.instance.products,
                builder: (context, catalog, _) {
                  final products = <String, SampleProduct>{
                    for (final p in catalog) p.id: p,
                  };
                  return ListView(
                    padding: const EdgeInsets.all(LuntiSpacing.gutter),
                    children: [
                      Text('Order details', style: LuntiTextStyles.display),
                      const SizedBox(height: LuntiSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.id,
                              style: LuntiTextStyles.caption,
                            ),
                          ),
                          OrderStatusPill(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatOrderDate(order.createdAt),
                        style: LuntiTextStyles.caption,
                      ),
                      const SizedBox(height: LuntiSpacing.md),
                      _SectionCard(
                        title: 'Delivery',
                        child: _DeliveryDetails(order: order),
                      ),
                      const SizedBox(height: LuntiSpacing.md),
                      _SectionCard(
                        title: 'Items',
                        child: Column(
                          children: [
                            for (var i = 0; i < order.items.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  color: LuntiColors.beige,
                                  height: LuntiSpacing.lg,
                                ),
                              _OrderItemRow(
                                line: order.items[i],
                                product: products[order.items[i].productId],
                                canReview:
                                    order.status == OrderStatus.completed,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: LuntiSpacing.md),
                      _TotalsCard(order: order),
                      const SizedBox(height: LuntiSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => SupportChatScreen(
                              uid: order.userId.isEmpty ? null : order.userId,
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LuntiColors.forest,
                          side: const BorderSide(color: LuntiColors.forest),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(LuntiRadii.sm),
                          ),
                        ),
                        icon: const Icon(Icons.support_agent, size: 18),
                        label: const Text('Chat with us about this order'),
                      ),
                      if (order.status != OrderStatus.cancelled) ...[
                        const SizedBox(height: LuntiSpacing.lg),
                        ElevatedButton(
                          onPressed: widget.onTrack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LuntiColors.forest,
                            foregroundColor: LuntiColors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(LuntiRadii.sm),
                            ),
                          ),
                          child: const Text('Track order'),
                        ),
                      ],
                      if (order.status == OrderStatus.pending) ...[
                        const SizedBox(height: LuntiSpacing.sm),
                        OutlinedButton(
                          onPressed: _isCancelling ? null : _confirmCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LuntiColors.warning,
                            side: const BorderSide(color: LuntiColors.warning),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(LuntiRadii.sm),
                            ),
                          ),
                          child: Text(
                            _isCancelling ? 'Cancelling\u2026' : 'Cancel Order',
                          ),
                        ),
                        const SizedBox(height: LuntiSpacing.xs),
                        Text(
                          'Pending orders can be cancelled. Stock is returned '
                          'to the shop automatically.',
                          style: LuntiTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (order.status == OrderStatus.cancelled) ...[
                        const SizedBox(height: LuntiSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(LuntiSpacing.md),
                          decoration: BoxDecoration(
                            color: LuntiColors.sage,
                            borderRadius: BorderRadius.circular(LuntiRadii.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cancel_outlined,
                                color: LuntiColors.warning,
                                semanticLabel: 'Order cancelled',
                              ),
                              const SizedBox(width: LuntiSpacing.sm),
                              Expanded(
                                child: Text(
                                  'This order was cancelled. Any reserved stock '
                                  'has been returned to the shop.',
                                  style: LuntiTextStyles.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: LuntiSpacing.lg),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LuntiTextStyles.cardTitle),
          const SizedBox(height: LuntiSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final lines = [
      order.addressTitle,
      order.addressLine1,
      order.addressLine2,
    ].where((line) => line.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lines.isEmpty)
          Text(
            'No delivery address on file.',
            style: LuntiTextStyles.body.copyWith(
              color: LuntiColors.mutedForeground,
            ),
          )
        else
          for (final line in lines)
            Text(line, style: LuntiTextStyles.body),
        if (order.phone.trim().isNotEmpty) ...[
          const SizedBox(height: LuntiSpacing.xs),
          Text(order.phone, style: LuntiTextStyles.caption),
        ],
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        children: [
          _TotalRow(label: 'Subtotal', value: '\u20B1${order.subtotal}'),
          const SizedBox(height: LuntiSpacing.xs),
          _TotalRow(label: 'Shipping', value: '\u20B1${order.shippingFee}'),
          const SizedBox(height: LuntiSpacing.xs),
          _TotalRow(
            label: 'Total',
            value: '\u20B1${order.total}',
            emphasised: true,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          _TotalRow(label: 'Payment', value: order.paymentMethod),
          const SizedBox(height: LuntiSpacing.xs),
          Row(
            children: [
              const Expanded(
                child: Text('Payment status', style: LuntiTextStyles.body),
              ),
              PaymentStatusBadge(
                status: order.paymentStatusDisplay,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
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
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasised
                ? LuntiTextStyles.cardTitle
                : LuntiTextStyles.body,
          ),
        ),
        Text(
          value,
          style: emphasised
              ? LuntiTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : LuntiTextStyles.body,
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.line,
    required this.product,
    this.canReview = false,
  });

  final BagLine line;
  final SampleProduct? product;

  /// True once the order is completed, so each purchased item can be rated.
  final bool canReview;

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Text(
        'Unknown product (${line.productId})',
        style: LuntiTextStyles.caption,
      );
    }
    final unitPrice = BagPricing.unitPrice(product!, line);
    final styleText = BagPricing.styleText(product!, line);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 48,
          decoration: BoxDecoration(
            color: LuntiColors.cream,
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
          ),
          child: LuntiProductImage(
            image: product!.image,
            semanticLabel: product!.name,
          ),
        ),
        const SizedBox(width: LuntiSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product!.name, style: LuntiTextStyles.cardTitle),
              Text(
                '$styleText \u00B7 Qty ${line.quantity}',
                style: LuntiTextStyles.caption,
              ),
              if (line.engravingText != null &&
                  line.engravingText!.isNotEmpty)
                Text(
                  'Engraved: "${line.engravingText}"',
                  style: LuntiTextStyles.caption,
                ),
              if (canReview) ...[
                const SizedBox(height: 6),
                _ReviewAction(product: product!),
              ],
            ],
          ),
        ),
        const SizedBox(width: LuntiSpacing.xs),
        Text('\u20B1$unitPrice', style: LuntiTextStyles.price),
      ],
    );
  }
}

/// Per-line "Rate Item" action shown on completed orders.
///
/// The live review stream swaps the button for a "Reviewed" badge as soon as
/// this customer's review is saved, including edits made from product details.
class _ReviewAction extends StatelessWidget {
  const _ReviewAction({required this.product});

  final SampleProduct product;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ReviewService.instance.watchHasReviewed(product.id),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Semantics(
            label: 'Reviewed. You can edit this review from the product page.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: LuntiColors.sage,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: LuntiColors.forest.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: Color(0xFFC58A2B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed',
                    style: LuntiTextStyles.caption.copyWith(
                      color: LuntiColors.forest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return TextButton.icon(
          onPressed: () => startProductReview(context, product),
          style: TextButton.styleFrom(
            foregroundColor: LuntiColors.forest,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuntiRadii.sm),
            ),
          ),
          icon: const Icon(Icons.rate_review_outlined, size: 16),
          label: const Text('Rate Item'),
        );
      },
    );
  }
}
