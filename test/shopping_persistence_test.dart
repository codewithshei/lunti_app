import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lunti_app/data/mock_app_state.dart';
import 'package:lunti_app/services/shopping_state_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MockAppState.debugResetPersistence();
    MockAppState.reset();
  });

  tearDown(() {
    MockAppState.debugResetPersistence();
  });

  test('first launch starts with an empty bag and saves it', () async {
    // Production starts from the empty bag initializer; the seeded lines are
    // only a test/preview fixture.
    MockAppState.bag.value = [];
    await MockAppState.initializePersistence();

    expect(MockAppState.bag.value, isEmpty);

    final stored = await ShoppingStateStore.instance.load();
    expect(stored, isNotNull);
    expect(stored!.bag, isEmpty);
    // The wishlist still keeps the Figma sample items as inspiration.
    expect(stored.wishlist.keys, containsAll(['phone-speaker', 'coaster']));
  });

  test('a legacy seeded guest bag is cleared on launch', () async {
    // Older builds saved the demo bag with epoch 0, meaning the customer never
    // edited it. Launching the updated app should open with an empty bag while
    // keeping the saved wishlist.
    SharedPreferences.setMockInitialValues({
      'lunti.shopping.guest.bag.v1': jsonEncode([
        {
          'productId': 'phone-speaker',
          'variant': 'Natural',
          'quantity': 1,
          'engravingText': null,
        },
        {
          'productId': 'coaster',
          'variant': null,
          'quantity': 1,
          'engravingText': null,
        },
      ]),
      'lunti.shopping.guest.wishlist.v1': jsonEncode({
        'phone-speaker': 'Natural',
        'coaster': null,
      }),
      'lunti.shopping.guest.updatedAt.v1': 0,
    });
    MockAppState.debugResetPersistence();
    MockAppState.reset();
    expect(MockAppState.bag.value, hasLength(2));

    await MockAppState.initializePersistence();

    expect(MockAppState.bag.value, isEmpty);
    expect(
      MockAppState.wishlist.value.keys,
      containsAll(['phone-speaker', 'coaster']),
    );
  });

  test('removing every bag and wishlist item survives a restart', () async {
    await MockAppState.initializePersistence();

    MockAppState.removeLine(0);
    MockAppState.removeLine(0);
    MockAppState.removeFromWishlist('phone-speaker');
    MockAppState.removeFromWishlist('coaster');
    await MockAppState.persistNow();

    expect(MockAppState.bag.value, isEmpty);
    expect(MockAppState.wishlist.value, isEmpty);

    // Simulate an app/hot restart: the in-memory defaults come back first,
    // then the saved snapshot must win.
    MockAppState.debugResetPersistence();
    MockAppState.reset();
    expect(MockAppState.bag.value, hasLength(2));

    await MockAppState.initializePersistence();

    expect(MockAppState.bag.value, isEmpty);
    expect(MockAppState.wishlist.value, isEmpty);
  });

  test('added lines keep quantity and engraving after a restart', () async {
    await MockAppState.initializePersistence();

    MockAppState.addLine(
      'bamboo-tray',
      variant: 'Engraved',
      quantity: 2,
      engravingText: 'Maya',
    );
    MockAppState.toggleWishlist('bamboo-tray', variant: 'Engraved');
    await MockAppState.persistNow();

    MockAppState.debugResetPersistence();
    MockAppState.reset();
    await MockAppState.initializePersistence();

    final added = MockAppState.bag.value.firstWhere(
      (line) => line.productId == 'bamboo-tray',
    );
    expect(added.quantity, 2);
    expect(added.variant, 'Engraved');
    expect(added.engravingText, 'Maya');
    expect(MockAppState.wishlist.value['bamboo-tray'], 'Engraved');
  });

  test('a newer remote snapshot replaces and re-saves local state', () async {
    await MockAppState.initializePersistence();

    final remote = StoredShoppingState(
      bag: [
        {
          'productId': 'remote-item',
          'variant': 'Natural',
          'quantity': 3,
          'engravingText': null,
        },
      ],
      wishlist: {'remote-item': 'Natural'},
      updatedAt: DateTime.now().add(const Duration(minutes: 5)),
    );

    await MockAppState.applyStoredState(remote);

    expect(MockAppState.bag.value.single.productId, 'remote-item');
    expect(MockAppState.bag.value.single.quantity, 3);
    expect(MockAppState.wishlist.value, {'remote-item': 'Natural'});
    expect(
      MockAppState.stateUpdatedAt.millisecondsSinceEpoch,
      remote.updatedAt.millisecondsSinceEpoch,
    );

    final stored = await ShoppingStateStore.instance.load();
    expect(stored!.bag.single['productId'], 'remote-item');
    expect(
      stored.updatedAt.millisecondsSinceEpoch,
      remote.updatedAt.millisecondsSinceEpoch,
    );
  });

  test(
    'corrupt local data falls back to an empty snapshot, not defaults',
    () async {
      SharedPreferences.setMockInitialValues({
        'lunti.shopping.bag.v1': 'not-json',
        'lunti.shopping.wishlist.v1': 'not-json',
        'lunti.shopping.updatedAt.v1': 1,
      });
      MockAppState.debugResetPersistence();
      MockAppState.reset();

      await MockAppState.initializePersistence();

      expect(MockAppState.bag.value, isEmpty);
      expect(MockAppState.wishlist.value, isEmpty);
    },
  );

  test('a fresh account starts empty and never inherits demo items', () async {
    await MockAppState.initializePersistence(scope: 'user-a');

    expect(MockAppState.shoppingScope, 'user-a');
    expect(MockAppState.bag.value, isEmpty);
    expect(MockAppState.wishlist.value, isEmpty);
  });

  test('switching accounts clears the previous account items', () async {
    await MockAppState.initializePersistence(scope: 'user-a');
    MockAppState.addLine('phone-speaker', variant: 'Natural');
    MockAppState.toggleWishlist('coaster');
    await MockAppState.persistNow();

    await MockAppState.switchShoppingScope('user-b');

    expect(MockAppState.shoppingScope, 'user-b');
    expect(MockAppState.bag.value, isEmpty);
    expect(MockAppState.wishlist.value, isEmpty);

    // Account A keeps its own snapshot, and B has none to inherit.
    final a = await ShoppingStateStore.instance.load(scope: 'user-a');
    expect(a!.bag.single['productId'], 'phone-speaker');
    expect(a.wishlist, {'coaster': 'Natural'});
    expect(await ShoppingStateStore.instance.load(scope: 'user-b'), isNull);
  });

  test('switching back restores only that account snapshot', () async {
    await MockAppState.initializePersistence(scope: 'user-a');
    MockAppState.addLine('bamboo-tray', quantity: 2);
    await MockAppState.persistNow();

    await MockAppState.switchShoppingScope('user-b');
    MockAppState.addLine('coaster');
    await MockAppState.persistNow();

    await MockAppState.switchShoppingScope('user-a');

    expect(MockAppState.bag.value.map((line) => line.productId), [
      'bamboo-tray',
    ]);
    expect(MockAppState.bag.value.single.quantity, 2);
  });

  test('signing out clears the account items for the guest view', () async {
    await MockAppState.initializePersistence(scope: 'user-a');
    MockAppState.addLine('phone-speaker');
    MockAppState.toggleWishlist('phone-speaker');
    await MockAppState.persistNow();

    await MockAppState.clearForSignedOut();

    expect(MockAppState.shoppingScope, MockAppState.guestShoppingScope);
    expect(MockAppState.bag.value, isEmpty);
    expect(MockAppState.wishlist.value, isEmpty);

    // The empty guest snapshot is stored, so a relaunch does not reseed the
    // demo items or resurrect the signed-out account's cart.
    final guest = await ShoppingStateStore.instance.load();
    expect(guest, isNotNull);
    expect(guest!.bag, isEmpty);
    expect(guest.wishlist, isEmpty);

    MockAppState.debugResetPersistence();
    MockAppState.reset();
    await MockAppState.initializePersistence();

    expect(MockAppState.bag.value, isEmpty);
    expect(MockAppState.wishlist.value, isEmpty);
  });
}
