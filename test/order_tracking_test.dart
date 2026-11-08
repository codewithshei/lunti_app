import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lunti_app/data/mock_app_state.dart';
import 'package:lunti_app/data/payment_method.dart';
import 'package:lunti_app/screens/shop/order_confirmation_screen.dart';
import 'package:lunti_app/screens/shop/order_tracking_screen.dart';
import 'package:lunti_app/services/catalog_store.dart';

Order _order({
  OrderStatus status = OrderStatus.pending,
  List<OrderStatusHistoryEntry>? history,
}) {
  return Order(
    id: 'LNT-TEST-001',
    items: <BagLine>[
      BagLine('phone-speaker', variant: 'Natural', quantity: 2),
    ],
    subtotal: 900,
    shippingFee: 80,
    total: 980,
    paymentMethod: PaymentMethod.gcash.label,
    addressTitle: 'Home',
    addressLine1: '12 Bamboo St',
    addressLine2: 'Cardona, Rizal',
    phone: '+63 912 345 6789',
    createdAt: DateTime(2026, 11, 7, 15, 42),
    customerName: 'Maya Santos',
    status: status,
    statusHistory: history ?? const <OrderStatusHistoryEntry>[],
  );
}

void _usePhoneViewport(WidgetTester tester) {
  // LUNTI design width, so the whole tracking card is on screen.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const MethodChannel _printingChannel = MethodChannel('net.nfet.printing');

void main() {
  setUp(() {
    MockAppState.reset();
    CatalogStore.instance.resetToBundledCatalog();
    // The printing plugin has no platform implementation in widget tests, so
    // answer its channel directly instead of letting the share call hang.
    // sharePdf returns an int status code (0 = shared).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _printingChannel,
          (MethodCall call) async => 0,
        );
  });

  testWidgets('tracking shows every step and the receipt button', (
    tester,
  ) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(home: OrderTrackingScreen(order: _order(), onBack: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Packed'), findsOneWidget);
    expect(find.text('Shipped'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(4));
    expect(find.text('Download receipt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reached steps show timestamps from the status history', (
    tester,
  ) async {
    _usePhoneViewport(tester);

    final order = _order(
      status: OrderStatus.shipped,
      history: <OrderStatusHistoryEntry>[
        OrderStatusHistoryEntry(
          status: OrderStatus.pending,
          at: DateTime(2026, 11, 7, 9, 5),
          by: 'customer',
        ),
        OrderStatusHistoryEntry(
          status: OrderStatus.approved,
          at: DateTime(2026, 11, 7, 10, 30),
          by: 'admin',
        ),
        OrderStatusHistoryEntry(
          status: OrderStatus.packed,
          at: DateTime(2026, 11, 8, 8, 0),
          by: 'admin',
        ),
        OrderStatusHistoryEntry(
          status: OrderStatus.shipped,
          at: DateTime(2026, 11, 9, 14, 15),
          by: 'admin',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: OrderTrackingScreen(order: order, onBack: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nov 7, 2026 · 9:05 AM'), findsOneWidget);
    expect(find.text('Nov 7, 2026 · 10:30 AM'), findsOneWidget);
    expect(find.text('Nov 8, 2026 · 8:00 AM'), findsOneWidget);
    expect(find.text('Nov 9, 2026 · 2:15 PM'), findsOneWidget);
    // Only the unreached "Completed" step has no timestamp.
    expect(find.text('—'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('legacy orders with an empty history still show the steps', (
    tester,
  ) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: OrderTrackingScreen(
          order: _order(status: OrderStatus.approved),
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    // The placement step falls back to the order date.
    expect(find.text('Nov 7, 2026 · 3:42 PM'), findsOneWidget);
    // Steps after the current one have no recorded timestamp.
    expect(find.text('—'), findsNWidgets(4));
  });

  testWidgets('cancelled orders show the cancelled treatment, not a timeline', (
    tester,
  ) async {
    _usePhoneViewport(tester);

    final order = _order(
      status: OrderStatus.cancelled,
      history: <OrderStatusHistoryEntry>[
        OrderStatusHistoryEntry(
          status: OrderStatus.pending,
          at: DateTime(2026, 11, 7, 9, 0),
          by: 'customer',
        ),
        OrderStatusHistoryEntry(
          status: OrderStatus.cancelled,
          at: DateTime(2026, 11, 7, 12, 0),
          by: 'admin',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: OrderTrackingScreen(order: order, onBack: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order cancelled'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.text('Cancelled on Nov 7, 2026 · 12:00 PM'), findsOneWidget);
    expect(find.text('Order placed'), findsNothing);
    expect(find.text('Shipped'), findsNothing);
    expect(find.text('Download receipt'), findsOneWidget);
  });

  testWidgets('tapping the receipt button confirms without hanging', (
    tester,
  ) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(home: OrderTrackingScreen(order: _order(), onBack: () {})),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Download receipt'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation screen offers the receipt download', (tester) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: OrderConfirmationScreen(
          order: _order(),
          onBackHome: () {},
          onViewOrders: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Download receipt'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Download receipt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
