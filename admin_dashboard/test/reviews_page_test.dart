import 'dart:async';

import 'package:admin_dashboard/features/reviews/reviews_page.dart';
import 'package:admin_dashboard/models/review.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in so the widget tests never touch Firestore.
class _FakeDatabase extends AdminDatabase {
  _FakeDatabase(this._controller);

  final StreamController<List<AdminReview>> _controller;

  @override
  Stream<List<AdminReview>> watchAllReviews() => _controller.stream;

  @override
  Future<void> setReviewModerated(
    AdminReview review, {
    required bool moderated,
  }) async {}

  @override
  Future<void> deleteReview(AdminReview review) async {}
}

void main() {
  testWidgets('Reviews page shows the empty state when there are no reviews', (
    tester,
  ) async {
    final controller = StreamController<List<AdminReview>>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReviewsPage(database: _FakeDatabase(controller))),
      ),
    );

    controller.add(const <AdminReview>[]);
    await tester.pumpAndSettle();

    expect(find.text('No reviews yet'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'Reviews page shows an actionable error card when the stream fails',
    (tester) async {
      final controller = StreamController<List<AdminReview>>.broadcast();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReviewsPage(database: _FakeDatabase(controller))),
        ),
      );

      controller.addError(
        Exception('failed to get documents as the query requires an index'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load reviews'), findsOneWidget);
      expect(find.textContaining('collection-group index'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('Reviews page stops spinning once data arrives', (tester) async {
    final controller = StreamController<List<AdminReview>>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReviewsPage(database: _FakeDatabase(controller))),
      ),
    );

    // While the stream is still waiting the spinner is shown.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.add(const <AdminReview>[]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
