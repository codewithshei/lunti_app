import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../data/payment_method.dart';
import '../../data/sample_catalog.dart';
import '../../services/catalog_store.dart';
import '../../services/database_service.dart';
import '../../services/stock_service.dart';
import '../../widgets/address_sheet.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/controls.dart';
import '../../widgets/lunti_product_image.dart';
import '../../widgets/payment_badge.dart';
import '../../widgets/stock_badge.dart';
import '../support_chat_screen.dart';
import 'simulated_payment_screen.dart';

class _Totals {
  const _Totals({required this.subtotal, required this.itemCount});

  final int subtotal;
  final int itemCount;

  /// SAMPLE flat fee, only charged when the bag has something in it.
  int get shippingFeePeso =>
      itemCount == 0 ? 0 : BagPricing.shippingFeePeso;
  int get total => subtotal + shippingFeePeso;
}

_Totals _computeTotals(
  Map<String, SampleProduct> products,
  List<BagLine> lines,
) {
  var subtotal = 0;
  var itemCount = 0;
  for (final line in lines) {
    final product = products[line.productId];
    if (product == null) continue;
    subtotal +=
        BagPricing.unitPrice(product, line) * line.quantity;
    itemCount += line.quantity;
  }
  return _Totals(subtotal: subtotal, itemCount: itemCount);
}

/// Outcome of a placement attempt handed back by [CheckoutScreen.onPlaceOrder].
///
/// Stock is validated inside the service that actually places the order, so
/// checkout only needs to know whether it succeeded, ran out of stock, or
/// failed for another reason.
class CheckoutOrderResult {
  const CheckoutOrderResult._({
    this.conflicts = const [],
    this.error,
  });

  const CheckoutOrderResult.success() : this._();

 const CheckoutOrderResult.insufficient(this.conflicts)
    : error = null;

const CheckoutOrderResult.failed(this.error)
    : conflicts = const [];
      
  final List<StockConflict> conflicts;
  final String? error;

  bool get isSuccess => conflicts.isEmpty && error == null;
}

/// Checkout screen that loads saved address from Firestore and displays it.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.onPlaceOrder});

  /// Deducts stock and places the order.
  ///
  /// The callback owns the order creation and confirmation navigation so the
  /// checkout screen can stay mounted and show a stock warning when the order
  /// cannot be placed.
  final Future<CheckoutOrderResult> Function() onPlaceOrder;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Map<String, String> _savedAddress = {
    'street': '',
    'barangay': '',
    'city': '',
    'province': '',
    'postalCode': '',
    'phone': '',
  };
  bool _isLoadingAddress = true;
  String? _addressError;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    // Widget tests and offline previews run without a Firebase app; keep the
    // empty-address state instead of throwing.
    if (Firebase.apps.isEmpty) {
      setState(() => _isLoadingAddress = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingAddress = false;
      });
      return;
    }

    try {
      final dbService = DatabaseService();
      final address = await dbService.getUserAddress(user.uid);
      if (!mounted) return;
      setState(() {
        _savedAddress = {
          'street': address['street'] ?? '',
          'barangay': address['barangay'] ?? '',
          'city': address['city'] ?? '',
          'province': address['province'] ?? '',
          'postalCode': address['postalCode'] ?? '',
          'phone': address['phone'] ?? '',
        };
        _isLoadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addressError = e.toString();
        _isLoadingAddress = false;
      });
    }
  }

  void _onAddressChange() => _showEditAddressSheet();

  /// Styled sheet that adds or edits the customer's delivery address.
  ///
  /// The address is written to `users/{uid}/address` in Firestore, then the
  /// checkout screen rebuilds immediately so the card reflects the new
  /// address without leaving the page.
  Future<void> _showEditAddressSheet() async {
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;

    final saved = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.lunti.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuntiRadii.lg)),
      ),
      builder: (sheetContext) => AddressSheet(
        initialAddress: _savedAddress,
        canSync: user != null,
        onSave: (address) async {
          if (user != null) {
            await DatabaseService().saveUserAddress(user.uid, address);
          }
        },
      ),
    );

    if (saved == null || !mounted) return;
    setState(() {
      _savedAddress = Map<String, String>.from(saved);
      _addressError = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Delivery address saved.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _showOrderHelp() {
    // Widget tests and offline previews run without a Firebase app.
    final uid = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser?.uid;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SupportChatScreen(uid: uid),
      ),
    );
  }

  /// Places the prototype order, but only once a complete delivery address
  /// exists. The same required fields the address sheet validates are checked
  /// here so a partially saved address can never reach an order.
  ///
  /// Stock is checked again with the live catalog before the order is handed
  /// to [CheckoutScreen.onPlaceOrder], which deducts it transactionally. Two
  /// customers can race for the last item, so that callback's result is the
  /// final authority and any conflict is shown as an alert.
  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;

    final hasAddress = AddressSheet.requiredKeys.every(
      (field) => (_savedAddress[field] ?? '').trim().isNotEmpty,
    );
    if (!hasAddress) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Add a delivery address before placing your order.'),
            duration: Duration(seconds: 3),
          ),
        );
      _showEditAddressSheet();
      return;
    }

    final lines = List<BagLine>.from(MockAppState.bag.value);
    final conflicts = _stockConflicts(
      lines,
      {for (final p in CatalogStore.instance.products.value) p.id: p},
    );
    if (conflicts.isNotEmpty) {
      await _showStockAlert(conflicts);
      return;
    }

    // Payment happens before the order is saved or stock is deducted. A
    // failed or cancelled simulation therefore leaves both untouched.
    final products = {
      for (final product in CatalogStore.instance.products.value)
        product.id: product,
    };
    final totals = _computeTotals(products, lines);
    setState(() => _isPlacingOrder = true);

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SimulatedPaymentScreen(
          method: MockAppState.paymentMethod.value,
          total: totals.total,
          itemCount: totals.itemCount,
        ),
      ),
    );
    if (!mounted) return;
    if (paid != true) {
      setState(() => _isPlacingOrder = false);
      return;
    }

    CheckoutOrderResult result;
    try {
      result = await widget.onPlaceOrder();
    } catch (_) {
      result = const CheckoutOrderResult.failed(
        'Something went wrong while placing your order. Please try again.',
      );
    }

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    // A successful placement already navigated to the confirmation screen.
    if (result.isSuccess) return;

    if (result.conflicts.isNotEmpty) {
      await _showStockAlert(result.conflicts);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Could not place your order.'),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Stock conflicts for the current bag, aggregated per product.
  static List<StockConflict> _stockConflicts(
    List<BagLine> lines,
    Map<String, SampleProduct> products,
  ) {
    final requested = StockService.requestedQuantities(lines);
    final conflicts = <StockConflict>[];
    for (final entry in requested.entries) {
      final product = products[entry.key];
      if (product == null) continue;
      final available = StockService.availableFor(product);
      if (entry.value > available) {
        conflicts.add(
          StockConflict(
            productId: entry.key,
            productName: product.name,
            requested: entry.value,
            available: available,
          ),
        );
      }
    }
    return conflicts;
  }

  /// Refreshes stock and explains which items are short.
  Future<void> _showStockAlert(List<StockConflict> conflicts) async {
    // Pull the latest counts so the inline warnings behind the dialog agree
    // with what the customer is being told.
    await CatalogStore.instance.refresh();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.lunti.background,
        title: Text(
          'Not enough stock',
          style: context.lunti.sectionTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final conflict in conflicts)
              Padding(
                padding: const EdgeInsets.only(bottom: LuntiSpacing.xs),
                child: Text(
                  '\u2022 ${conflict.message}',
                  style: context.lunti.body,
                ),
              ),
            const SizedBox(height: LuntiSpacing.xs),
            Text(
              'Adjust the highlighted items in your bag, then try again. '
              'Nothing was charged.',
              style: context.lunti.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Review items'),
          ),
        ],
      ),
    );
  }

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
              builder: (context, lines, _) {
                final totals = _computeTotals(products, lines);
                final hasStockIssue = _stockConflicts(lines, products).isNotEmpty;
                return Column(
                  children: [
                    Expanded(
                      child: _CheckoutBody(
                        products: products,
                        lines: lines,
                        totals: totals,
                        savedAddress: _savedAddress,
                        isLoadingAddress: _isLoadingAddress,
                        addressError: _addressError,
                        onAddressChange: _onAddressChange,
                        onOrderHelp: _showOrderHelp,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        LuntiSpacing.gutter,
                        LuntiSpacing.sm,
                        LuntiSpacing.gutter,
                        LuntiSpacing.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasStockIssue)
                            Padding(
                              padding: EdgeInsets.only(bottom: LuntiSpacing.xs),
                              child: Text(
                                'Reduce the highlighted items to place your '
                                'order.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.lunti.warning,
                                ),
                              ),
                            ),
                          PrimaryButton(
                            label: _isPlacingOrder
                                ? 'Placing order\u2026'
                                : 'Place order \u00B7 \u20B1${totals.total}',
                            expand: true,
                            onPressed:
                                totals.itemCount == 0 ||
                                    hasStockIssue ||
                                    _isPlacingOrder
                                ? null
                                : _placeOrder,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({
    required this.products,
    required this.lines,
    required this.totals,
    required this.savedAddress,
    required this.isLoadingAddress,
    required this.addressError,
    required this.onAddressChange,
    required this.onOrderHelp,
  });

  final Map<String, SampleProduct> products;
  final List<BagLine> lines;
  final _Totals totals;
  final Map<String, String> savedAddress;
  final bool isLoadingAddress;
  final String? addressError;
  final VoidCallback onAddressChange;
  final VoidCallback onOrderHelp;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        BrandHeader(
          bagListenable: MockAppState.bagCount,
          onBack: () => Navigator.of(context).maybePop(),
          onBagPressed: null,
          icon: Icons.lock_outline,
          showBadge: false,
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Text(
            'A few final details',
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
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: _AddressCard(
            onChange: onAddressChange,
            address: savedAddress,
            isLoading: isLoadingAddress,
            error: addressError,
          ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Text('Delivery', style: context.lunti.sectionTitle),
        ),
        const SizedBox(height: LuntiSpacing.sm),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: _ShippingChoice(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            LuntiSpacing.gutter,
            LuntiSpacing.xs,
            LuntiSpacing.gutter,
            0,
          ),
          child: Text(
            'Illustrative shipping fee. Delivery timing is confirmed '
            'separately.',
            style: context.lunti.caption,
          ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: _PaymentCard(
            onChange: () =>
                Navigator.of(context).pushNamed('/payment'),
          ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Text(
            'Your order \u00B7 ${totals.itemCount} '
            '${totals.itemCount == 1 ? 'item' : 'items'}',
            style: context.lunti.sectionTitle,
          ),
        ),
        const SizedBox(height: LuntiSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: lines.isEmpty
              ? Text('Your bag is empty.', style: context.lunti.body)
              : _orderCard(context),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: _TotalsCard(totals: totals),
        ),
        const SizedBox(height: LuntiSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
          child: Text(
            'By placing your order, you agree to the Terms and Privacy '
            'Policy. Please review your address, items and total before '
            'continuing.',
            style: context.lunti.body,
          ),
        ),
        const SizedBox(height: LuntiSpacing.md),
        GestureDetector(
          onTap: onOrderHelp,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: LuntiSpacing.gutter),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: LuntiSpacing.sm),
                  child: Icon(
                    Icons.mode_comment_outlined,
                    size: 22,
                    color: context.lunti.text,
                    semanticLabel: 'Need help with your order?',
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need help with your order?',
                        style: context.lunti.cardTitle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Contact LUNTI before placing your order',
                        style: context.lunti.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 26,
                  color: context.lunti.text,
                  semanticLabel: 'Order help',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LuntiSpacing.sm),
      ],
    );
  }

  /// Order lines with one inline stock warning per short product.
  ///
  /// Quantities are aggregated per product (Natural + Engraved lines count
  /// together) so the warning matches what the transactional stock check uses.
  Widget _orderCard(BuildContext context) {
    final requested = StockService.requestedQuantities(lines);
    final warnedProducts = <String>{};
    final rows = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final product = products[line.productId];
      final available = product == null
          ? null
          : StockService.availableFor(product);
      final quantity = requested[line.productId] ?? line.quantity;
      final overStock = available != null && quantity > available;
      final showWarning =
          overStock && warnedProducts.add(line.productId);

      if (i > 0) {
        rows.add(Divider(color: context.lunti.border, height: 1));
      }
      rows.add(
        _OrderLineRow(
          line: line,
          product: product,
          stockWarning: showWarning ? available : null,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(children: rows),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.onChange,
    required this.address,
    required this.isLoading,
    required this.error,
  });

  final VoidCallback onChange;
  final Map<String, String> address;
  final bool isLoading;
  final String? error;

  String get _fullAddress {
    final parts = [
      address['street'],
      address['barangay'],
      address['city'],
      address['province'],
      address['postalCode'],
    ].where((p) => p.toString().trim().isNotEmpty).toList();
    return parts.isEmpty ? 'No saved address' : parts.join(', ');
  }

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
          Row(
            children: [
              Text('Deliver to', style: context.lunti.cardTitle),
              const Spacer(),
              _OutlinedPill(label: 'Edit', onTap: onChange),
            ],
          ),
          const SizedBox(height: LuntiSpacing.sm),
          if (isLoading)
            const SizedBox(
              height: 24,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (error != null)
            Text('Error loading address: $error',
                style: context.lunti.caption.copyWith(color: Colors.red))
          else if (address['street']?.toString().trim().isEmpty == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_filled, size: 20, color: context.lunti.accent),
                    const SizedBox(width: LuntiSpacing.sm),
                    Text('No saved address',
                        style: context.lunti.body.copyWith(
                          color: context.lunti.textFaint,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Tap Edit to add your delivery address',
                    style: context.lunti.caption.copyWith(
                      color: context.lunti.textFaint,
                    )),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_filled,
                        size: 20, color: context.lunti.accent),
                    const SizedBox(width: LuntiSpacing.sm),
                    Text('Home',
                        style: context.lunti.cardTitle.copyWith(
                          fontSize: 15,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_fullAddress, style: context.lunti.body),
                if (address['phone']?.toString().trim().isNotEmpty == true)
                  Text(address['phone']!, style: context.lunti.caption),
              ],
            ),
        ],
      ),
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  const _OutlinedPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.lunti.surface,
      shape: StadiumBorder(side: BorderSide(color: context.lunti.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: context.lunti.cardTitle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Selected shipping radio card. SAMPLE only: one option exists so the
/// frame's single choice stays honest; more carrier options come with
/// the Firebase integration.
class _ShippingChoice extends StatelessWidget {
  const _ShippingChoice();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.lunti.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
        side: BorderSide(color: context.lunti.text, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LuntiSpacing.md,
          vertical: LuntiSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard shipping \u00B7 \u20B180',
                    style: context.lunti.cardTitle,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'To your selected home address',
                    style: context.lunti.body,
                  ),
                ],
              ),
            ),
            const SizedBox(width: LuntiSpacing.md),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.lunti.accent,
                border: Border.fromBorderSide(
                  BorderSide(color: context.lunti.accent, width: 2),
                ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LuntiSpacing.md,
        LuntiSpacing.md,
        LuntiSpacing.md,
        LuntiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: LuntiSpacing.sm),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 22,
                  color: context.lunti.text,
                  semanticLabel: 'Payment method',
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<PaymentMethod>(
                      valueListenable: MockAppState.paymentMethod,
                      builder: (context, method, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: LuntiSpacing.xs,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Payment \u00B7 ${method.shortLabel}',
                                style: context.lunti.cardTitle,
                              ),
                              PaymentMethodBadge(method: method),
                            ],
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            key: const Key('paymentChangeText'),
                            onTap: onChange,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              'Selected payment method \u00B7 Change',
                              style: context.lunti.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                key: const Key('paymentChangeChevron'),
                onTap: onChange,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_right,
                    size: 26,
                    color: context.lunti.text,
                    semanticLabel: 'Change payment method',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ValueListenableBuilder<PaymentMethod>(
              valueListenable: MockAppState.paymentMethod,
              builder: (context, method, _) => Text(
                method.checkoutNote,
                style: context.lunti.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineRow extends StatelessWidget {
  const _OrderLineRow({
    required this.line,
    required this.product,
    this.stockWarning,
  });

  final BagLine line;
  final SampleProduct? product;

  /// Stock left for this product when the line is short; null hides the
  /// warning (either the line is fine or another line already warned).
  final int? stockWarning;

  @override
  Widget build(BuildContext context) {
    final product = this.product;
    if (product == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: LuntiSpacing.sm),
        child: Text(
          'Unknown product (${line.productId})',
          style: context.lunti.caption,
        ),
      );
    }

    final unitPrice = BagPricing.unitPrice(product, line);
    final styleText = BagPricing.styleText(product, line);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuntiSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 56,
            decoration: BoxDecoration(
              color: context.lunti.surface,
              borderRadius: BorderRadius.circular(LuntiRadii.sm),
            ),
            child: LuntiProductImage(
              image: product.image,
              semanticLabel: product.name,
            ),
          ),
          const SizedBox(width: LuntiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: context.lunti.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '$styleText \u00B7 Quantity ${line.quantity}',
                  style: context.lunti.caption,
                ),
                if (line.engravingText != null &&
                    line.engravingText!.isNotEmpty &&
                    line.variant == product.variantLabel) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Engraved: "${line.engravingText}"',
                    style: context.lunti.caption.copyWith(
                      color: context.lunti.textFaint,
                    ),
                  ),
                ],
                if (stockWarning != null) ...[
                  const SizedBox(height: 4),
                  StockWarningText(available: stockWarning!),
                ],
              ],
            ),
          ),
          const SizedBox(width: LuntiSpacing.sm),
          Text('\u20B1$unitPrice', style: context.lunti.price),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final _Totals totals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.surfaceAlt,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Subtotal', style: context.lunti.body),
              const Spacer(),
              Text('\u20B1${totals.subtotal}', style: context.lunti.body),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Row(
            children: [
              Text('Standard shipping', style: context.lunti.body),
              const Spacer(),
              Text(
                '\u20B1${totals.shippingFeePeso}',
                style: context.lunti.body,
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text('Total', style: context.lunti.cardTitle),
              ),
              Text(
                '\u20B1${totals.total}',
                style: context.lunti.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
