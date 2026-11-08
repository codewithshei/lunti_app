import 'dart:async';

import 'package:admin_dashboard/features/reviews/reviews_page.dart';
import 'package:admin_dashboard/models/admin_notification.dart';
import 'package:admin_dashboard/models/review.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Broadcast stream that replays the latest value to late subscribers,
/// mirroring how Firestore emits current data when a listener attaches.
class _ReplayStream<T> {
  _ReplayStream() : _controller = StreamController<T>.broadcast();

  final StreamController<T> _controller;
  T? _last;
  bool _hasValue = false;

  Stream<T> get stream => Stream<T>.multi((controller) {
        if (_hasValue) controller.add(_last as T);
        final subscription = _controller.stream.listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = () => subscription.cancel();
      });

  void add(T value) {
    _last = value;
    _hasValue = true;
    _controller.add(value);
  }

  void close() => _controller.close();
}

/// In-memory stand-in so the widget tests never touch Firestore.
class _FakeDatabase extends AdminDatabase {
  _FakeDatabase(this.reviews, this.notifications);

  final _ReplayStream<List<AdminReview>> reviews;
  final _ReplayStream<List<AdminNotification>> notifications;

  final List<String> moderated = [];
  final List<String> deleted = [];
  final List<String> read = [];
  int markAllCalls = 0;

  @override
  Stream<List<AdminReview>> watchAllReviews() => reviews.stream;

  @override
  Future<void> setReviewModerated(
    AdminReview review, {
    required bool moderated,
  }) async {
    this.moderated.add(review.id);
  }

  @override
  Future<void> deleteReview(AdminReview review) async {
    deleted.add(review.id);
  }

  @override
  Stream<List<AdminNotification>> watchAdminNotifications() =>
      notifications.stream;

  @override
  Future<void> markNotificationRead(String id) async {
    read.add(id);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    markAllCalls++;
  }
}

AdminReview _review({
  required String id,
  required String product,
  required int rating,
  required String text,
}) {
  return AdminReview(
    id: id,
    productId: 'p-$id',
    productName: product,
    userId: 'user-$id',
    userName: 'Maya Santos',
    rating: rating,
    text: text,
    createdAt: DateTime(2026, 11, 8, 9, 30),
  );
}

AdminNotification _notification({
  required String id,
  required String title,
  bool read = false,
  String? type,
  String? refId,
}) {
  return AdminNotification(
    id: id,
    title: title,
    body: 'Body for $title',
    timestamp: DateTime(2026, 11, 8, 9, 30),
    read: read,
    type: type,
    refId: refId,
  );
}

void main() {
  testWidgets('Reviews table renders every review and filters by stars', (
    tester,
  ) async {
    final reviews = _ReplayStream<List<AdminReview>>();
    final database = _FakeDatabase(
      reviews,
      _ReplayStream<List<AdminNotification>>(),
    );
    addTearDown(reviews.close);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ReviewsPage(database: database))),
    );

    reviews.add([
      _review(
        id: 'r1',
        product: 'Phone Speaker',
        rating: 5,
        text: 'Beautiful finish.',
      ),
      _review(id: 'r2', product: 'Coaster', rating: 2, text: 'Too small.'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Phone Speaker'), findsOneWidget);
    expect(find.text('Coaster'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('5 Stars'), findsOneWidget);

    await tester.tap(find.text('5 Stars'));
    await tester.pumpAndSettle();

    expect(find.text('Phone Speaker'), findsOneWidget);
    expect(find.text('Coaster'), findsNothing);
  });

  testWidgets('Moderate and delete call the database', (tester) async {
    final reviews = _ReplayStream<List<AdminReview>>();
    final database = _FakeDatabase(
      reviews,
      _ReplayStream<List<AdminNotification>>(),
    );
    addTearDown(reviews.close);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ReviewsPage(database: database))),
    );

    reviews.add([
      _review(
        id: 'r1',
        product: 'Phone Speaker',
        rating: 5,
        text: 'Beautiful finish.',
      ),
    ]);
    await tester.pumpAndSettle();

    // The actions column sits off-screen in the horizontal table scroll.
    await tester.ensureVisible(find.text('Moderate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moderate'));
    await tester.pumpAndSettle();
    expect(database.moderated, ['r1']);

    await tester.ensureVisible(find.byTooltip('Delete review'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete review'));
    await tester.pumpAndSettle();
    expect(find.text('Delete review?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(database.deleted, ['r1']);
  });

  testWidgets('Notification bell shows the unread badge and opens the panel', (
    tester,
  ) async {
    final notifications = _ReplayStream<List<AdminNotification>>();
    final database = _FakeDatabase(
      _ReplayStream<List<AdminReview>>(),
      notifications,
    );
    addTearDown(notifications.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [NotificationBell(database: database)]),
        ),
      ),
    );

    notifications.add([
      _notification(id: 'n1', title: 'New order'),
      _notification(id: 'n2', title: 'New message'),
      _notification(id: 'n3', title: 'Old alert', read: true),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();

    expect(find.text('Notifications · 2 unread'), findsOneWidget);
    expect(find.text('New order'), findsOneWidget);
    expect(find.text('Old alert'), findsOneWidget);
  });

  testWidgets('Tapping an order notification navigates to the order detail', (
    tester,
  ) async {
    final notifications = _ReplayStream<List<AdminNotification>>();
    final database = _FakeDatabase(
      _ReplayStream<List<AdminReview>>(),
      notifications,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            appBar: AppBar(actions: [NotificationBell(database: database)]),
            body: const Center(child: Text('Dashboard')),
          ),
        ),
        GoRoute(
          path: '/orders/detail/:id',
          builder: (context, state) => Scaffold(
            body: Center(child: Text('Order ${state.pathParameters['id']}')),
          ),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      notifications.close();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    notifications.add([
      _notification(
        id: 'n1',
        title: 'New order',
        type: 'order',
        refId: 'order-1',
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New order'));
    await tester.pumpAndSettle();

    expect(database.read, ['n1']);
    expect(find.text('Order order-1'), findsOneWidget);
  });

  testWidgets('Mark all read calls the database once', (tester) async {
    final notifications = _ReplayStream<List<AdminNotification>>();
    final database = _FakeDatabase(
      _ReplayStream<List<AdminReview>>(),
      notifications,
    );
    addTearDown(notifications.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [NotificationBell(database: database)]),
        ),
      ),
    );

    notifications.add([
      _notification(id: 'n1', title: 'New order'),
      _notification(id: 'n2', title: 'New message'),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(database.markAllCalls, 1);
  });
}
