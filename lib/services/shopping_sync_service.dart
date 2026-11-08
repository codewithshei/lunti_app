import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/mock_app_state.dart';
import 'shopping_state_store.dart';

/// Best-effort Firestore backup for the bag and wishlist.
///
/// SharedPreferences stays the source of truth for the running app. This
/// service only reconciles when a customer signs in, comparing the
/// `updatedAt` timestamp on both copies:
///
/// - local newer -> push local (so a removal is not undone by an older copy)
/// - remote newer -> apply remote (so a fresh install restores the account)
/// - same time -> prefer remote, which keeps an empty remote list empty instead
///   of resurrecting demo items
///
/// Every write is best-effort: a failed network call never blocks the UI or
/// discards the local snapshot.
class ShoppingSyncService {
  ShoppingSyncService._();

  static final ShoppingSyncService instance = ShoppingSyncService._();

  static const _pushDelay = Duration(milliseconds: 600);

  bool _started = false;
  bool _applyingRemote = false;
  bool _switchingScope = false;
  String? _uid;
  Timer? _pushTimer;

  /// Starts listening for sign-in and local changes. Safe to call when Firebase
  /// is unavailable (widget tests, offline previews): it simply does nothing.
  void start() {
    if (_started || Firebase.apps.isEmpty) return;
    _started = true;
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    MockAppState.bag.addListener(_onLocalChanged);
    MockAppState.wishlist.addListener(_onLocalChanged);
  }

  /// Keeps the bag and wishlist bound to exactly one identity.
  ///
  /// Sign-out clears the previous account's items and returns to a clean guest
  /// session. Sign-in (including switching from another account or from guest)
  /// clears the in-memory state before loading anything, then reconciles only
  /// with the new uid's Firestore document. The previous identity's snapshot is
  /// never pushed to the new account.
  Future<void> _onAuthChanged(User? user) async {
    _pushTimer?.cancel();
    final newUid = user?.uid;

    if (newUid == null) {
      // Already a guest and nothing to drop.
      if (_uid == null) return;
      _uid = null;
      _switchingScope = true;
      try {
        await MockAppState.clearForSignedOut();
      } finally {
        _switchingScope = false;
      }
      return;
    }

    final identityChanged = newUid != _uid;
    _uid = newUid;

    if (identityChanged) {
      _switchingScope = true;
      try {
        await MockAppState.switchShoppingScope(newUid);
      } finally {
        _switchingScope = false;
      }
    }

    await _reconcile(newUid);
  }

  Future<void> _reconcile(String uid) async {
    StoredShoppingState? remote;
    try {
      remote = await _readRemote(uid);
    } catch (_) {
      // Offline or rules not deployed: keep using this account's local cache.
      return;
    }

    // The account changed while the remote read was in flight; never apply one
    // identity's snapshot to another.
    if (_uid != uid) return;

    final local = MockAppState.currentStoredState;

    if (remote == null || local.updatedAt.isAfter(remote.updatedAt)) {
      await _push(uid, local);
      return;
    }

    if (_uid != uid) return;
    _applyingRemote = true;
    try {
      await MockAppState.applyStoredState(remote);
    } finally {
      _applyingRemote = false;
    }
  }

  void _onLocalChanged() {
    if (_applyingRemote || _switchingScope) return;
    final uid = _uid;
    if (uid == null) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDelay, () {
      // The account may have changed during the debounce window.
      if (_uid != uid) return;
      unawaited(_push(uid, MockAppState.currentStoredState));
    });
  }

  Future<void> _push(String uid, StoredShoppingState state) async {
    try {
      await _users.doc(uid).set({
        'shopping': {
          'bag': state.bag,
          'wishlist': state.wishlist,
          'updatedAt': Timestamp.fromDate(state.updatedAt),
        },
        'shoppingUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Local persistence already holds the change; retry on the next edit.
    }
  }

  Future<StoredShoppingState?> _readRemote(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    final shopping = data?['shopping'];
    if (shopping is! Map) return null;

    final bagRaw = shopping['bag'];
    final wishlistRaw = shopping['wishlist'];
    if (bagRaw is! List && wishlistRaw is! Map) return null;

    return StoredShoppingState(
      bag: _bagFromList(bagRaw),
      wishlist: _wishlistFromMap(wishlistRaw),
      updatedAt: _dateTime(shopping['updatedAt']),
    );
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  static List<Map<String, dynamic>> _bagFromList(Object? raw) {
    if (raw is! List) return const [];
    return raw
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
  }

  static Map<String, String?> _wishlistFromMap(Object? raw) {
    if (raw is! Map) return <String, String?>{};
    return {
      for (final entry in raw.entries)
        if (entry.key is String)
          entry.key as String: entry.value is String
              ? entry.value as String
              : null,
    };
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
