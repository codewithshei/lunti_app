import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/shopping_state_store.dart';
import 'payment_method.dart';
import 'sample_catalog.dart';

/// Shared SAMPLE pricing rules for the cart and checkout screens:
/// only the product's actual engraved style ("Engraved") pays the variant
/// price; "Natural" and plain single-price items pay the base price.
class BagPricing {
  static int unitPrice(SampleProduct product, BagLine line) {
    if (line.variant != null &&
        product.variantLabel != null &&
        line.variant == product.variantLabel) {
      return product.variantPricePeso ?? product.pricePeso;
    }
    return product.pricePeso;
  }

  static String styleText(SampleProduct product, BagLine line) {
    return line.variant ??
        (product.variantLabel != null ? 'Natural' : 'Bamboo');
  }

  /// Flat standard-shipping fee shared by Bag, Checkout and Payment so
  /// totals can never disagree between screens.
  static const int shippingFeePeso = 80;
}

/// The key type used by [MockAppState.wishlist]: product id -> the saved
/// variant label (null = plain product, saved without a style choice).
typedef WishlistEntry = Map<String, String?>;

/// One line in the shopping bag: product + style choice + quantity.
class BagLine {
  BagLine(this.productId, {this.variant, this.quantity = 1});

  final String productId;

  /// Style choice label ('Natural' / 'Engraved'); null = plain product
  /// without a style choice (single-price items like plaques).
  final String? variant;

  int quantity;

  /// Personalization text for engraved lines. Kept with the line so Edit
  /// and Checkout show the exact personalization ("Maya" etc.).
  String? engravingText;

  String get lineKey =>
      '$productId|${variant ?? ''}|${engravingText?.trim() ?? ''}';

  String get variantLabel => variant == null ? 'Natural' : variant!;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variant': variant,
      'quantity': quantity,
      'engravingText': engravingText,
    };
  }

  factory BagLine.fromJson(Map<String, dynamic> json) {
    return BagLine(
      json['productId'] as String? ?? '',
      variant: json['variant'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    )..engravingText = json['engravingText'] as String?;
  }
}

/// Arguments for reopening an engraved bag line's personalization from the
/// bag's Edit action: prefills the text and replaces that line on Add.
class EngravingEditSeed {
  EngravingEditSeed(this.productId, this.engravingText, this.replaceLineKey);

  final String productId;
  final String? engravingText;

  /// Bag line key to remove before re-adding (keeps quantities honest).
  final String replaceLineKey;
}

/// Canonical order status used by both the mobile app and the admin
/// dashboard. Legacy values are mapped in [OrderStatusX.fromFirestore].
enum OrderStatus { pending, approved, packed, shipped, completed, cancelled }

extension OrderStatusX on OrderStatus {
  /// Readable label shared by the order history and tracking screens.
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Maps stored values (including older prototype values) onto the
  /// canonical statuses used by the dashboard.
  static OrderStatus fromFirestore(Object? value) {
    switch ('$value'.toLowerCase()) {
      case 'approved':
      case 'confirmed':
        return OrderStatus.approved;
      case 'packed':
        return OrderStatus.packed;
      case 'shipped':
      case 'in_transit':
      case 'in transit':
      case 'intransit':
      case 'out_for_delivery':
      case 'out for delivery':
        return OrderStatus.shipped;
      case 'completed':
      case 'delivered':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
      case 'returned':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  /// Whether the status is part of the happy-path tracking timeline.
  bool get isClosed => this == OrderStatus.cancelled;
}

/// One entry in an order's audit trail: which status it moved to, when, and
/// who triggered it. `OrderService` writes this to Firestore and reads it back
/// so the tracking timeline can show a real timestamp per step.
class OrderStatusHistoryEntry {
  const OrderStatusHistoryEntry({
    required this.status,
    required this.at,
    required this.by,
  });

  final OrderStatus status;
  final DateTime at;

  /// The uid of the customer or admin who made the change ('' when unknown).
  final String by;
}

/// A placed order stored in shared local state. Firestore documents are mapped
/// into this same model by `OrderService`, so every existing screen keeps its
/// presentational code.
class Order {
  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = '',
    required this.addressTitle,
    required this.addressLine1,
    required this.addressLine2,
    required this.phone,
    required this.createdAt,
    this.customerName = '',
    this.email = '',
    this.userId = '',
    this.status = OrderStatus.pending,
    this.statusHistory = const <OrderStatusHistoryEntry>[],
    this.stockRestored = false,
  });

  final String id;
  final List<BagLine> items;
  final int subtotal;
  final int shippingFee;
  final int total;
  final String paymentMethod;

  /// 'Paid (GCash)', 'Paid (Card)' or 'Unpaid (COD)' for new orders. Older
  /// prototype orders may have an empty value.
  final String paymentStatus;
  final String addressTitle;
  final String addressLine1;
  final String addressLine2;
  final String phone;
  final DateTime createdAt;
  final String customerName;
  final String email;
  final String userId;
  OrderStatus status;

  /// Audit trail of status changes, oldest first.
  ///
  /// Empty for legacy orders placed before the trail existed; the tracking
  /// screen then derives the reached steps from [status] alone.
  List<OrderStatusHistoryEntry> statusHistory;

  /// True once an admin cancellation has already returned this order's stock,
  /// so a later customer cancellation can never restore it twice.
  bool stockRestored;

  /// Whether the stored record already says paid.
  bool get hasPaidOnRecord =>
      paymentStatus.trim().toLowerCase().startsWith('paid');

  /// Whether the order has been paid.
  ///
  /// Cash on delivery settles on delivery, so a completed COD order counts as
  /// paid even when its stored status predates that rule.
  bool get isPaymentPaid => hasPaidOnRecord || status == OrderStatus.completed;

  /// Status shown in the payment badge.
  ///
  /// A completed order has been delivered, so cash on delivery has been
  /// collected — including orders stored before completion began writing the
  /// payment status, which would otherwise read 'Unpaid (COD)' forever. An
  /// empty stored status still falls back to the method default, matching what
  /// Checkout recorded.
  String get paymentStatusDisplay {
    if (status == OrderStatus.completed && !hasPaidOnRecord) {
      return PaymentMethodX.paidStatusFor(paymentMethod);
    }
    return paymentStatus.trim().isEmpty
        ? PaymentMethodX.parse(paymentMethod).paymentStatus
        : paymentStatus;
  }

  int get itemCount =>
      items.fold<int>(0, (runningTotal, line) => runningTotal + line.quantity);
}

/// Shared shopping state for the bag, wishlist, orders and payment method.
/// - The bag starts empty for every identity, including guests, so a fresh
///   launch never shows pre-loaded demo items. The wishlist keeps the Figma
///   sample items as browsing inspiration. Both persist to device storage via
///   [initializePersistence] so removals and additions survive app and hot
///   restarts. [bagCount] stays a live ValueListenable so the badge keeps
///   updating.
/// - A signed-in customer also gets a best-effort Firestore backup through
///   `ShoppingSyncService`, merged by timestamp so local removals are not
///   reverted by an older copy.
/// - The payment method starts on GCash like the handoff frames; the
///   Payment screen (frame 12) changes it.
class MockAppState {
  MockAppState._();

  /// Guest and signed-in sessions both start with an empty bag. Saved lines
  /// are restored by [initializePersistence] when the device has a snapshot.
  static final ValueNotifier<List<BagLine>> bag = ValueNotifier<List<BagLine>>(
    <BagLine>[],
  );

  static final ValueListenable<int> bagCount = _BagCountListenable._();

  static final ValueNotifier<WishlistEntry> wishlist =
      ValueNotifier<WishlistEntry>(<String, String?>{
        'phone-speaker': 'Natural',
        'coaster': null,
      });

  /// Product ids in the order the customer opened them, newest first.
  ///
  /// Session-only browsing context; unlike the bag and wishlist this does not
  /// need a Firestore backup. Seeded with sample pieces so the Home rail is
  /// visible in a fresh prototype session; [reset] clears it for widget tests.
  static final ValueNotifier<List<String>> recentlyViewed =
      ValueNotifier<List<String>>(const <String>[
        'phone-speaker',
        'carved-bowl',
        'capiz-lamp',
        'bamboo-clock',
      ]);

  static const int maxRecentlyViewed = 8;

  /// Records a product view, moving an existing entry back to the front and
  /// capping the rail at [maxRecentlyViewed].
  static void markViewed(String productId) {
    if (productId.isEmpty) return;
    final next = <String>[
      productId,
      ...recentlyViewed.value.where((id) => id != productId),
    ];
    if (next.length > maxRecentlyViewed) {
      next.removeRange(maxRecentlyViewed, next.length);
    }
    recentlyViewed.value = next;
  }

  /// Selected payment method. GCash and card are simulated; Cash on Delivery
  /// is collected by the rider. No credentials or wallet number are stored.
  static final ValueNotifier<PaymentMethod> paymentMethod =
      ValueNotifier<PaymentMethod>(PaymentMethod.gcash);

  /// Shared order history.
  static final ValueNotifier<List<Order>> orders = ValueNotifier<List<Order>>(
    [],
  );

  static bool _persistenceInitialized = false;
  static bool _suppressPersist = false;
  static DateTime _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Scope used while nobody is signed in.
  static const String guestShoppingScope = ShoppingStateStore.guestScope;

  /// Which identity the in-memory bag and wishlist belong to: the Firebase uid
  /// of the signed-in customer, or [guestShoppingScope] when signed out.
  static String _shoppingScope = guestShoppingScope;

  /// The identity that currently owns [bag] and [wishlist].
  static String get shoppingScope => _shoppingScope;

  /// When the bag/wishlist snapshot last changed. `epoch 0` means the device is
  /// still showing the seeded first-launch state, so an existing Firestore copy
  /// may restore over it.
  static DateTime get stateUpdatedAt => _stateUpdatedAt;

  /// Loads the saved bag and wishlist and starts saving every later change.
  ///
  /// [scope] is the signed-in uid, or [guestShoppingScope] for a guest. Call
  /// this once from `main()` before `runApp`. Widget tests never call it, so
  /// they stay in-memory and never touch platform storage.
  static Future<void> initializePersistence({String? scope}) async {
    if (_persistenceInitialized) return;
    _persistenceInitialized = true;
    if (scope != null && scope.isNotEmpty) _shoppingScope = scope;
    bag.addListener(_persistBagChange);
    wishlist.addListener(_persistWishlistChange);
    try {
      await restoreFromStorage();
    } catch (error) {
      // Never block launch: fall back to the seeded state and keep trying to
      // save later edits.
      debugPrint('Could not restore saved bag/wishlist: $error');
    }
  }

  /// Reads the saved snapshot for the active scope.
  ///
  /// A guest with no saved snapshot starts with an empty bag; the empty
  /// snapshot is saved once so later additions and removals are treated as
  /// real state. A signed-in account always starts from its own data (local
  /// cache or Firestore), never from another identity's snapshot.
  static Future<void> restoreFromStorage() async {
    final stored = await ShoppingStateStore.instance.load(
      scope: _shoppingScope,
    );
    if (stored == null) {
      _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);
      if (_shoppingScope == guestShoppingScope) {
        // First launch as a guest: save the empty bag once. Any later removal
        // or addition is then stored as a real snapshot.
        await persistNow();
      } else {
        // A signed-in account with no saved snapshot starts clean; it must
        // never inherit another identity's defaults.
        _clearShoppingStateInMemory();
      }
      return;
    }

    // Older builds seeded a guest bag with demo items and saved it with epoch
    // 0 (meaning "never edited by the customer"). Drop that bag once so
    // existing installs also open empty, while keeping their saved wishlist.
    if (_shoppingScope == guestShoppingScope &&
        stored.updatedAt.millisecondsSinceEpoch == 0) {
      final migratedAt = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      );
      _applyStored(
        StoredShoppingState(
          bag: const <Map<String, dynamic>>[],
          wishlist: stored.wishlist,
          updatedAt: migratedAt,
        ),
      );
      await persistNow();
      return;
    }

    _applyStored(stored);
  }

  /// Drops the in-memory bag and wishlist without writing to storage.
  static void _clearShoppingStateInMemory() {
    _suppressPersist = true;
    try {
      bag.value = [];
      wishlist.value = <String, String?>{};
      _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);
    } finally {
      _suppressPersist = false;
    }
  }

  /// Switches the active shopping identity (Firebase uid or guest).
  ///
  /// The in-memory bag and wishlist are cleared **synchronously** before any
  /// storage read, so the previous account's items can never be rendered under
  /// the new identity. Only [scope]'s own local snapshot is then restored; the
  /// Firestore reconciliation happens separately in `ShoppingSyncService`.
  static Future<void> switchShoppingScope(String scope) async {
    if (scope.isEmpty || scope == _shoppingScope) return;
    _shoppingScope = scope;

    _clearShoppingStateInMemory();

    final stored = await ShoppingStateStore.instance.load(scope: scope);
    // A second switch may have started while this one was reading storage.
    if (_shoppingScope != scope) return;
    if (stored != null) _applyStored(stored);
  }

  /// Returns to a clean guest session after sign-out.
  ///
  /// Drops the previous account's items from memory and stores an explicit
  /// empty guest snapshot, so a later relaunch does not resurrect the seeded
  /// demo items or the signed-out account's cart.
  static Future<void> clearForSignedOut() async {
    _shoppingScope = guestShoppingScope;

    _clearShoppingStateInMemory();

    // Drop the guest cache and any pre-isolation keys, then write an explicit
    // empty snapshot so a relaunch cannot reseed the demo items.
    try {
      await ShoppingStateStore.instance.clear(scope: guestShoppingScope);
    } catch (error) {
      debugPrint('Could not clear the guest bag/wishlist: $error');
    }

    _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch,
    );
    await persistNow();
  }

  /// The current bag/wishlist in the shape used by local storage and the
  /// Firestore backup.
  static StoredShoppingState get currentStoredState {
    return StoredShoppingState(
      bag: bag.value.map((line) => line.toJson()).toList(),
      wishlist: Map<String, String?>.of(wishlist.value),
      updatedAt: _stateUpdatedAt,
    );
  }

  /// Replaces the in-memory state with [stored] and saves it locally.
  ///
  /// Used by the signed-in sync when the Firestore copy is newer than this
  /// device's copy.
  static Future<void> applyStoredState(StoredShoppingState stored) async {
    _applyStored(stored);
    await persistNow();
  }

  /// Writes the current state immediately. Exposed for tests that need to
  /// simulate a restart without waiting for a listener callback.
  @visibleForTesting
  static Future<void> persistNow() async {
    try {
      await ShoppingStateStore.instance.save(
        bag: bag.value.map((line) => line.toJson()).toList(),
        wishlist: Map<String, String?>.of(wishlist.value),
        updatedAt: _stateUpdatedAt,
        scope: _shoppingScope,
      );
    } catch (error) {
      // The in-memory state is still valid; the next edit retries the save.
      debugPrint('Could not save bag/wishlist: $error');
    }
  }

  /// Detaches persistence so a test can re-initialize from a clean slate.
  @visibleForTesting
  static void debugResetPersistence() {
    bag.removeListener(_persistBagChange);
    wishlist.removeListener(_persistWishlistChange);
    _persistenceInitialized = false;
    _suppressPersist = false;
    _shoppingScope = guestShoppingScope;
    _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  static void _applyStored(StoredShoppingState stored) {
    _suppressPersist = true;
    try {
      // Store timestamps at millisecond precision so the in-memory value and
      // the value reloaded from SharedPreferences compare exactly.
      _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(
        stored.updatedAt.millisecondsSinceEpoch,
      );
      bag.value = stored.bag
          .map(BagLine.fromJson)
          .where((line) => line.productId.isNotEmpty)
          .toList();
      wishlist.value = Map<String, String?>.of(stored.wishlist);
    } finally {
      _suppressPersist = false;
    }
  }

  static void _persistBagChange() => _persistAfterChange();

  static void _persistWishlistChange() => _persistAfterChange();

  static void _persistAfterChange() {
    if (!_persistenceInitialized || _suppressPersist) return;
    _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch,
    );
    unawaited(persistNow());
  }

  static bool isWishlisted(String productId) =>
      wishlist.value.containsKey(productId);

  /// Restores the seeded sample bag and wishlist in memory for widget tests
  /// and design previews. This is a test fixture only: a production launch
  /// starts with an empty bag and restores saved state through
  /// [initializePersistence].
  static void reset() {
    _suppressPersist = true;
    try {
      bag.value = [
        BagLine('phone-speaker', variant: 'Natural'),
        BagLine('coaster'),
      ];
      wishlist.value = <String, String?>{
        'phone-speaker': 'Natural',
        'coaster': null,
      };
    } finally {
      _suppressPersist = false;
    }
    _stateUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);
    paymentMethod.value = PaymentMethod.gcash;
    orders.value = [];
    recentlyViewed.value = const <String>[];
  }

  /// Builds an order object without touching shared state.
  ///
  /// Checkout reserves stock and persists the order before the bag is cleared,
  /// so a failure never leaves the customer with neither bag nor order.
  static Order buildOrder({
    required List<BagLine> items,
    required int subtotal,
    required int shippingFee,
    required int total,
    required String paymentMethod,
    String? paymentStatus,
    String addressTitle = 'Home',
    String addressLine1 = '',
    String addressLine2 = '',
    String phone = '',
    String customerName = '',
    String email = '',
    String userId = '',
  }) {
    final resolvedStatus = (paymentStatus ?? '').trim();
    final createdAt = DateTime.now();
    return Order(
      id: 'LNT-${createdAt.millisecondsSinceEpoch}',
      items: items
          .map(
            (line) => BagLine(
              line.productId,
              variant: line.variant,
              quantity: line.quantity,
            )..engravingText = line.engravingText,
          )
          .toList(),
      subtotal: subtotal,
      shippingFee: shippingFee,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: resolvedStatus.isEmpty
          ? PaymentMethodX.parse(paymentMethod).paymentStatus
          : resolvedStatus,
      addressTitle: addressTitle,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      phone: phone,
      customerName: customerName,
      email: email,
      userId: userId,
      createdAt: createdAt,
      statusHistory: <OrderStatusHistoryEntry>[
        OrderStatusHistoryEntry(
          status: OrderStatus.pending,
          at: createdAt,
          by: userId,
        ),
      ],
    );
  }

  /// Registers a built order and clears the bag.
  static void commitOrder(Order order) {
    orders.value = [order, ...orders.value];
    // Clear bag after placing order (prototype behavior)
    bag.value = [];
  }

  /// Builds, registers and returns an order in one step.
  static Order placeOrder({
    required List<BagLine> items,
    required int subtotal,
    required int shippingFee,
    required int total,
    required String paymentMethod,
    String? paymentStatus,
    String addressTitle = 'Home',
    String addressLine1 = '',
    String addressLine2 = '',
    String phone = '',
    String customerName = '',
    String email = '',
    String userId = '',
  }) {
    final order = buildOrder(
      items: items,
      subtotal: subtotal,
      shippingFee: shippingFee,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      addressTitle: addressTitle,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      phone: phone,
      customerName: customerName,
      email: email,
      userId: userId,
    );
    commitOrder(order);
    return order;
  }

  /// Marks a locally stored order cancelled and notifies listeners.
  ///
  /// Firestore orders are updated by [OrderService.cancelOrder]; this keeps the
  /// same-session prototype list consistent (and is the offline fallback).
  static void markOrderCancelled(String orderId) {
    final current = orders.value;
    var changed = false;
    final next = <Order>[];
    for (final order in current) {
      if (order.id == orderId && order.status != OrderStatus.cancelled) {
        order.status = OrderStatus.cancelled;
        order.statusHistory = <OrderStatusHistoryEntry>[
          ...order.statusHistory,
          OrderStatusHistoryEntry(
            status: OrderStatus.cancelled,
            at: DateTime.now(),
            by: order.userId,
          ),
        ];
        changed = true;
      }
      next.add(order);
    }
    if (changed) orders.value = next;
  }

  static void toggleWishlist(String productId, {String? variant}) {
    if (wishlist.value.containsKey(productId)) {
      final next = Map<String, String?>.of(wishlist.value)..remove(productId);
      wishlist.value = next;
      return;
    }
    final next = Map<String, String?>.of(wishlist.value);
    next[productId] = variant ?? 'Natural';
    wishlist.value = next;
  }

  static void removeFromWishlist(String productId) {
    if (!wishlist.value.containsKey(productId)) return;
    final next = Map<String, String?>.of(wishlist.value)..remove(productId);
    wishlist.value = next;
  }

  static void restoreWishlist(String productId, String? variant) {
    final next = Map<String, String?>.of(wishlist.value);
    next[productId] = variant;
    wishlist.value = next;
  }

  /// Adds (or extends) a bag line for the given product + style. Pass
  /// [replaceLineKey] to drop that prior line first (bag Edit flow), and
  /// [engravingText] to attach personalization to the line.
  static void addLine(
    String? productId, {
    String? variant,
    int quantity = 1,
    String? engravingText,
    String? replaceLineKey,
  }) {
    if (productId == null || quantity < 1) return;
    final lines = List<BagLine>.of(bag.value);
    if (replaceLineKey != null) {
      lines.removeWhere((line) => line.lineKey == replaceLineKey);
    }
    final normalizedEngraving = engravingText?.trim();
    final candidate = BagLine(productId, variant: variant)
      ..engravingText = normalizedEngraving;
    for (final line in lines) {
      if (line.lineKey == candidate.lineKey) {
        line.quantity += quantity;
        bag.value = lines;
        return;
      }
    }
    lines.add(
      BagLine(productId, variant: variant, quantity: quantity)
        ..engravingText = normalizedEngraving,
    );
    bag.value = lines;
  }

  static void setLineQuantity(int index, int quantity) {
    final lines = List<BagLine>.of(bag.value);
    if (index < 0 || index >= lines.length) return;
    lines[index].quantity = quantity.clamp(1, 99);
    bag.value = lines;
  }

  static void removeLine(int index) {
    final lines = List<BagLine>.of(bag.value);
    if (index < 0 || index >= lines.length) return;
    lines.removeAt(index);
    bag.value = lines;
  }

  /// Undo helper: puts a removed bag line back (same style + quantity).
  static void restoreLine(BagLine line) {
    final lines = List<BagLine>.of(bag.value);
    for (final existing in lines) {
      if (existing.lineKey == line.lineKey) {
        existing.quantity += line.quantity;
        if (line.engravingText != null) {
          existing.engravingText = line.engravingText;
        }
        bag.value = lines;
        return;
      }
    }
    lines.add(
      BagLine(line.productId, variant: line.variant, quantity: line.quantity)
        ..engravingText = line.engravingText,
    );
    bag.value = lines;
  }
}

/// Derives the badge count from the bag lines so any bag mutation
/// updates BrandHeader reactively. SAMPLE only.
class _BagCountListenable extends ValueNotifier<int> {
  _BagCountListenable._() : super(0) {
    _recalc();
    MockAppState.bag.addListener(_onBagChanged);
  }

  void _onBagChanged() => _recalc();

  void _recalc() {
    value = MockAppState.bag.value.fold(0, (n, line) => n + line.quantity);
  }
}
