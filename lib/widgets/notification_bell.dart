import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/router.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_service.dart';
import 'brand_header.dart';

/// Bell action used in the Home and Catalog headers.
///
/// The unread count is a live Firestore stream for the signed-in customer.
/// Guests can tap the bell too; they are asked to sign in first.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return _BellButton(count: 0, onPressed: () => _open(context, null));
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return _BellButton(count: 0, onPressed: () => _open(context, null));
        }
        NotificationService.instance.startOrderSync(user.uid);
        return StreamBuilder<int>(
          stream: NotificationService.instance.watchUnreadCount(user.uid),
          builder: (context, unreadSnapshot) {
            return _BellButton(
              count: unreadSnapshot.data ?? 0,
              onPressed: () => _open(context, user.uid),
            );
          },
        );
      },
    );
  }

  Future<void> _open(BuildContext context, String? uid) async {
    if (uid == null) {
      await AppRouter.openSignIn(
        context,
        title: 'Sign in for updates',
        subtitle: 'See order updates and announcements from LUNTI.',
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(uid: uid),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        LuntiIconButton(
          icon: Icons.notifications_none,
          label: 'Notifications',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: context.lunti.warning,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: context.lunti.navLabel.copyWith(
                  color: context.lunti.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
