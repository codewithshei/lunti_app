import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/payment_method.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/payment_badge.dart';

/// Prototype payment screen for every checkout method.
///
/// GCash and card show provider branding and two simulation actions. Cash on
/// Delivery confirms a real COD request instead. The screen never collects
/// wallet numbers or card details; it simply returns `true` when the customer
/// completes the prototype step so Checkout can save the order.
class SimulatedPaymentScreen extends StatefulWidget {
  const SimulatedPaymentScreen({
    super.key,
    required this.method,
    required this.total,
    required this.itemCount,
  });

  final PaymentMethod method;
  final int total;
  final int itemCount;

  @override
  State<SimulatedPaymentScreen> createState() => _SimulatedPaymentScreenState();
}

class _SimulatedPaymentScreenState extends State<SimulatedPaymentScreen> {
  bool _failed = false;
  bool _processing = false;

  bool get _isCod => widget.method == PaymentMethod.cashOnDelivery;

  String get _providerName {
    switch (widget.method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
    }
  }

  IconData get _providerIcon {
    switch (widget.method) {
      case PaymentMethod.cashOnDelivery:
        return Icons.payments_outlined;
      case PaymentMethod.gcash:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
    }
  }

  Future<void> _completeSimulatedPayment() async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _failed = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _simulateFailure() {
    if (_processing) return;
    setState(() => _failed = true);
  }

  void _confirmCod() {
    Navigator.of(context).pop(true);
  }

  void _returnToCheckout() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  BrandHeader(
                    onBack: _returnToCheckout,
                    onBagPressed: null,
                    icon: Icons.lock_outline,
                    showBadge: false,
                  ),
                  const SizedBox(height: LuntiSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: Text(
                      _isCod
                          ? 'Confirm cash on delivery'
                          : 'Complete your payment',
                      style: context.lunti.display,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: Text(
                      _isCod
                          ? 'Review your COD request before confirming.'
                          : 'This is a safe simulation. No real money moves.',
                      style: context.lunti.body,
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: _ProviderCard(
                      method: widget.method,
                      providerName: _providerName,
                      icon: _providerIcon,
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: _AmountCard(
                      total: widget.total,
                      itemCount: widget.itemCount,
                      isCod: _isCod,
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.md),
                  if (_failed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LuntiSpacing.gutter,
                      ),
                      child: _FailureCard(onReturn: _returnToCheckout),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LuntiSpacing.gutter,
                      ),
                      child: _isCod
                          ? const _CodDetailsCard()
                          : const _SimulationDisclaimer(),
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
              child: _buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            key: const Key('tryAgainPayment'),
            label: 'Try again',
            expand: true,
            onPressed: () => setState(() => _failed = false),
          ),
          const SizedBox(height: LuntiSpacing.xs),
          OutlinedButton(
            key: const Key('returnToCheckout'),
            onPressed: _returnToCheckout,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: context.lunti.accent,
              side: BorderSide(color: context.lunti.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LuntiRadii.sm),
              ),
            ),
            child: const Text('Return to checkout'),
          ),
        ],
      );
    }

    if (_isCod) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            key: const Key('confirmCodRequest'),
            label: 'Confirm COD Request',
            expand: true,
            onPressed: _confirmCod,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Pay \u20B1${widget.total} upon delivery. The rider collects '
            'cash when your order arrives.',
            textAlign: TextAlign.center,
            style: context.lunti.caption,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          key: const Key('completeSimulatedPayment'),
          label: _processing
              ? 'Completing simulated payment\u2026'
              : 'Complete Simulated Payment',
          expand: true,
          onPressed: _processing ? null : _completeSimulatedPayment,
        ),
        const SizedBox(height: LuntiSpacing.xs),
        OutlinedButton(
          key: const Key('simulateFailedPayment'),
          onPressed: _processing ? null : _simulateFailure,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: context.lunti.warning,
            side: BorderSide(color: context.lunti.warning),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuntiRadii.sm),
            ),
          ),
          child: const Text('Simulate Failed Payment'),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.method,
    required this.providerName,
    required this.icon,
  });

  final PaymentMethod method;
  final String providerName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isCod = method == PaymentMethod.cashOnDelivery;
    final isGcash = method == PaymentMethod.gcash;
    final background = isCod
        ? context.lunti.surfaceAlt
        : isGcash
            ? const Color(0xFF007DFE)
            : context.lunti.accent;
    final foreground = isCod ? context.lunti.accent : context.lunti.surface;

    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        boxShadow: isCod
            ? null
            : [
                BoxShadow(
                  color: background.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: isCod ? 0.10 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: foreground, size: 24),
          ),
          const SizedBox(width: LuntiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName,
                  style: context.lunti.sectionTitle.copyWith(
                    color: foreground,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCod
                      ? 'Pay the rider when your order arrives'
                      : 'Prototype payment · no real charge',
                  style: context.lunti.caption.copyWith(
                    color: foreground.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LuntiSpacing.xs),
          if (isCod)
            PaymentMethodBadge(method: method)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.lunti.surface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: context.lunti.surface.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'SIMULATION',
                style: context.lunti.caption.copyWith(
                  color: context.lunti.surface,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.total,
    required this.itemCount,
    required this.isCod,
  });

  final int total;
  final int itemCount;
  final bool isCod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCod ? 'Amount to pay on delivery' : 'Amount due',
            style: context.lunti.caption,
          ),
          const SizedBox(height: 4),
          Text(
            '\u20B1$total',
            style: context.lunti.display.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 2),
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'} · Standard '
            'shipping included',
            style: context.lunti.body,
          ),
        ],
      ),
    );
  }
}

class _SimulationDisclaimer extends StatelessWidget {
  const _SimulationDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.sm),
      decoration: BoxDecoration(
        color: context.lunti.surfaceAlt,
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: context.lunti.accent,
          ),
          const SizedBox(width: LuntiSpacing.xs),
          Expanded(
            child: Text(
              'Demo only. This screen does not connect to GCash, a bank or a '
              'card network. No wallet number, card number or CVV is '
              'collected, and no real payment is processed.',
              style: context.lunti.body.copyWith(color: context.lunti.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodDetailsCard extends StatelessWidget {
  const _CodDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.surfaceAlt,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 20,
                color: context.lunti.accent,
              ),
              const SizedBox(width: LuntiSpacing.xs),
              Text(
                'Pay in cash upon delivery',
                style: context.lunti.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Your order will be prepared after you confirm this request. '
            'The rider collects the full amount in cash when your bamboo '
            'pieces arrive. No online payment is taken now.',
            style: context.lunti.body.copyWith(color: context.lunti.text),
          ),
        ],
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        border: Border.all(
          color: context.lunti.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 20,
                color: context.lunti.warning,
              ),
              const SizedBox(width: LuntiSpacing.xs),
              Text(
                'Simulated payment failed',
                style: context.lunti.cardTitle.copyWith(
                  color: context.lunti.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'No order was created and nothing was charged. You can try the '
            'simulation again or return to checkout.',
            style: context.lunti.body.copyWith(color: context.lunti.text),
          ),
          const SizedBox(height: LuntiSpacing.xs),
          TextButton(
            onPressed: onReturn,
            style: TextButton.styleFrom(
              foregroundColor: context.lunti.warning,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Back to checkout'),
          ),
        ],
      ),
    );
  }
}
