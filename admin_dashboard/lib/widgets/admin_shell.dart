import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/features/auth/services/auth_service.dart';
import 'package:admin_dashboard/models/support_chat.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/notification_bell.dart';

/// Airy workspace shell used by every signed-in dashboard route. A persistent
/// white sidebar is shown on desktop-sized windows; narrower windows use a
/// drawer so the same navigation stays usable on a tablet.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final AdminDatabase _database = AdminDatabase();
  late final Stream<List<SupportThread>> _threadsStream = _database
      .watchSupportThreads();

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final user = AuthService.instance.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 960;
        if (desktop) {
          return Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AdminColors.background, AdminColors.backgroundAlt],
                ),
              ),
              child: Column(
                children: [
                  const _AdminTopBar(),
                  Expanded(
                    child: Row(
                      children: [
                        _Sidebar(
                          width: 252,
                          path: path,
                          email: user?.email ?? 'Signed in',
                          threadsStream: _threadsStream,
                        ),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AdminColors.background,
          appBar: AppBar(
            title: Text(_titleFor(path)),
            actions: [
              const NotificationBell(),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    user?.email ?? 'Signed in',
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: AdminColors.surface,
            child: _Sidebar(
              path: path,
              email: user?.email ?? 'Signed in',
              closeDrawer: true,
              threadsStream: _threadsStream,
            ),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AdminColors.background, AdminColors.backgroundAlt],
              ),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }

  static String _titleFor(String path) {
    if (path.startsWith('/products')) return 'Products';
    if (path.startsWith('/reviews')) return 'Reviews';
    if (path.startsWith('/orders')) return 'Orders';
    if (path.startsWith('/messages')) return 'Messages';
    return 'Dashboard';
  }
}

/// Slim top header bar shown above the sidebar on desktop-sized windows.
///
/// Hosts the admin notification bell so alerts are reachable from every page.
class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AdminColors.sageDeep,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'LUNTI ADMIN STUDIO',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              color: AdminColors.muted,
            ),
          ),
          const Spacer(),
          const NotificationBell(),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.path,
    required this.email,
    required this.threadsStream,
    this.width,
    this.closeDrawer = false,
  });

  final double? width;
  final String path;
  final String email;
  final Stream<List<SupportThread>> threadsStream;
  final bool closeDrawer;

  void _go(BuildContext context, String route) {
    if (closeDrawer) Navigator.of(context).pop();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border(
          right: BorderSide(
            color: width == null ? Colors.transparent : AdminColors.border,
          ),
        ),
        boxShadow: width == null
            ? null
            : const [
                BoxShadow(
                  color: AdminColors.shadow,
                  blurRadius: 24,
                  offset: Offset(6, 0),
                ),
              ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AdminColors.mint, AdminColors.sage],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AdminColors.shadowStrong,
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: AdminColors.forest,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LUNTI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: AdminColors.ink,
                        ),
                      ),
                      Text(
                        'ADMIN STUDIO',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.6,
                          color: AdminColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: AdminColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: path == '/dashboard',
              onTap: () => _go(context, '/dashboard'),
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              selected: path.startsWith('/products'),
              onTap: () => _go(context, '/products'),
            ),
            _NavItem(
              icon: Icons.star_outline,
              label: 'Reviews',
              selected: path.startsWith('/reviews'),
              onTap: () => _go(context, '/reviews'),
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              selected: path.startsWith('/orders'),
              onTap: () => _go(context, '/orders'),
            ),
            StreamBuilder<List<SupportThread>>(
              stream: threadsStream,
              builder: (context, snapshot) {
                final unread = (snapshot.data ?? const <SupportThread>[])
                    .fold<int>(
                      0,
                      (total, thread) => total + thread.adminUnread,
                    );
                return _NavItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Messages',
                  selected: path.startsWith('/messages'),
                  badgeCount: unread,
                  onTap: () => _go(context, '/messages'),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SIGNED IN',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.text,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService.instance.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AdminColors.forest : AdminColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? AdminColors.sage : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? AdminColors.ink : AdminColors.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badgeCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AdminColors.forest : AdminColors.sage,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        color: selected ? AdminColors.cream : AdminColors.ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected) const SizedBox(width: 6),
                ],
                if (selected)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AdminColors.forest,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
