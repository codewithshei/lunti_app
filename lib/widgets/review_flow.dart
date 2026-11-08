import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/router.dart';
import '../data/sample_catalog.dart';
import '../services/review_service.dart';
import 'controls.dart';

/// Opens the review form for [product] after checking whether the signed-in
/// customer is allowed to review it.
///
/// Shared by the product details screen and the per-item "Rate Item" action in
/// order details so both entry points enforce the same verified-purchase rule.
Future<void> startProductReview(
  BuildContext context,
  SampleProduct product,
) async {
  final eligibility = await ReviewService.instance.eligibilityFor(product.id);
  if (!context.mounted) return;

  switch (eligibility) {
    case ReviewEligibility.notSignedIn:
      final signedIn = await AppRouter.openSignIn(
        context,
        title: 'Sign in to write a review',
        subtitle: 'Reviews are limited to customers with a delivered order.',
      );
      if (!context.mounted || !signedIn) return;
      await startProductReview(context, product);
      return;
    case ReviewEligibility.noDeliveredOrder:
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: LuntiColors.cream,
          title: const Text(
            'Reviews come after delivery',
            style: LuntiTextStyles.sectionTitle,
          ),
          content: const Text(
            'You can review this product once an order containing it is '
            'completed. Thanks for helping us keep reviews verified.',
            style: LuntiTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    case ReviewEligibility.eligible:
      final saved = await showReviewForm(context, product);
      if (!context.mounted || saved != true) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Thanks! Your review is now live.')),
        );
  }
}

/// Shows the review form sheet for [product] and resolves to `true` when the
/// review was saved.
Future<bool?> showReviewForm(BuildContext context, SampleProduct product) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LuntiColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(LuntiRadii.lg)),
    ),
    builder: (_) => ReviewForm(product: product),
  );
}

/// Rating + comment form used by both review entry points.
class ReviewForm extends StatefulWidget {
  const ReviewForm({super.key, required this.product});

  final SampleProduct product;

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final TextEditingController _controller = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = 'Choose a rating from 1 to 5 stars.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await ReviewService.instance.submitReview(
      productId: widget.product.id,
      rating: _rating,
      text: _controller.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: LuntiSpacing.gutter,
        right: LuntiSpacing.gutter,
        top: LuntiSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + LuntiSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write a review', style: LuntiTextStyles.sectionTitle),
            const SizedBox(height: 2),
            Text(widget.product.name, style: LuntiTextStyles.caption),
            const SizedBox(height: LuntiSpacing.md),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() {
                      _rating = i;
                      _error = null;
                    }),
                    tooltip: '$i star${i == 1 ? '' : 's'}',
                    icon: Icon(
                      _rating >= i
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 34,
                      color: const Color(0xFFC58A2B),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: LuntiSpacing.xs),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'What did you like about this piece?',
                hintStyle: LuntiTextStyles.caption,
                filled: true,
                fillColor: LuntiColors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LuntiRadii.sm),
                  borderSide: const BorderSide(color: LuntiColors.beige),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LuntiRadii.sm),
                  borderSide: const BorderSide(
                    color: LuntiColors.forest,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: LuntiSpacing.xs),
              Text(
                _error!,
                style: LuntiTextStyles.caption.copyWith(
                  color: LuntiColors.warning,
                ),
              ),
            ],
            const SizedBox(height: LuntiSpacing.md),
            PrimaryButton(
              label: _submitting ? 'Saving\u2026' : 'Submit review',
              expand: true,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
