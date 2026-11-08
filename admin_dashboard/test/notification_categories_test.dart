import 'dart:async';

import 'package:admin_dashboard/models/admin_notification.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in so the widget tests never touch Firestore.
class _FakeDatabase extends AdminDatabase {
  _FakeDatabase(this._controller);

  final StreamController<List<AdminNotification>> _controller;

  @override
  Stream<List<AdminNotification>> watchAdminNotifications() =>
      _controller.stream;

  @override
  Future<void> markNotificationRead(String id) async {}

  @override
  Future<void> markAllNotificationsRead() async {}
}

List<AdminNotification> _notifications() => <AdminNotification>[
      AdminNotification(
        id: 'n1',
        title: 'New Order Placed',
        body: 'Order #ORD-1 placed by Maya Santos',
        timestamp: DateTime(2026, 11, 8, 9, 30),
        read: false,
        category: 'New Order',
        type: 'order',
        refId: 'ORD-1',
      ),
      AdminNotification(
        id: 'n2',
        title: 'Order Cancelled',
        body: 'Order #ORD-2 was cancelled by buyer',
        timestamp: DateTime(2026, 11, 8, 9, 20),
        read: false,
        category: 'Cancellation',
        type: 'order_cancelled',
        refId: 'ORD-2',
      ),
      AdminNotification(
        id: 'n3',
        title: 'New Product Review',
        body: 'Maya Santos left a 5-star review on Bamboo Tumbler',
        timestamp: DateTime(2026, 11, 8, 9, 10),
        read: true,
        category: 'Review',
        type: 'review',
        refId: 'p1',
      ),
    ];

Widget _shell(AdminDatabase database) => MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: [NotificationBell(database: database)]),
      ),
    );

/// Pumps the shell and opens the popover. The panel subscribes to the stream
/// only once it is on screen, so tests feed data after calling this.
Future<void> _openPanel(
  WidgetTester tester,
  StreamController<List<AdminNotification>> controller,
) async {
  await tester.pumpWidget(_shell(_FakeDatabase(controller)));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(NotificationBell));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('popover shows a filter chip for every category', (tester) async {
    final controller = StreamController<List<AdminNotification>>.broadcast();
    addTearDown(controller.close);

    await _openPanel(tester, controller);
    controller.add(_notifications());
    await tester.pumpAndSettle();

    for (final chip in const [
      'All',
      'Orders',
      'Cancellations',
      'Reviews',
      'Messages',
    ]) {
      expect(find.text(chip), findsOneWidget);
    }
  });

  testWidgets('category chips filter the list', (tester) async {
    final controller = StreamController<List<AdminNotification>>.broadcast();
    addTearDown(controller.close);

    await _openPanel(tester, controller);
    controller.add(_notifications());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reviews'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();

    expect(find.text('New Product Review'), findsOneWidget);
    expect(find.text('New Order Placed'), findsNothing);
    expect(find.text('Order Cancelled'), findsNothing);
  });

  testWidgets('each notification shows a category badge', (tester) async {
    final controller = StreamController<List<AdminNotification>>.broadcast();
    addTearDown(controller.close);

    await _openPanel(tester, controller);
    controller.add(_notifications());
    await tester.pumpAndSettle();

    expect(find.text('New Order'), findsOneWidget);
    expect(find.text('Cancellation'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('permission errors show a friendly retry state', (tester) async {
    final controller = StreamController<List<AdminNotification>>.broadcast();
    addTearDown(controller.close);

    await _openPanel(tester, controller);
    controller.addError(Exception('permission-denied'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load notifications'), findsOneWidget);
    expect(find.textContaining('do not have permission'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
