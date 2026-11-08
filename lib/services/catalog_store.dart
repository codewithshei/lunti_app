import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/sample_catalog.dart';

/// Firestore-backed catalog shared by every mobile screen.
///
/// The existing UI is built around [SampleProduct], so this store maps each
/// `products` document into that model. When Firestore is unavailable (for
/// example in widget tests) the bundled sample catalog remains the source of
/// truth, and product photos fall back to the matching local asset.
class CatalogStore {
  CatalogStore._();

  static final CatalogStore instance = CatalogStore._();

  /// Live catalog consumed by Home, Catalog, Search and Wishlist.
  final ValueNotifier<List<SampleProduct>> products =
      ValueNotifier<List<SampleProduct>>(sampleProducts);

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  static const String _fallbackImage = 'assets/images/hero_craft.jpg';

  final Map<String, SampleProduct> _sampleById = {
    for (final product in sampleProducts) product.id: product,
  };
  final Map<String, SampleProduct> _sampleByName = {
    for (final product in sampleProducts) product.name.toLowerCase(): product,
  };

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _started = false;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('products');

  /// Starts the real-time product stream. Safe to call more than once.
  void start() {
    if (_started || !_firebaseReady) return;
    _started = true;
    isLoading.value = true;

    _subscription = _collection.snapshots().listen(
      (snapshot) {
        _applySnapshot(snapshot);
        isLoading.value = false;
        error.value = null;
      },
      onError: (Object exception) {
        error.value = exception.toString();
        isLoading.value = false;
      },
    );
  }

  /// Adds every bundled sample product that is missing from Firestore.
  ///
  /// The requirement is to seed when the collection is empty; checking for
  /// missing IDs also repairs partially seeded projects and keeps the demo
  /// catalog complete if the admin dashboard seeded only a few items first.
  Future<void> ensureSeeded() async {
    if (!_firebaseReady) return;
    try {
      final snapshot = await _collection.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      final missing = sampleProducts
          .where((product) => !existingIds.contains(product.id))
          .toList();

      if (missing.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      final now = Timestamp.now();
      for (final product in missing) {
        batch.set(_collection.doc(product.id), _toFirestore(product, now));
      }
      await batch.commit();
    } catch (exception) {
      error.value = exception.toString();
    }
  }

  Future<SampleProduct?> findById(String id) async {
    for (final product in products.value) {
      if (product.id == id) return product;
    }
    if (!_firebaseReady) return null;

    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc.id, doc.data() ?? const {});
    } catch (exception) {
      error.value = exception.toString();
      return null;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Restores the bundled sample catalog.
  ///
  /// Used by widget tests (which run without Firebase) so each test starts
  /// from the same stock counts, and as an offline fallback.
  void resetToBundledCatalog() {
    products.value = sampleProducts;
  }

  /// Re-reads the whole collection once.
  ///
  /// Checkout uses this after a stock conflict so the inline "available in
  /// stock" warnings reflect the stock another order just consumed, even if
  /// the live snapshot has not arrived yet.
  Future<void> refresh() async {
    if (!_firebaseReady) return;
    try {
      final snapshot = await _collection.get();
      _applySnapshot(snapshot);
      error.value = null;
    } catch (exception) {
      error.value = exception.toString();
    }
  }

  /// Subtracts locally sold quantities from the in-memory catalog.
  ///
  /// Firestore remains the source of truth: this only gives immediate feedback
  /// after a successful stock transaction (and powers the offline/test flow
  /// where no Firebase app exists). Counts never go below zero.
  void applyStockDelta(Map<String, int> soldQuantities) {
    if (soldQuantities.isEmpty) return;
    products.value = [
      for (final product in products.value)
        if (soldQuantities.containsKey(product.id))
          product.copyWith(
            stockLeft: _subtractFloorZero(
              product.stockLeft,
              soldQuantities[product.id]!,
            ),
          )
        else
          product,
    ];
  }

  static int _subtractFloorZero(int stock, int sold) {
    final remaining = stock - sold;
    return remaining < 0 ? 0 : remaining;
  }

  /// Adds cancelled-order quantities back to the in-memory catalog.
  ///
  /// Firestore is incremented in the cancellation transaction; this keeps the
  /// UI honest immediately and powers the offline/test fallback.
  void restoreStock(Map<String, int> restoredQuantities) {
    if (restoredQuantities.isEmpty) return;
    products.value = [
      for (final product in products.value)
        if (restoredQuantities.containsKey(product.id))
          product.copyWith(
            stockLeft: product.stockLeft + restoredQuantities[product.id]!,
          )
        else
          product,
    ];
  }

  void _applySnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.docs.isEmpty) {
      products.value = sampleProducts;
      return;
    }

    final mapped = snapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    products.value = mapped;
  }

  Map<String, dynamic> _toFirestore(SampleProduct product, Timestamp now) {
    final engravingPrice = product.variantPricePeso == null
        ? 0
        : product.variantPricePeso! - product.pricePeso;

    return {
      'name': product.name,
      'description': product.description,
      'type': 'product',
      'category': product.categoryId,
      'price': product.pricePeso,
      'imagePath': product.image,
      'stock': product.stockLeft,
      'engravingPrice': engravingPrice,
      'availableEngravings': product.variantLabel == null
          ? <String>[]
          : <String>['Natural', product.variantLabel!],
      'note': product.note,
      'eyebrow': product.eyebrow,
      'material': product.material,
      'origin': product.origin,
      'care': product.care,
      'gallery': product.galleryImages,
      'createdAt': now,
      'updatedAt': now,
    };
  }

  SampleProduct _fromFirestore(String id, Map<String, dynamic> data) {
    final name = _string(data['name']) ?? 'LUNTI piece';
    final sample = _sampleById[id] ?? _sampleByName[name.toLowerCase()];
    final price = _int(data['price']) ?? sample?.pricePeso ?? 0;
    final engravingPrice = _int(data['engravingPrice']) ?? 0;
    final availableEngravings = _stringList(data['availableEngravings']);
    final supportsEngraving = availableEngravings
            .any((value) => value.toLowerCase() == 'engraved') ||
        engravingPrice > 0 ||
        sample?.variantLabel != null;

    final imagePath = _string(data['imagePath'])?.trim();
    final image = (imagePath != null && imagePath.isNotEmpty)
        ? imagePath
        : (sample?.image ?? _fallbackImage);
    final gallery = _stringList(data['gallery']);

    final variantPrice = supportsEngraving
        ? (sample?.variantPricePeso ??
            price + (engravingPrice > 0 ? engravingPrice : 100))
        : null;

    return SampleProduct(
      id: id,
      name: name,
      pricePeso: price,
      note: _string(data['note']) ??
          sample?.note ??
          (supportsEngraving ? 'Engraving available' : 'Bamboo craft'),
      image: image,
      categoryId: _string(data['category']) ?? sample?.categoryId ?? 'customized',
      eyebrow: _string(data['eyebrow']) ?? sample?.eyebrow ?? 'Bamboo everyday',
      description: _string(data['description']) ??
          sample?.description ??
          'A handcrafted LUNTI bamboo piece.',
      stockLeft: _int(data['stock']) ?? sample?.stockLeft ?? 0,
      material: _string(data['material']) ?? sample?.material ?? 'Bamboo',
      origin: _string(data['origin']) ??
          sample?.origin ??
          'Cardona, Rizal, Philippines',
      care: _string(data['care']) ?? sample?.care ?? 'Wipe gently; keep dry.',
      gallery: gallery.isEmpty ? <String>[image] : gallery,
      variantLabel: supportsEngraving ? 'Engraved' : null,
      variantPricePeso: variantPrice,
    );
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((entry) => '$entry'.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}
