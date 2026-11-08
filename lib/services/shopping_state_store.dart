import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A serializable copy of the bag and wishlist.
///
/// Kept independent of the UI models so this store has no dependency on the
/// app state, which avoids a circular import. `MockAppState` converts to and
/// from [BagLine] / [WishlistEntry].
class StoredShoppingState {
  const StoredShoppingState({
    required this.bag,
    required this.wishlist,
    required this.updatedAt,
  });

  /// One map per bag line: `productId`, `variant`, `quantity`, `engravingText`.
  final List<Map<String, dynamic>> bag;

  /// Product id -> saved style label (or null for a plain product).
  final Map<String, String?> wishlist;

  /// When this snapshot was last changed on the device or in Firestore.
  final DateTime updatedAt;
}

/// Device-local persistence for the shopping bag and wishlist.
///
/// Every snapshot is namespaced by **scope**: the Firebase uid of the
/// signed-in customer, or [guestScope] when signed out. This is what keeps one
/// account's cart and wishlist from appearing under another account (or under
/// the guest view) on the same device.
///
/// The first launch starts the guest bag empty (the wishlist keeps the Figma
/// sample items) and saves that snapshot once. After that the saved snapshot
/// wins, even when it is empty, so removing every item does not make defaults
/// reappear on the next launch or hot restart.
class ShoppingStateStore {
  ShoppingStateStore._();

  static final ShoppingStateStore instance = ShoppingStateStore._();

  /// Scope used while nobody is signed in.
  static const String guestScope = 'guest';

  static const _legacyBagKey = 'lunti.shopping.bag.v1';
  static const _legacyWishlistKey = 'lunti.shopping.wishlist.v1';
  static const _legacyUpdatedAtKey = 'lunti.shopping.updatedAt.v1';

  static String _bagKey(String scope) => 'lunti.shopping.$scope.bag.v1';
  static String _wishlistKey(String scope) =>
      'lunti.shopping.$scope.wishlist.v1';
  static String _updatedAtKey(String scope) =>
      'lunti.shopping.$scope.updatedAt.v1';

  /// Returns `null` only when this scope has never saved shopping state.
  ///
  /// The pre-isolation, unscoped snapshot is migrated into the guest scope
  /// once and then removed, so older installs do not silently lose their bag.
  Future<StoredShoppingState?> load({String scope = guestScope}) async {
    final prefs = await SharedPreferences.getInstance();
    var bagRaw = prefs.getString(_bagKey(scope));
    var wishlistRaw = prefs.getString(_wishlistKey(scope));
    var updatedAtRaw = prefs.getInt(_updatedAtKey(scope));

    if (scope == guestScope && bagRaw == null && wishlistRaw == null) {
      final legacyBag = prefs.getString(_legacyBagKey);
      final legacyWishlist = prefs.getString(_legacyWishlistKey);
      if (legacyBag != null || legacyWishlist != null) {
        bagRaw = legacyBag;
        wishlistRaw = legacyWishlist;
        updatedAtRaw = prefs.getInt(_legacyUpdatedAtKey);
        // Copy into the guest scope first, then drop the unscoped keys so the
        // migration runs at most once.
        await save(
          scope: scope,
          bag: _decodeBag(bagRaw),
          wishlist: _decodeWishlist(wishlistRaw),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtRaw ?? 0),
        );
        await prefs.remove(_legacyBagKey);
        await prefs.remove(_legacyWishlistKey);
        await prefs.remove(_legacyUpdatedAtKey);
      }
    }

    if (bagRaw == null && wishlistRaw == null) return null;

    return StoredShoppingState(
      bag: _decodeBag(bagRaw),
      wishlist: _decodeWishlist(wishlistRaw),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtRaw ?? 0),
    );
  }

  Future<void> save({
    required List<Map<String, dynamic>> bag,
    required Map<String, String?> wishlist,
    required DateTime updatedAt,
    String scope = guestScope,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bagKey(scope), jsonEncode(bag));
    await prefs.setString(_wishlistKey(scope), jsonEncode(wishlist));
    await prefs.setInt(_updatedAtKey(scope), updatedAt.millisecondsSinceEpoch);
  }

  /// Clears the saved snapshot for [scope]. Used by tests and by an explicit
  /// app reset; normal sign-in / sign-out flows never call this.
  Future<void> clear({String scope = guestScope}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bagKey(scope));
    await prefs.remove(_wishlistKey(scope));
    await prefs.remove(_updatedAtKey(scope));
    if (scope == guestScope) {
      await prefs.remove(_legacyBagKey);
      await prefs.remove(_legacyWishlistKey);
      await prefs.remove(_legacyUpdatedAtKey);
    }
  }

  static List<Map<String, dynamic>> _decodeBag(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => <String, dynamic>{
              'productId': '${item['productId'] ?? ''}',
              'variant': item['variant'] is String ? item['variant'] : null,
              'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
              'engravingText': item['engravingText'] is String
                  ? item['engravingText']
                  : null,
            },
          )
          .where((item) => (item['productId'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      // Corrupt local data should not crash the app or resurrect defaults.
      return const [];
    }
  }

  static Map<String, String?> _decodeWishlist(String? raw) {
    if (raw == null || raw.isEmpty) return <String, String?>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String?>{};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String)
            entry.key as String: entry.value is String
                ? entry.value as String
                : null,
      };
    } catch (_) {
      return <String, String?>{};
    }
  }
}
