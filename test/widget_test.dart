import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lunti_app/data/mock_app_state.dart';
import 'package:lunti_app/data/payment_method.dart';
import 'package:lunti_app/data/sample_catalog.dart';
import 'package:lunti_app/main.dart';
import 'package:lunti_app/models/product_review.dart';
import 'package:lunti_app/screens/auth/auth_screen.dart';
import 'package:lunti_app/screens/auth/guest_account_screen.dart';
import 'package:lunti_app/screens/notifications_screen.dart';
import 'package:lunti_app/screens/shop/checkout_screen.dart';
import 'package:lunti_app/screens/shop/order_details_screen.dart';
import 'package:lunti_app/screens/shop/personalization_screen.dart';
import 'package:lunti_app/screens/shop/product_details_screen.dart';
import 'package:lunti_app/screens/support_chat_screen.dart';
import 'package:lunti_app/services/catalog_store.dart';
import 'package:lunti_app/services/chat_service.dart';
import 'package:lunti_app/services/notification_service.dart';
import 'package:lunti_app/services/order_service.dart';
import 'package:lunti_app/widgets/brand_header.dart';
import 'package:lunti_app/widgets/lunti_nav_bar.dart';
import 'package:lunti_app/services/review_service.dart';
import 'package:lunti_app/services/stock_service.dart';
import 'package:lunti_app/widgets/category_tile.dart';
import 'package:lunti_app/widgets/product_card.dart';

void main() {
  setUp(() {
    MockAppState.reset();
    CatalogStore.instance.resetToBundledCatalog();
    ReviewService.instance.resetLocal();
    NotificationService.instance.resetLocal();
    ChatService.instance.resetLocal();
  });

  testWidgets('LUNTI Home shows headline and sample catalog', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    expect(find.text('A little nature.\nA lot of character.'), findsOneWidget);
    expect(find.text('Shop by craft'), findsOneWidget);    await tester.scrollUntilVisible(
      find.text('Phone Speaker'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Phone Speaker'), findsOneWidget);
    final speakerCard = find.ancestor(
      of: find.text('Phone Speaker'),
      matching: find.byType(ProductCard),
    );
    expect(speakerCard, findsOneWidget);
    expect(
      find.descendant(of: speakerCard, matching: find.text('\u20B1450')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Discover our craft'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Discover our craft'), findsOneWidget);
  });

  testWidgets('Shop tab opens Categories then Catalog', (WidgetTester tester) async {
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

    expect(find.text('Explore all products'), findsOneWidget);

    await tester.tap(find.text('Explore all products'));
    await tester.pumpAndSettle();

    expect(find.text('The bamboo collection'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsOneWidget);
    expect(find.text('Coaster'), findsOneWidget);

    await tester.tap(find.text('Plaques').last);
    await tester.pumpAndSettle();

    expect(find.text('Table Bar Name'), findsOneWidget);
    expect(find.text('Coaster'), findsNothing);

    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search bamboo crafts'));
    await tester.pumpAndSettle();

    expect(find.text('Find a little character'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'speaker');
    await tester.pumpAndSettle();
    expect(find.text('View product'), findsOneWidget);
  });

  testWidgets('Product opens, updates quantity, and Engraved opens Personalization', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Explore all products'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore all products'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Phone Speaker').last,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone Speaker').last);
    await tester.pumpAndSettle();

    expect(find.text('BAMBOO EVERYDAY'), findsOneWidget);
    expect(find.text('Add to bag \u00B7 \u20B1450'), findsOneWidget);
    expect(find.text('Made with character'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Engraved').last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Engraved').last);
    await tester.pumpAndSettle();

    expect(find.text('Make it yours'), findsOneWidget);
    expect(find.text('Add to bag \u00B7 \u20B1550'), findsOneWidget);
    expect(find.textContaining('Maya'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.byIcon(Icons.add),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add to bag \u00B7 \u20B11100'), findsOneWidget);
  });

  testWidgets('Engraving text is stored with the bag line', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Explore all products'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore all products'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Phone Speaker').last,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone Speaker').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Engraved').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engraved').last);
    await tester.pumpAndSettle();

    expect(find.text('Make it yours'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Jose');

    await tester.scrollUntilVisible(
      find.text('Add to bag \u00B7 \u20B1550'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to bag \u00B7 \u20B1550'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Engraved: "Jose"'), findsOneWidget);
    expect(find.text('Engraved \u00B7 Quantity 1'), findsOneWidget);
  });

  testWidgets('Wishlist lists saved products and supports remove', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wishlist').last);
    await tester.pumpAndSettle();

    expect(find.text('Worth coming back to'), findsOneWidget);
    expect(find.text('Phone Speaker \u00B7 Natural'), findsOneWidget);
    expect(find.text('Saved to your wishlist'), findsNWidgets(2));
    expect(find.text('Add to bag'), findsNWidgets(2));

    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();

    expect(find.text('Phone Speaker \u00B7 Natural'), findsNothing);

    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No saved pieces yet'),
      findsOneWidget,
    );
  });

  testWidgets('catalog grid fits a phone-width screen without overflow', (
    WidgetTester tester,
  ) async {
    // The default 800x600 test surface hides card overflows; 390 is the
    // LUNTI design width.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Explore all products'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore all products'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Bamboo craft').first,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Home category cards are tall and fit a phone-width screen', (
    WidgetTester tester,
  ) async {
    // LUNTI design width: the full-bleed category cards must be ~180px tall and
    // must not overflow their grid cells.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Shop by craft'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CategoryHeroTile), findsNWidgets(4));
    expect(tester.getSize(find.byType(CategoryHeroTile).first).height, 180);
    expect(find.text('Miniature'), findsOneWidget);
    expect(find.text('Customized'), findsOneWidget);
    expect(find.text('Plaque'), findsOneWidget);
    expect(find.text('Engraving'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home category card opens the catalog pre-filtered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Miniature'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Miniature'));
    await tester.pumpAndSettle();

    // The Shop tab opens the catalog filtered to the tapped craft.
    expect(find.text('The bamboo collection'), findsOneWidget);
    expect(find.text('Gazebo'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsNothing);
  });

  testWidgets('Home category card returns to Home on back, not the Shop tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Miniature'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Miniature'));
    await tester.pumpAndSettle();

    // The catalog is pushed onto the root stack, filtered to the tapped craft.
    expect(find.text('The bamboo collection'), findsOneWidget);
    expect(find.text('Gazebo'), findsOneWidget);

    // Back leaves the pushed flow and returns to the root with Home still
    // selected — not the Shop tab's category landing, which is what the old
    // tab-switching behaviour did.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('The bamboo collection'), findsNothing);
    expect(find.text('The LUNTI shop'), findsNothing);
    expect(
      tester.widget<LuntiNavBar>(find.byType(LuntiNavBar)).currentTab,
      LuntiTab.home,
    );
  });

  testWidgets('Home bag badge shares the live cart count', (tester) async {
    MockAppState.reset();

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    // Two seeded bag lines -> a "2" badge in Home's header.
    expect(
      find.descendant(of: find.byType(BrandHeader), matching: find.text('2')),
      findsOneWidget,
    );

    // The badge tracks the shared bag state, so it matches the Shop tab's.
    MockAppState.bag.value = [
      ...MockAppState.bag.value,
      BagLine('bamboo-clock'),
    ];
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(BrandHeader), matching: find.text('3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(BrandHeader), matching: find.text('2')),
      findsNothing,
    );
  });

  testWidgets('Categories screen uses the same tall hero cards as Home', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Discover'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CategoryHeroTile), findsNWidgets(4));
    expect(find.byType(CategoryTile), findsNothing);
    expect(tester.getSize(find.byType(CategoryHeroTile).first).height, 180);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bag opens with seeded lines and supports edit', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Your bag'), findsOneWidget);
    expect(find.text('Two little pieces of everyday warmth.'), findsOneWidget);
    expect(find.text('Natural \u00B7 Quantity 1'), findsOneWidget);
    expect(find.text('Bamboo \u00B7 Quantity 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Subtotal \u00B7 2 items'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Subtotal \u00B7 2 items'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();

    expect(find.text('Phone Speaker'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Subtotal \u00B7 1 item'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Subtotal \u00B7 1 item'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();

    expect(find.text('Your bag is empty'), findsOneWidget);
    expect(find.text('Nothing in here yet.'), findsOneWidget);
  });

  testWidgets('Checkout shows delivery details and totals', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('A few final details'), findsOneWidget);
    expect(find.text('Deliver to'), findsOneWidget);
    expect(find.text('No saved address'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Payment \u00B7 GCash'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Payment \u00B7 GCash'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Total'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('\u20B1590'), findsOneWidget);
    expect(find.text('\u20B1670'), findsOneWidget);
    expect(find.textContaining('Place order \u00B7 \u20B1670'), findsOneWidget);

    
  });

  testWidgets('Checkout help opens the support chat', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Need help with your order?'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Need help with your order?'));
    await tester.pumpAndSettle();

    expect(find.byType(SupportChatScreen), findsOneWidget);
    expect(find.text('Start a conversation'), findsOneWidget);
  });

  testWidgets('Category tile opens the catalog pre-filtered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Plaques').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plaques').first);
    await tester.pumpAndSettle();

    expect(find.text('The bamboo collection'), findsOneWidget);
    expect(find.text('Table Bar Name'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsNothing);
  });

  testWidgets('Checkout address sheet validates and saves the address', (
    WidgetTester tester,
  ) async {
    MockAppState.bag.value = [];
    await tester.pumpWidget(
    MaterialApp(home: CheckoutScreen(onPlaceOrder: () async => CheckoutOrderResult.success())),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved address'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery address'), findsOneWidget);

    await tester.ensureVisible(find.text('Save address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
    expect(find.text('Enter your postal code.'), findsOneWidget);
    expect(find.text('Enter a phone number.'), findsOneWidget);

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

    expect(find.text('Delivery address'), findsNothing);
    expect(find.textContaining('12 Bamboo St'), findsOneWidget);
  });

  testWidgets('Explore shop from Home opens category landing', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore shop'));
    await tester.pumpAndSettle();

    expect(find.text('Shop by craft'), findsOneWidget);
    expect(find.text('A few final details'), findsNothing);
    expect(find.text('Your bag'), findsNothing);
  });

  testWidgets('Thoughtfully picked rail scrolls horizontally and Shop all opens the catalog', (
    WidgetTester tester,
  ) async {
    // LUNTI design width: the rail must fit two cards without overflow.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Thoughtfully picked'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // The section is a single horizontal rail, not a vertical grid.
    final horizontalRail = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.right,
    );
    expect(horizontalRail, findsOneWidget);
    expect(find.text('Phone Speaker'), findsOneWidget);

    await tester.drag(horizontalRail, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The header action opens the full shop catalog, not the category landing.
    await tester.ensureVisible(find.text('Shop all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop all'));
    await tester.pumpAndSettle();

    expect(find.text('The bamboo collection'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsOneWidget);
    expect(find.text('Coaster'), findsOneWidget);
  });

  testWidgets('Search filters as the customer types', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    // Home search field opens the real Search screen, which starts empty.
    await tester.tap(find.text('Search bamboo crafts').first);
    await tester.pumpAndSettle();

    expect(find.text('Find a little character'), findsOneWidget);
    expect(find.textContaining('results for'), findsNothing);

    await tester.enterText(find.byType(TextField), 'speaker');
    await tester.pumpAndSettle();

    expect(find.text('2 results for \u201Cspeaker\u201D'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsOneWidget);
    expect(find.text('View product'), findsOneWidget);

    // Clearing the query falls back to the recents state.
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('results for'), findsNothing);
    expect(find.text('Recently searched'), findsOneWidget);

    // Tapping the recent search re-runs the query.
    await tester.tap(find.text('speaker').last);
    await tester.pumpAndSettle();

    expect(find.text('2 results for \u201Cspeaker\u201D'), findsOneWidget);

    // The compact more-matches row sits below the fold.
    await tester.scrollUntilVisible(
      find.text('Small Speaker'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('More matches'), findsOneWidget);
    expect(find.text('Small Speaker'), findsOneWidget);
  });

  testWidgets('Catalog filters narrow the grid', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Explore all products'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore all products'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Under \u20B1500'));
    await tester.tap(find.text('Engraved styles available'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show pieces'));
    await tester.pumpAndSettle();

    expect(find.text('Filters \u00B7 2'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsOneWidget);
    expect(find.text('Small Speaker'), findsOneWidget);
    expect(find.text('Wooden Truck'), findsNothing);
  });

  testWidgets('Catalog sort reorders the grid', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Explore all products'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore all products'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sort \u00B7 Recommended'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Price low to high'));
    await tester.pumpAndSettle();

    expect(find.text('Sort \u00B7 Price low to high'), findsOneWidget);
    // Cheapest pieces first: Coaster at \u20B1140, then Small Speaker at \u20B1150.
    expect(find.text('Coaster'), findsOneWidget);
    expect(find.text('Small Speaker'), findsOneWidget);
  });

  test('different engraving text stays on separate bag lines', () {
    MockAppState.bag.value = [];

    MockAppState.addLine(
      'phone-speaker',
      variant: 'Engraved',
      engravingText: 'Maya',
    );
    MockAppState.addLine(
      'phone-speaker',
      variant: 'Engraved',
      engravingText: 'Ava',
    );

    expect(MockAppState.bag.value, hasLength(2));
    expect(
      MockAppState.bag.value.map((line) => line.engravingText).toSet(),
      {'Maya', 'Ava'},
    );
  });

  testWidgets('single-price products do not offer engraving', (
    WidgetTester tester,
  ) async {
    final coaster = sampleProducts.firstWhere((product) => product.id == 'coaster');
    await tester.pumpWidget(MaterialApp(home: ProductDetailsScreen(product: coaster)));
    await tester.pumpAndSettle();

    expect(find.text('Planning a personalized gift?'), findsNothing);
  });

  testWidgets('blank engraving text cannot be added to the bag', (
    WidgetTester tester,
  ) async {
    MockAppState.bag.value = [];
    final phoneSpeaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');
    await tester.pumpWidget(
      MaterialApp(home: PersonalizationScreen(product: phoneSpeaker)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.textContaining('Add to bag'),
        matching: find.byType(FilledButton),
      ),
    );

    expect(button.onPressed, isNull);
    expect(MockAppState.bag.value, isEmpty);
    expect(
      find.text('Enter the text to engrave before adding to your bag.'),
      findsOneWidget,
    );
  });

  testWidgets('valid engraving text is added to the bag', (
    WidgetTester tester,
  ) async {
    MockAppState.bag.value = [];
    final phoneSpeaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');
    await tester.pumpWidget(
      MaterialApp(home: PersonalizationScreen(product: phoneSpeaker)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ava');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Add to bag'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Add to bag'));
    await tester.pumpAndSettle();

    expect(MockAppState.bag.value, hasLength(1));
    expect(MockAppState.bag.value.single.engravingText, 'Ava');
  });

  testWidgets('engraving text is limited to twenty characters', (
    WidgetTester tester,
  ) async {
    MockAppState.bag.value = [];
    final phoneSpeaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');
    await tester.pumpWidget(
      MaterialApp(home: PersonalizationScreen(product: phoneSpeaker)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'x' * 50);
    await tester.pumpAndSettle();

    expect(find.text('20/20'), findsOneWidget);
  });

  testWidgets('empty bag cannot start checkout', (tester) async {
    MockAppState.bag.value = [];
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Checkout'),
        matching: find.byType(FilledButton),
      ),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('empty bag checkout shows no charge', (tester) async {
    MockAppState.bag.value = [];
    await tester.pumpWidget(
      MaterialApp(home: CheckoutScreen(onPlaceOrder: () async => CheckoutOrderResult.success())),
    );
    await tester.pumpAndSettle();

    expect(find.text('₱80'), findsNothing);
    expect(find.text('Place order · ₱0'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Place order · ₱0'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Profile shows a clean dynamic empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('No email on file'), findsOneWidget);
    expect(
      find.text('No saved address yet. Add one to speed up checkout.'),
      findsOneWidget,
    );
    expect(find.text('my@email.com'), findsNothing);
    expect(find.text('Maya Santos'), findsNothing);
  });

  testWidgets('Profile address action opens Saved addresses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();

    // No Firebase in widget tests, so the screen shows its signed-out state
    // instead of inventing a sample address.
    expect(find.text('Sign in to save an address'), findsOneWidget);
    expect(find.text('24 Bamboo Lane'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();

    expect(find.text('No email on file'), findsOneWidget);
  });

  testWidgets('checkout auth gate offers sign-in, Google and guest options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(
          title: 'Sign in to check out',
          allowContinueAsGuest: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to check out'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Continue browsing as guest'), findsOneWidget);

    // Google is intentionally not connected in this prototype, and the
    // button says so instead of pretending to sign the customer in.
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Google Sign-In is not connected yet'), findsOneWidget);
  });

  testWidgets('auth gate can switch to account creation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(
          title: 'Sign in to check out',
          allowContinueAsGuest: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The gate scrolls on short screens; bring the footer action into view.
    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Continue browsing as guest'), findsOneWidget);
  });

  testWidgets('guest can leave the checkout auth gate', (
    WidgetTester tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const AuthScreen(
                        title: 'Sign in to check out',
                        allowContinueAsGuest: true,
                      ),
                    ),
                  );
                },
                child: const Text('Open auth'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open auth'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to check out'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue browsing as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue browsing as guest'));
    await tester.pumpAndSettle();

    // The gate closes with "guest" and the bag is untouched by auth.
    expect(result, isFalse);
    expect(find.text('Open auth'), findsOneWidget);
    expect(MockAppState.bag.value, isNotEmpty);
  });

  testWidgets('guest Profile prompt asks the customer to sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GuestAccountScreen(
          onSignIn: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Sign in to view your profile and order history'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('bag icon on Home opens the cart on the root stack', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Your bag'), findsOneWidget);

    // Back must return to Home, not switch to the Shop tab.
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();

    expect(find.text('A little nature.\nA lot of character.'), findsOneWidget);
  });

  testWidgets('root cart Checkout opens inside the pushed flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Your bag'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery \u2192 Payment \u2192 Review'), findsOneWidget);
  });

  testWidgets('Home story banner opens the craft story and its CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Discover our craft'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover our craft'));
    await tester.pumpAndSettle();

    expect(find.text('OUR CRAFT & ARTISANS'), findsOneWidget);
    expect(find.text('From grove to home'), findsOneWidget);
    expect(find.text('Explore Collection'), findsOneWidget);

    await tester.tap(find.text('Explore Collection'));
    await tester.pumpAndSettle();

    expect(find.text('The bamboo collection'), findsOneWidget);
  });

  testWidgets('bag blocks checkout when combined quantity exceeds stock', (
    WidgetTester tester,
  ) async {
    MockAppState.bag.value = [
      BagLine('phone-speaker', variant: 'Natural', quantity: 5),
      BagLine('phone-speaker', variant: 'Engraved', quantity: 5)
        ..engravingText = 'Ava',
    ];

    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
    await tester.pumpAndSettle();

    expect(
      find.text('Reduce the highlighted items to continue to checkout.'),
      findsOneWidget,
    );
    final checkout = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Checkout'),
    );
    expect(checkout.onPressed, isNull);
  });

  testWidgets('out-of-stock product disables Add to bag', (
    WidgetTester tester,
  ) async {
    final speaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');
    CatalogStore.instance.products.value = [
      for (final product in sampleProducts)
        product.id == speaker.id
            ? product.copyWith(stockLeft: 0)
            : product,
    ];

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailsScreen(product: speaker)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Out of stock'), findsWidgets);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Out of stock'),
    );
    expect(button.onPressed, isNull);
  });

  test('stock deduction aggregates engraved and natural bag lines', () async {
    final lines = [
      BagLine('phone-speaker', variant: 'Natural', quantity: 5),
      BagLine('phone-speaker', variant: 'Engraved', quantity: 5)
        ..engravingText = 'Ava',
    ];

    final result = await StockService.instance.deductForOrder(lines);

    expect(result.isSuccess, isFalse);
    expect(result.conflicts.single.productId, 'phone-speaker');
    expect(result.conflicts.single.available, 8);
    expect(
      CatalogStore.instance.products.value
          .firstWhere((product) => product.id == 'phone-speaker')
          .stockLeft,
      8,
    );
  });

  test('cancelling a pending order restores product stock', () async {
    final lines = [BagLine('phone-speaker', variant: 'Natural', quantity: 2)];
    final deduction = await StockService.instance.deductForOrder(lines);
    expect(deduction.isSuccess, isTrue);
    expect(
      CatalogStore.instance.products.value
          .firstWhere((product) => product.id == 'phone-speaker')
          .stockLeft,
      6,
    );

    final order = MockAppState.placeOrder(
      items: lines,
      subtotal: 900,
      shippingFee: 80,
      total: 980,
      paymentMethod: PaymentMethod.gcash.label,
    );

    final result = await OrderService.instance.cancelOrder(order);

    expect(result.isSuccess, isTrue);
    expect(order.status, OrderStatus.cancelled);
    expect(MockAppState.orders.value.first.status, OrderStatus.cancelled);
    expect(
      CatalogStore.instance.products.value
          .firstWhere((product) => product.id == 'phone-speaker')
          .stockLeft,
      8,
    );
  });

  test('non-pending orders cannot be cancelled', () async {
    final order = MockAppState.placeOrder(
      items: [BagLine('phone-speaker', variant: 'Natural', quantity: 2)],
      subtotal: 900,
      shippingFee: 80,
      total: 980,
      paymentMethod: PaymentMethod.gcash.label,
    )..status = OrderStatus.approved;

    final result = await OrderService.instance.cancelOrder(order);

    expect(result.isSuccess, isFalse);
    expect(order.status, OrderStatus.approved);
    expect(
      CatalogStore.instance.products.value
          .firstWhere((product) => product.id == 'phone-speaker')
          .stockLeft,
      8,
    );
  });

  testWidgets('product details shows the empty reviews state', (
    WidgetTester tester,
  ) async {
    final speaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailsScreen(product: speaker)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reviews'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('No reviews yet'), findsWidgets);
    expect(find.text('Write a review'), findsOneWidget);
  });

  testWidgets('product card shows the average rating badge', (
    WidgetTester tester,
  ) async {
    final speaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');
    final now = DateTime.now();
    ReviewService.instance.localReviews.value = [
      ProductReview(
        id: 'a',
        productId: speaker.id,
        userId: 'a',
        userName: 'Ana',
        rating: 5,
        text: 'Lovely.',
        createdAt: now,
      ),
      ProductReview(
        id: 'b',
        productId: speaker.id,
        userId: 'b',
        userName: 'Ben',
        rating: 4,
        text: 'Great.',
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: ProductCard(product: speaker, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);
  });

  testWidgets('product cards fit narrow grid cells without overflowing', (
    WidgetTester tester,
  ) async {
    final speaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');

    // Small-phone grid cell (~320px viewport, two columns) that previously
    // overflowed the card column by a few pixels.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 136,
              height: 187.6,
              child: ProductCard(product: speaker, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 136,
              height: 180,
              child: CatalogProductCard(
                product: speaker,
                onTap: () {},
                isWishlisted: false,
                onWishlistToggle: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('verified customer can submit a review', (
    WidgetTester tester,
  ) async {
    final speaker =
        sampleProducts.firstWhere((product) => product.id == 'phone-speaker');
    MockAppState.placeOrder(
      items: [BagLine('phone-speaker', variant: 'Natural')],
      subtotal: 450,
      shippingFee: 80,
      total: 530,
      paymentMethod: PaymentMethod.gcash.label,
    ).status = OrderStatus.completed;

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailsScreen(product: speaker)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Write a review'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();

    expect(find.text('Write a review'), findsWidgets);
    await tester.tap(find.byTooltip('5 stars'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Beautiful finish and fast delivery.',
    );
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(ReviewService.instance.localReviews.value, hasLength(1));
    expect(
      ReviewService.instance.localReviews.value.single.rating,
      5,
    );
    expect(
      find.text('Beautiful finish and fast delivery.'),
      findsOneWidget,
    );
  });

  testWidgets('completed order offers Rate Item and marks it reviewed', (
    WidgetTester tester,
  ) async {
    final order = MockAppState.placeOrder(
      items: [BagLine('phone-speaker', variant: 'Natural')],
      subtotal: 450,
      shippingFee: 80,
      total: 530,
      paymentMethod: PaymentMethod.gcash.label,
    )..status = OrderStatus.completed;

    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailsScreen(
          order: order,
          onBack: () {},
          onTrack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Rate Item'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Rate Item'), findsOneWidget);

    await tester.tap(find.text('Rate Item'));
    await tester.pumpAndSettle();

    expect(find.text('Write a review'), findsWidgets);
    await tester.tap(find.byTooltip('5 stars'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Beautiful finish and fast delivery.',
    );
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(ReviewService.instance.localReviews.value, hasLength(1));
    expect(find.text('Reviewed'), findsOneWidget);
    expect(find.text('Rate Item'), findsNothing);
  });

  testWidgets('notifications show order updates and can be marked read', (
    WidgetTester tester,
  ) async {
    MockAppState.placeOrder(
      items: [BagLine('phone-speaker', variant: 'Natural')],
      subtotal: 450,
      shippingFee: 80,
      total: 530,
      paymentMethod: PaymentMethod.gcash.label,
    ).status = OrderStatus.approved;

    await tester.pumpWidget(
      const MaterialApp(home: NotificationsScreen(uid: 'local-user')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order approved'), findsOneWidget);
    expect(find.textContaining('was approved!'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(
      NotificationService.instance.localNotifications.value
          .every((item) => item.isRead),
      isTrue,
    );
    expect(find.text('All caught up'), findsOneWidget);
  });

  testWidgets('support chat sends a customer message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportChatScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chat with us'), findsOneWidget);
    expect(find.text('Start a conversation'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Do you engrave names?',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Do you engrave names?'), findsOneWidget);
    expect(ChatService.instance.localMessages.value, hasLength(1));
    expect(ChatService.instance.localMessages.value.single.isAdmin, isFalse);
  });

  testWidgets('notification bell asks a guest to sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text('Sign in for updates'), findsOneWidget);
  });

  testWidgets('Profile opens the support chat', (WidgetTester tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Chat with us'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat with us'));
    await tester.pumpAndSettle();

    expect(find.text('Start a conversation'), findsOneWidget);
  });
}
