import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/mock_app_state.dart';
import '../data/sample_catalog.dart';
import 'catalog_store.dart';

/// One product whose requested quantity is higher than the stock left.
class StockConflict {
  const StockConflict({
    required this.productId,
    required this.productName,
    required this.requested,
    required this.available,
  });

  final String productId;
  final String productName;
  final int requested;

  /// Stock found when the order was validated (never negative).
  final int available;

  /// Short inline warning for a bag / checkout line.
  ///
  /// The wording is shared by every screen so the message stays consistent.
  String get inlineMessage => available <= 0
      ? 'Out of stock'
      : 'Only $available items available in stock';

  /// Full sentence for the "not enough stock" alert.
  String get message => available <= 0
      ? '$productName is out of stock.'
      : '$productName: only $available items available in stock.';
}

/// Outcome of an attempt to reserve stock for an order.
class StockDeductionResult {
  const StockDeductionResult._({this.conflicts = const [], this.error});

  const StockDeductionResult.success() : this._();

  const StockDeductionResult.insufficient(this.conflicts) : error = null;

  const StockDeductionResult.failed(this.error) : conflicts = const [];

  final List<StockConflict> conflicts;
  final String? error;

  bool get isSuccess => conflicts.isEmpty && error == null;
}

/// Validates and deducts product stock for an order.
///
/// With Firebase available the deduction runs inside a Firestore transaction:
/// every product document is read, checked against the requested quantity and
/// only then incremented. Firestore retries the whole transaction when another
/// order changes one of those documents, so stock can never drop below zero.
///
/// Without Firebase (widget tests, offline preview) the same validation runs
/// against [CatalogStore] and the in-memory catalog is updated instead, keeping
/// the out-of-stock UI honest in the demo.
class StockService {
  StockService._();

  static final StockService instance = StockService._();

  bool get _firestoreReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  static int availableFor(SampleProduct product) =>
      product.stockLeft < 0 ? 0 : product.stockLeft;

  /// Aggregates requested quantities per product id.
  ///
  /// The same product can sit in the bag more than once (Natural plus an
  /// engraved line), so stock is validated against the combined quantity.
  static Map<String, int> requestedQuantities(List<BagLine> lines) {
    final requested = <String, int>{};
    for (final line in lines) {
      if (line.quantity < 1) continue;
      requested.update(
        line.productId,
        (value) => value + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }
    return requested;
  }

  /// Quantity of [productId] currently in the bag.
  ///
  /// Pass [ignoreLineKey] when editing a line that will be replaced, so its old
  /// quantity is not counted twice.
  static int quantityInBag(String productId, {String? ignoreLineKey}) {
    var total = 0;
    for (final line in MockAppState.bag.value) {
      if (line.productId != productId) continue;
      if (ignoreLineKey != null && line.lineKey == ignoreLineKey) continue;
      total += line.quantity;
    }
    return total;
  }

  /// Reserves stock for every line in the order.
  ///
  /// Returns [StockDeductionResult.success] only after the stock was actually
  /// deducted. On insufficient stock the transaction writes nothing and the
  /// caller receives the conflicts to show in the UI.
  Future<StockDeductionResult> deductForOrder(List<BagLine> lines) async {
    final requested = requestedQuantities(lines);
    if (requested.isEmpty) return const StockDeductionResult.success();

    final localCatalog = {
      for (final product in CatalogStore.instance.products.value)
        product.id: product,
    };

    if (!_firestoreReady) {
      final conflicts = _localConflicts(requested, localCatalog);
      if (conflicts.isNotEmpty) {
        return StockDeductionResult.insufficient(conflicts);
      }
      CatalogStore.instance.applyStockDelta(requested);
      return const StockDeductionResult.success();
    }

    final conflicts = <StockConflict>[];
    try {
      await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
        // A retry re-runs this body, so discard any conflicts from the
        // previous attempt before reading the documents again.
        conflicts.clear();

        final snapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final productId in requested.keys) {
          snapshots[productId] = await transaction.get(_products.doc(productId));
        }

        for (final entry in requested.entries) {
          final snapshot = snapshots[entry.key]!;
          final data = snapshot.data();
          final name = _string(data?['name']) ??
              localCatalog[entry.key]?.name ??
              entry.key;
          final available = _int(data?['stock']) ?? 0;

          if (!snapshot.exists || available < entry.value) {
            conflicts.add(
              StockConflict(
                productId: entry.key,
                productName: name,
                requested: entry.value,
                available: snapshot.exists ? available : 0,
              ),
            );
          }
        }

        // Returning without write operations cancels the transaction, so no
        // stock is changed when any line is short.
        if (conflicts.isNotEmpty) return;

        final now = Timestamp.now();
        for (final entry in requested.entries) {
          transaction.update(_products.doc(entry.key), {
            'stock': FieldValue.increment(-entry.value),
            'updatedAt': now,
          });
        }
      });
    } on FirebaseException catch (exception) {
      return StockDeductionResult.failed(
        'Could not update stock (${exception.code}). Please try again.',
      );
    } catch (_) {
      return const StockDeductionResult.failed(
        'Could not update stock. Check your connection and try again.',
      );
    }

    if (conflicts.isNotEmpty) {
      return StockDeductionResult.insufficient(conflicts);
    }

    // Reflect the sale immediately; the live Firestore snapshot will confirm
    // the same values shortly after.
    CatalogStore.instance.applyStockDelta(requested);
    return const StockDeductionResult.success();
  }

  List<StockConflict> _localConflicts(
    Map<String, int> requested,
    Map<String, SampleProduct> catalog,
  ) {
    final conflicts = <StockConflict>[];
    for (final entry in requested.entries) {
      final product = catalog[entry.key];
      if (product == null) continue;
      final available = availableFor(product);
      if (available < entry.value) {
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
}
