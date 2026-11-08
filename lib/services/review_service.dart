import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/mock_app_state.dart';
import '../models/product_review.dart';
import 'admin_notification_service.dart';
import 'catalog_store.dart';

/// Whether the signed-in customer is allowed to review a product.
enum ReviewEligibility { notSignedIn, noDeliveredOrder, eligible }

/// Product reviews stored at `products/{productId}/reviews/{uid}`.
///
/// A review can only be submitted by a signed-in customer with a completed
/// (delivered) order containing that product. When Firebase is unavailable
/// (widget tests / offline preview) the same rules run against the local
/// prototype orders, and reviews stay in memory so the UI still works.
class ReviewService {
  ReviewService._() {
    localReviews.addListener(() {
      _localController.add(localReviews.value);
    });
  }

  static final ReviewService instance = ReviewService._();

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  /// In-memory reviews used when Firebase is not configured.
  final ValueNotifier<List<ProductReview>> localReviews =
      ValueNotifier<List<ProductReview>>(const []);

  final StreamController<List<ProductReview>> _localController =
      StreamController<List<ProductReview>>.broadcast();

  final Map<String, ValueNotifier<ReviewSummary>> _summaryCache =
      <String, ValueNotifier<ReviewSummary>>{};
  final Map<String, StreamSubscription<List<ProductReview>>> _summarySubs =
      <String, StreamSubscription<List<ProductReview>>>{};

  CollectionReference<Map<String, dynamic>> _reviews(String productId) {
    return FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews');
  }

  /// Reviews visible in the shop: moderated ones are hidden.
  static List<ProductReview> visible(List<ProductReview> reviews) =>
      reviews.where((review) => !review.moderated).toList();

  /// Live reviews for one product, newest first.
  Stream<List<ProductReview>> watchReviews(String productId) {
    if (isAvailable) {
      return _reviews(productId).snapshots().map((snapshot) {
        final reviews = visible(
          snapshot.docs
              .map((doc) => ProductReview.fromFirestore(
                    productId,
                    doc.id,
                    doc.data(),
                  ))
              .toList(),
        )
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      });
    }
    return _watchLocalReviews(productId);
  }

  Stream<List<ProductReview>> _watchLocalReviews(String productId) async* {
    List<ProductReview> filter() {
      final reviews = localReviews.value
          .where((review) => review.productId == productId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    }

    yield filter();
    yield* _localController.stream.map((_) => filter());
  }

  /// The uid used to identify the current reviewer, or `null` when signed out.
  ///
  /// Offline previews and widget tests use the local prototype identity, which
  /// matches the in-memory reviews written by [submitReview].
  String? get currentUserId {
    if (!isAvailable) return 'local-user';
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Emits whether the current customer has already reviewed [productId].
  ///
  /// Used by the order details "Rate Item" action so the button becomes a
  /// "Reviewed" badge as soon as the review is saved.
  Stream<bool> watchHasReviewed(String productId) {
    final uid = currentUserId;
    if (uid == null) return Stream<bool>.value(false);
    return watchReviews(productId).map(
      (reviews) => reviews.any(
        (review) => review.userId == uid || review.id == uid,
      ),
    );
  }

  /// Shared average/count notifier for a product card or title row.
  ValueNotifier<ReviewSummary> summaryFor(String productId) {
    final notifier = _summaryCache.putIfAbsent(
      productId,
      () => ValueNotifier<ReviewSummary>(const ReviewSummary()),
    );
    _ensureSummaryListener(productId);
    return notifier;
  }

  void _ensureSummaryListener(String productId) {
    if (_summarySubs.containsKey(productId)) return;
    _summarySubs[productId] = watchReviews(productId).listen(
      (reviews) {
        _summaryCache[productId]?.value = _summarize(reviews);
      },
      onError: (_) {
        // Keep the last known summary if the live query fails.
      },
    );
  }

  static ReviewSummary _summarize(List<ProductReview> reviews) {
    if (reviews.isEmpty) return const ReviewSummary();
    final total = reviews.fold<int>(0, (running, review) => running + review.rating);
    return ReviewSummary(
      average: total / reviews.length,
      count: reviews.length,
    );
  }

  /// Checks the signed-in customer's order history for a delivered order that
  /// contains [productId].
  Future<ReviewEligibility> eligibilityFor(String productId) async {
    if (!isAvailable) {
      final hasDelivered = MockAppState.orders.value.any(
        (order) =>
            order.status == OrderStatus.completed &&
            order.items.any((line) => line.productId == productId),
      );
      return hasDelivered
          ? ReviewEligibility.eligible
          : ReviewEligibility.notSignedIn;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return ReviewEligibility.notSignedIn;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (OrderStatusX.fromFirestore(data['status']) !=
            OrderStatus.completed) {
          continue;
        }
        final items = data['items'];
        if (items is List &&
            items.any((item) =>
                item is Map && '${item['productId']}'.trim() == productId)) {
          return ReviewEligibility.eligible;
        }
      }

      // An existing review can always be edited, even if the order query is
      // temporarily unavailable.
      final existing = await _reviews(productId).doc(user.uid).get();
      if (existing.exists) return ReviewEligibility.eligible;
      return ReviewEligibility.noDeliveredOrder;
    } catch (_) {
      return ReviewEligibility.noDeliveredOrder;
    }
  }

  /// Saves (or edits) the customer's review. Returns an error message on
  /// failure and `null` on success.
  Future<String?> submitReview({
    required String productId,
    required int rating,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (rating < 1 || rating > 5) {
      return 'Choose a rating from 1 to 5 stars.';
    }
    if (trimmed.isEmpty) {
      return 'Write a short review before submitting.';
    }
    if (trimmed.length > 500) {
      return 'Keep your review to 500 characters or fewer.';
    }

    final eligibility = await eligibilityFor(productId);
    if (eligibility == ReviewEligibility.notSignedIn) {
      return 'Sign in to write a review.';
    }
    if (eligibility == ReviewEligibility.noDeliveredOrder) {
      return 'You can review this product after a delivered order.';
    }

    if (!isAvailable) {
      final review = ProductReview(
        id: 'local-user',
        productId: productId,
        userId: 'local-user',
        userName: 'You',
        rating: rating,
        text: trimmed,
        createdAt: DateTime.now(),
      );
      final next = localReviews.value
          .where((item) =>
              !(item.productId == productId && item.id == review.id))
          .toList()
        ..add(review);
      localReviews.value = next;
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Sign in to write a review.';

    try {
      await _reviews(productId).doc(user.uid).set(
        ProductReview(
          id: user.uid,
          productId: productId,
          userId: user.uid,
          userName: _displayName(user),
          rating: rating,
          text: trimmed,
          createdAt: DateTime.now(),
        ).toFirestore(),
        // Merge so an admin's `moderated` flag survives the customer editing
        // their own review.
        SetOptions(merge: true),
      );
    } on FirebaseException catch (exception) {
      return 'Could not save your review (${exception.code}). '
          'Please try again.';
    } catch (_) {
      return 'Could not save your review. Check your connection and try again.';
    }

    // Best-effort: alert the admin dashboard about the new review.
    await AdminNotificationService.instance.notifyNewReview(
      customerName: _displayName(user),
      rating: rating,
      productName: _productName(productId),
      productId: productId,
    );

    return null;
  }

  /// Catalog name for the reviewed product, falling back to its id.
  String _productName(String productId) {
    for (final product in CatalogStore.instance.products.value) {
      if (product.id == productId) return product.name;
    }
    return productId;
  }

  static String _displayName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'LUNTI customer';
  }

  /// Clears in-memory reviews between widget tests.
  void resetLocal() {
    localReviews.value = const [];
    for (final notifier in _summaryCache.values) {
      notifier.value = const ReviewSummary();
    }
  }
}
