import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lunti_app/data/mock_app_state.dart';
import 'package:lunti_app/data/payment_method.dart';
import 'package:lunti_app/screens/shop/checkout_screen.dart';
import 'package:lunti_app/screens/shop/order_confirmation_screen.dart';
import 'package:lunti_app/screens/shop/payment_screen.dart';
import 'package:lunti_app/screens/shop/simulated_payment_screen.dart';
import 'package:lunti_app/services/catalog_store.dart';

/// Opens [SimulatedPaymentScreen] from a real route so `pop(true/false)` can
/// be observed the same way Checkout observes it.
Future<ValueNotifier<bool?>> _openPayment(
  WidgetTester tester,
  PaymentMethod method, {
  int total = 980,
  int itemCount = 2,
}) async {
  final result = ValueNotifier<bool?>(null);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('launchPayment'),
              onPressed: () async {
                result.value = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => SimulatedPaymentScreen(
                      method: method,
                      total: total,
                      itemCount: itemCount,
                    ),
                  ),
                );
              },
              child: const Text('Launch payment'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('launchPayment')));
  await tester.pumpAndSettle();
  return result;
}

Order _order(PaymentMethod method) {
  return MockAppState.placeOrder(
    items: [BagLine('phone-speaker', variant: 'Natural', quantity: 2)],
    subtotal: 900,
    shippingFee: 80,
    total: 980,
    paymentMethod: method.label,
  );
}

void main() {
  setUp(() {
    MockAppState.reset();
    CatalogStore.instance.resetToBundledCatalog();
  });

  group('PaymentMethod', () {
    test('uses the exact checkout labels', () {
      expect(PaymentMethod.cashOnDelivery.label, 'Cash on Delivery');
      expect(PaymentMethod.gcash.label, 'GCash (Simulated)');
      expect(PaymentMethod.card.label, 'Credit/Debit Card (Simulated)');
    });

    test('marks only COD as a real payment', () {
      expect(PaymentMethod.cashOnDelivery.isSimulated, isFalse);
      expect(PaymentMethod.gcash.isSimulated, isTrue);
      expect(PaymentMethod.card.isSimulated, isTrue);

      expect(
        PaymentMethod.cashOnDelivery.badgeLabel,
        'REAL PAYMENT / COD',
      );
      expect(PaymentMethod.gcash.badgeLabel, 'SIMULATION');
      expect(PaymentMethod.card.badgeLabel, 'SIMULATION');
    });

    test('maps methods to the saved payment status', () {
      expect(PaymentMethod.gcash.paymentStatus, 'Paid (GCash)');
      expect(PaymentMethod.card.paymentStatus, 'Paid (Card)');
      expect(PaymentMethod.cashOnDelivery.paymentStatus, 'Unpaid (COD)');
    });

    test('maps stored methods onto their paid variant', () {
      expect(PaymentMethodX.paidStatusFor('Cash on Delivery'), 'Paid (COD)');
      expect(PaymentMethodX.paidStatusFor('cash_on_delivery'), 'Paid (COD)');
      expect(PaymentMethodX.paidStatusFor('COD'), 'Paid (COD)');
      expect(
        PaymentMethodX.paidStatusFor('GCash (Simulated)'),
        'Paid (GCash)',
      );
      expect(
        PaymentMethodX.paidStatusFor('Credit/Debit Card (Simulated)'),
        'Paid (Card)',
      );
      expect(PaymentMethodX.paidStatusFor(''), 'Paid');
      expect(PaymentMethodX.paidStatusFor(null), 'Paid');
    });

    test('parses new labels and legacy stored values', () {
      expect(
        PaymentMethodX.parse('Cash on Delivery'),
        PaymentMethod.cashOnDelivery,
      );
      expect(
        PaymentMethodX.parse('cash_on_delivery'),
        PaymentMethod.cashOnDelivery,
      );
      expect(PaymentMethodX.parse('GCash (Simulated)'), PaymentMethod.gcash);
      expect(PaymentMethodX.parse('gcash'), PaymentMethod.gcash);
      expect(
        PaymentMethodX.parse('Credit/Debit Card (Simulated)'),
        PaymentMethod.card,
      );
      expect(PaymentMethodX.parse('credit_card'), PaymentMethod.card);
    });
  });

  group('SimulatedPaymentScreen', () {
    testWidgets('GCash simulation completes and returns true', (tester) async {
      final result = await _openPayment(tester, PaymentMethod.gcash);

      expect(find.text('Complete your payment'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('SIMULATION'), findsOneWidget);
      expect(find.text('\u20B1980'), findsOneWidget);
      expect(find.text('Complete Simulated Payment'), findsOneWidget);
      expect(find.text('Simulate Failed Payment'), findsOneWidget);
      expect(find.textContaining('No real money moves'), findsOneWidget);

      await tester.tap(find.byKey(const Key('completeSimulatedPayment')));
      await tester.pumpAndSettle();

      expect(result.value, isTrue);
      expect(find.byType(SimulatedPaymentScreen), findsNothing);
    });

    testWidgets('card simulation shows card branding and returns true', (
      tester,
    ) async {
      final result = await _openPayment(tester, PaymentMethod.card);

      expect(find.text('Credit/Debit Card'), findsOneWidget);
      expect(find.text('SIMULATION'), findsOneWidget);
      expect(
        find.textContaining('card number or CVV'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('completeSimulatedPayment')));
      await tester.pumpAndSettle();

      expect(result.value, isTrue);
    });

    testWidgets('failed simulation creates no result and can retry or return', (
      tester,
    ) async {
      final result = await _openPayment(tester, PaymentMethod.gcash);

      await tester.tap(find.byKey(const Key('simulateFailedPayment')));
      await tester.pumpAndSettle();

      expect(find.text('Simulated payment failed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Return to checkout'), findsOneWidget);
      expect(result.value, isNull);

      // Try again restores the normal simulation actions.
      await tester.tap(find.byKey(const Key('tryAgainPayment')));
      await tester.pumpAndSettle();
      expect(find.text('Complete Simulated Payment'), findsOneWidget);

      // A second failure can be abandoned back to Checkout.
      await tester.tap(find.byKey(const Key('simulateFailedPayment')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('returnToCheckout')));
      await tester.pumpAndSettle();

      expect(result.value, isFalse);
      expect(find.byType(SimulatedPaymentScreen), findsNothing);
    });

    testWidgets('COD confirmation shows cash reminder and returns true', (
      tester,
    ) async {
      final result = await _openPayment(
        tester,
        PaymentMethod.cashOnDelivery,
      );

      expect(find.text('Confirm cash on delivery'), findsOneWidget);
      expect(find.text('Pay in cash upon delivery'), findsOneWidget);
      expect(find.text('Amount to pay on delivery'), findsOneWidget);
      expect(find.text('\u20B1980'), findsOneWidget);
      expect(find.text('Confirm COD Request'), findsOneWidget);
      expect(
        find.textContaining('Pay \u20B1980 upon delivery'),
        findsOneWidget,
      );
      expect(find.text('Complete Simulated Payment'), findsNothing);
      expect(find.text('Simulate Failed Payment'), findsNothing);

      await tester.tap(find.byKey(const Key('confirmCodRequest')));
      await tester.pumpAndSettle();

      expect(result.value, isTrue);
    });
  });

  group('PaymentScreen', () {
    testWidgets('lists the three exact options with badges', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PaymentScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Cash on Delivery'), findsOneWidget);
      // The selected GCash option also appears in the summary card below.
      expect(find.text('GCash (Simulated)'), findsNWidgets(2));
      expect(find.text('Credit/Debit Card (Simulated)'), findsOneWidget);
      expect(find.text('REAL PAYMENT / COD'), findsOneWidget);
      expect(find.text('SIMULATION'), findsNWidgets(3));
      expect(find.text('Use GCash'), findsOneWidget);

      await tester.tap(find.text('Credit/Debit Card (Simulated)'));
      await tester.pumpAndSettle();

      expect(MockAppState.paymentMethod.value, PaymentMethod.card);
      expect(find.text('Use Credit/Debit Card'), findsOneWidget);
    });
  });

  group('Checkout payment handoff', () {
    Future<void> saveAddress(WidgetTester tester) async {
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '12 Bamboo St');
      await tester.enterText(fields.at(1), 'San Roque');
      await tester.enterText(fields.at(2), 'Cardona');
      await tester.enterText(fields.at(3), 'Rizal');
      await tester.enterText(fields.at(4), '1950');
      await tester.enterText(fields.at(5), '+63 912 345 6789');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save address'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      // Let the "Delivery address saved." snackbar clear so it cannot cover
      // the sticky Place order button.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    testWidgets('opens the simulation before saving the order', (tester) async {
      var placedOrders = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(
            onPlaceOrder: () async {
              placedOrders++;
              return CheckoutOrderResult.success();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveAddress(tester);

      await tester.scrollUntilVisible(
        find.textContaining('Place order'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Place order'));
      await tester.pumpAndSettle();

      // Default method is GCash, so the simulated provider screen opens.
      expect(find.byType(SimulatedPaymentScreen), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('\u20B1670'), findsOneWidget);
      expect(placedOrders, 0);

      // A failed simulation returns to Checkout without creating an order.
      await tester.tap(find.byKey(const Key('simulateFailedPayment')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('returnToCheckout')));
      await tester.pumpAndSettle();

      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(placedOrders, 0);

      // Completing the simulation then hands the order to Checkout.
      await tester.tap(find.textContaining('Place order'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('completeSimulatedPayment')));
      await tester.pumpAndSettle();

      expect(placedOrders, 1);
    });
  });

  group('Order payment state', () {
    test('placeOrder derives the status from the exact method label', () {
      final gcash = _order(PaymentMethod.gcash);
      expect(gcash.paymentMethod, 'GCash (Simulated)');
      expect(gcash.paymentStatus, 'Paid (GCash)');

      final card = _order(PaymentMethod.card);
      expect(card.paymentMethod, 'Credit/Debit Card (Simulated)');
      expect(card.paymentStatus, 'Paid (Card)');

      final cod = _order(PaymentMethod.cashOnDelivery);
      expect(cod.paymentMethod, 'Cash on Delivery');
      expect(cod.paymentStatus, 'Unpaid (COD)');
    });

    test('explicit payment status is preserved', () {
      final order = MockAppState.placeOrder(
        items: [BagLine('coaster')],
        subtotal: 140,
        shippingFee: 80,
        total: 220,
        paymentMethod: PaymentMethod.gcash.label,
        paymentStatus: 'Paid (GCash)',
      );

      expect(order.paymentStatus, 'Paid (GCash)');
    });

    test('a completed COD order reads as paid', () {
      final order = _order(PaymentMethod.cashOnDelivery);
      order.status = OrderStatus.completed;

      expect(order.hasPaidOnRecord, isFalse);
      expect(order.isPaymentPaid, isTrue);
      expect(order.paymentStatusDisplay, 'Paid (COD)');
    });

    test('an unfinished COD order stays unpaid', () {
      final order = _order(PaymentMethod.cashOnDelivery);

      expect(order.isPaymentPaid, isFalse);
      expect(order.paymentStatusDisplay, 'Unpaid (COD)');
    });

    test('a completed wallet order keeps its own label', () {
      final order = _order(PaymentMethod.gcash);
      order.status = OrderStatus.completed;

      expect(order.paymentStatusDisplay, 'Paid (GCash)');
    });

    test('an empty stored status falls back to the method default', () {
      final order = MockAppState.placeOrder(
        items: [BagLine('coaster')],
        subtotal: 140,
        shippingFee: 80,
        total: 220,
        paymentMethod: PaymentMethod.cashOnDelivery.label,
        paymentStatus: '',
      );

      expect(order.paymentStatusDisplay, 'Unpaid (COD)');
    });
  });

  group('OrderConfirmationScreen', () {
    testWidgets('simulated receipt shows method and paid badge', (
      tester,
    ) async {
      final order = _order(PaymentMethod.gcash);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderConfirmationScreen(
            order: order,
            onBackHome: () {},
            onViewOrders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order confirmed'), findsOneWidget);
      expect(find.text('Order ID'), findsOneWidget);
      expect(find.text(order.id), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('\u20B1900'), findsOneWidget);
      expect(find.text('\u20B1980'), findsOneWidget);
      expect(find.text('GCash (Simulated)'), findsOneWidget);
      expect(find.text('Paid (GCash)'), findsOneWidget);
      expect(
        find.textContaining('No real payment was processed'),
        findsOneWidget,
      );
    });

    testWidgets('COD receipt shows unpaid badge and cash reminder', (
      tester,
    ) async {
      final order = _order(PaymentMethod.cashOnDelivery);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderConfirmationScreen(
            order: order,
            onBackHome: () {},
            onViewOrders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order request received'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('Unpaid (COD)'), findsOneWidget);
      expect(
        find.textContaining('Please prepare \u20B1980 in cash'),
        findsOneWidget,
      );
    });
  });
}
