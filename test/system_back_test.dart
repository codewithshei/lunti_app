import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lunti_app/data/mock_app_state.dart';
import 'package:lunti_app/main.dart';
import 'package:lunti_app/services/catalog_store.dart';
import 'package:lunti_app/services/chat_service.dart';
import 'package:lunti_app/services/notification_service.dart';
import 'package:lunti_app/services/review_service.dart';
import 'package:lunti_app/widgets/lunti_nav_bar.dart';

/// Sends the Android system back event (button or gesture) to the app, then
/// lets the navigation transition settle.
Future<void> pressSystemBack(WidgetTester tester) async {
  // ignore: invalid_use_of_protected_member
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

LuntiTab currentTab(WidgetTester tester) =>
    tester.widget<LuntiNavBar>(find.byType(LuntiNavBar)).currentTab;

void main() {
  setUp(() {
    MockAppState.reset();
    CatalogStore.instance.resetToBundledCatalog();
    ReviewService.instance.resetLocal();
    NotificationService.instance.resetLocal();
    ChatService.instance.resetLocal();
  });

  testWidgets('system back pops the Shop tab stack before leaving the tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    expect(find.text('Shop by craft'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Explore all products'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore all products'));
    await tester.pumpAndSettle();
    expect(find.text('The bamboo collection'), findsOneWidget);

    // First back: pop Catalog -> Categories, still inside the Shop tab.
    // The Categories list keeps its scroll offset, so assert on the row that
    // was visible rather than the header that scrolled away.
    await pressSystemBack(tester);
    expect(find.text('The bamboo collection'), findsNothing);
    expect(find.text('Explore all products'), findsOneWidget);
    expect(currentTab(tester), LuntiTab.shop);

    // Second back: leave the Shop landing for the Home tab.
    await pressSystemBack(tester);
    expect(currentTab(tester), LuntiTab.home);
    expect(find.text('A little nature.\nA lot of character.'), findsOneWidget);
  });

  testWidgets('system back pops a pushed shop flow one screen at a time', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    // Home's category card pushes a catalog flow on the root navigator.
    await tester.scrollUntilVisible(
      find.text('Miniature'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Miniature'));
    await tester.pumpAndSettle();
    expect(find.text('The bamboo collection'), findsOneWidget);

    // Open a product inside that pushed flow.
    await tester.scrollUntilVisible(
      find.text('Gazebo').last,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gazebo').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Add to bag'), findsOneWidget);

    // First back: product details -> catalog, not out of the whole flow.
    await pressSystemBack(tester);
    expect(find.textContaining('Add to bag'), findsNothing);
    expect(find.text('Gazebo'), findsWidgets);

    // Second back: leave the pushed flow and return to Home. Gazebo can still
    // appear in Home's recently-viewed rail, so assert on the tab instead.
    await pressSystemBack(tester);
    expect(currentTab(tester), LuntiTab.home);
    expect(find.text('Miniature'), findsWidgets);
  });

  testWidgets('system back returns Wishlist and Profile to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wishlist').last);
    await tester.pumpAndSettle();
    expect(currentTab(tester), LuntiTab.wishlist);

    await pressSystemBack(tester);
    expect(currentTab(tester), LuntiTab.home);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(currentTab(tester), LuntiTab.profile);

    await pressSystemBack(tester);
    expect(currentTab(tester), LuntiTab.home);
  });

  testWidgets('Profile order history stays inside the Profile tab', (
    WidgetTester tester,
  ) async {
    final order = MockAppState.buildOrder(
      items: [BagLine('phone-speaker', variant: 'Natural')],
      subtotal: 1,
      shippingFee: 0,
      total: 1,
      paymentMethod: 'GCash',
    );
    MockAppState.orders.value = [order];

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(currentTab(tester), LuntiTab.profile);

    await tester.scrollUntilVisible(
      find.text('My orders'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My orders'));
    await tester.pumpAndSettle();

    // Order history is open and the Profile tab is still selected.
    expect(find.text('Order history'), findsWidgets);
    expect(currentTab(tester), LuntiTab.profile);

    // Opening an order pushes the details page inside the same tab.
    await tester.tap(find.text(order.id));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Track order'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Track order'), findsOneWidget);
    expect(currentTab(tester), LuntiTab.profile);

    // App-bar back returns to the history list, still inside Profile.
    await tester.tap(find.byIcon(Icons.chevron_left).last);
    await tester.pumpAndSettle();
    expect(find.text('Track order'), findsNothing);
    expect(find.text('Order history'), findsWidgets);
    expect(currentTab(tester), LuntiTab.profile);

    // System back then pops the history list and lands on the account screen.
    await pressSystemBack(tester);
    expect(find.text('Order history'), findsNothing);
    expect(currentTab(tester), LuntiTab.profile);
  });

  testWidgets('system back on the Home root asks the platform to exit', (
    WidgetTester tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();
    expect(currentTab(tester), LuntiTab.home);

    await pressSystemBack(tester);

    expect(
      calls.where((call) => call.method == 'SystemNavigator.pop'),
      isNotEmpty,
    );
  });
}
