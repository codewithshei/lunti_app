import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/models/admin_notification.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

/// Notification bell for the admin header.
///
/// Shows a live unread counter and opens a popover panel listing the real-time
/// alerts from `admin_notifications`. Tapping an alert marks it read and
/// navigates to the related order or message page.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.database});

  /// Optional override used by widget tests.
  final AdminDatabase? database;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final AdminDatabase _database = widget.database ?? AdminDatabase();
  final GlobalKey _bellKey = GlobalKey();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  void _togglePanel() {
    if (!mounted) return;
    if (_entry != null) {
      _removeEntry();
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final box = _bellKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    final narrow = screenWidth < 420;

    final bellLeft = box?.localToGlobal(Offset.zero).dx ?? 0;
    final top = box == null
        ? 72.0
        : box.localToGlobal(Offset.zero).dy + box.size.height + 8;
    final right = box == null || narrow
        ? 8.0
        : screenWidth - (bellLeft + box.size.width);
    final width = narrow ? screenWidth - 16 : 360.0;

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier: tapping anywhere outside closes the panel.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeEntry,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: top,
            right: right,
            width: width,
            child: _NotificationPanel(
              onClose: _removeEntry,
              database: _database,
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminNotification>>(
      stream: _database.watchAdminNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <AdminNotification>[];
        final unread = notifications.where((item) => !item.read).length;
        return IconButton(
          key: _bellKey,
          tooltip: 'Admin notifications',
          onPressed: _togglePanel,
          icon: _BellIcon(unread: unread),
        );
      },
    );
  }
}

/// Popover panel with the live notification list and category filters.
class _NotificationPanel extends StatefulWidget {
  const _NotificationPanel({required this.onClose, required this.database});

  final VoidCallback onClose;
  final AdminDatabase database;

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  /// Stored category label to filter by; `null` means "All".
  String? _categoryFilter;
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminNotification>>(
      key: ValueKey<int>(_refreshKey),
      stream: widget.database.watchAdminNotifications(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <AdminNotification>[];
        final unread = all.where((item) => !item.read).length;
        final notifications = _categoryFilter == null
            ? all
            : all.where((item) => item.category == _categoryFilter).toList();

        return Material(
          color: AdminColors.surface,
          elevation: 12,
          shadowColor: AdminColors.shadowStrong,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.border),
            ),
            constraints: const BoxConstraints(maxHeight: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 6, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          unread > 0
                              ? 'Notifications · $unread unread'
                              : 'Notifications',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        TextButton(
                          onPressed: () =>
                              widget.database.markAllNotificationsRead(),
                          child: const Text('Mark all read'),
                        ),
                      IconButton(
                        tooltip: 'Close notifications',
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildCategoryFilters(),
                const Divider(height: 1),
                if (snapshot.hasError)
                  _buildErrorState(snapshot.error)
                else if (notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 34,
                          color: AdminColors.muted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _categoryFilter == null
                              ? 'All caught up'
                              : 'No ${_categoryFilter!.toLowerCase()} yet',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order and message alerts appear here in real time.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AdminColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationTile(
                          notification: notification,
                          onTap: () => _open(context, notification),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final (label, category) in AdminNotificationCategory.filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                label: label,
                selected: _categoryFilter == category,
                onTap: () => setState(() => _categoryFilter = category),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    final message = '$error'.contains('permission')
        ? 'You do not have permission to read notifications. Check that your '
              'admin account has access, then try again.'
        : 'Notifications could not be loaded. Check your connection and try '
              'again.';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load notifications',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _refreshKey++),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, AdminNotification notification) {
    if (!notification.read) {
      widget.database.markNotificationRead(notification.id);
    }
    widget.onClose();
    if (!notification.hasLink) return;

    final router = GoRouter.of(context);
    final type = notification.type;
    if (type == 'order' || type == 'order_cancelled') {
      router.go('/orders/detail/${notification.refId}');
    } else if (type == 'review') {
      router.go('/reviews');
    } else if (type == 'message') {
      router.go('/messages');
    }
  }
}

/// Category filter chip used in the notifications popover.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AdminColors.sage : AdminColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AdminColors.sage : AdminColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AdminColors.ink : AdminColors.text,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// One alert row: read indicator, title, body, timestamp and a deep link.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AdminNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: notification.read
                    ? Colors.transparent
                    : AdminColors.sageDeep,
                shape: BoxShape.circle,
                border: Border.all(
                  color: notification.read
                      ? AdminColors.borderStrong
                      : AdminColors.sageDeep,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.read
                          ? FontWeight.w600
                          : FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _categoryBadge(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDate(notification.timestamp),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AdminColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (notification.hasLink) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AdminColors.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryBadge() {
    final tag = notification.tag;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon, size: 10, color: AdminColors.muted),
          const SizedBox(width: 3),
          Text(
            tag.label,
            style: const TextStyle(fontSize: 9, color: AdminColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Bell icon with an unread counter badge.
class _BellIcon extends StatelessWidget {
  const _BellIcon({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          unread > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none,
          size: 21,
          color: unread > 0 ? AdminColors.forest : AdminColors.muted,
        ),
        if (unread > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: AdminColors.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AdminColors.surface, width: 1.5),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
