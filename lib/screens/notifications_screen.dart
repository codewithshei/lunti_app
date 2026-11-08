import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../utils/order_display.dart';
import '../widgets/brand_header.dart';
import '../widgets/lunti_skeleton.dart';

/// In-app notifications centre for order-status updates and announcements.
///
/// The list is a live `users/{uid}/notifications` stream, so an order approved
/// by the admin dashboard appears without pulling to refresh.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.startOrderSync(widget.uid);
    if (Firebase.apps.isNotEmpty) return;
    NotificationService.instance.syncLocalOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandHeader(
              onBack: () => Navigator.of(context).maybePop(),
              onBagPressed: null,
              showBadge: false,
            ),
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: NotificationService.instance.watch(widget.uid),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <AppNotification>[];
                  final unread =
                      items.where((item) => !item.isRead).length;

                  return ListView(
                    padding: const EdgeInsets.all(LuntiSpacing.gutter),
                    children: [
                      Text('Notifications', style: LuntiTextStyles.display),
                      const SizedBox(height: LuntiSpacing.xs),
                      Text(
                        'Order updates and news from LUNTI.',
                        style: LuntiTextStyles.body,
                      ),
                      const SizedBox(height: LuntiSpacing.md),
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          items.isEmpty)
                        const Column(
                          children: [
                            SkeletonListTile(),
                            SizedBox(height: LuntiSpacing.sm),
                            SkeletonListTile(),
                            SizedBox(height: LuntiSpacing.sm),
                            SkeletonListTile(),
                          ],
                        )
                      else if (items.isEmpty)
                        const _EmptyNotificationsCard()
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                unread == 0
                                    ? 'All caught up'
                                    : '$unread unread update'
                                        '${unread == 1 ? '' : 's'}',
                                style: LuntiTextStyles.cardTitle.copyWith(
                                  color: LuntiColors.secondary,
                                ),
                              ),
                            ),
                            if (unread > 0)
                              TextButton(
                                onPressed: () => NotificationService.instance
                                    .markAllRead(widget.uid),
                                child: const Text('Mark all read'),
                              ),
                          ],
                        ),
                        const SizedBox(height: LuntiSpacing.xs),
                        Container(
                          decoration: BoxDecoration(
                            color: LuntiColors.white,
                            borderRadius:
                                BorderRadius.circular(LuntiRadii.md),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    color: LuntiColors.beige,
                                    height: 1,
                                  ),
                                _NotificationTile(
                                  notification: items[i],
                                  onTap: () =>
                                      NotificationService.instance.markRead(
                                    widget.uid,
                                    items[i].id,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: LuntiSpacing.lg),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotificationsCard extends StatelessWidget {
  const _EmptyNotificationsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuntiSpacing.lg),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 40,
            color: LuntiColors.secondary,
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Text(
            'You\u2019re all caught up',
            style: LuntiTextStyles.sectionTitle.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Order updates and announcements will appear here.',
            style: LuntiTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LuntiRadii.md),
      child: Padding(
        padding: const EdgeInsets.all(LuntiSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: LuntiColors.sage,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(notification.status),
                size: 19,
                color: LuntiColors.forest,
              ),
            ),
            const SizedBox(width: LuntiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: LuntiTextStyles.cardTitle.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: LuntiColors.forest,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: LuntiTextStyles.body,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: LuntiTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.receipt_long_outlined;
    }
  }

  static String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatOrderDate(date);
  }
}
