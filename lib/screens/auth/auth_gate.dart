import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../services/catalog_store.dart';
import '../../services/database_service.dart';
import '../root_screen.dart';
import '../splash_screen.dart';

/// App shell that keeps [RootScreen] available to signed-out guests.
///
/// Browsing Home, Shop, Product Details, Craft Story, Wishlist and the bag no
/// longer requires an account. Authentication is only requested when the
/// customer tries to check out or open Profile / Orders, which is handled by
/// the screens themselves.
///
/// The first auth event is also the app's real boot signal: a branded splash
/// covers that wait (with a short minimum so the animation is not a flicker),
/// then cross-fades into the same [RootScreen] guests and customers already
/// use. Routing is untouched.
///
/// This widget still listens for sign-in so the catalog seeding and the
/// `users/{uid}` document are created for accounts that sign in later.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Long enough for the pulse to read as intentional, short enough not to
  /// delay a returning customer.
  static const Duration _minimumSplash = Duration(milliseconds: 1200);

  /// Safety valve: never leave a customer on the splash if auth is slow or
  /// offline. Guests can browse without an account, so showing the app is safe.
  static const Duration _maximumSplash = Duration(seconds: 4);

  String? _seededForUser;
  Timer? _minimumTimer;
  Timer? _maximumTimer;
  bool _minimumElapsed = false;
  bool _maximumElapsed = false;

  @override
  void initState() {
    super.initState();
    _minimumTimer = Timer(_minimumSplash, () {
      if (mounted) setState(() => _minimumElapsed = true);
    });
    _maximumTimer = Timer(_maximumSplash, () {
      if (mounted) setState(() => _maximumElapsed = true);
    });
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    _maximumTimer?.cancel();
    super.dispose();
  }

  void _afterSignIn(User user) {
    if (_seededForUser == user.uid) return;
    _seededForUser = user.uid;
    CatalogStore.instance.start();
    CatalogStore.instance.ensureSeeded();
    DatabaseService().createUserIfMissing(user);
  }

  @override
  Widget build(BuildContext context) {
    // Widget tests build the app without calling main(), so keep the existing
    // RootScreen path when Firebase has not been initialized.
    if (Firebase.apps.isEmpty) return const RootScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _afterSignIn(user),
          );
        }

        final authSettled = snapshot.connectionState != ConnectionState.waiting;
        final showSplash =
            !_maximumElapsed && (!_minimumElapsed || !authSettled);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: showSplash
              ? const LuntiSplashScreen(key: ValueKey('lunti-splash'))
              : const RootScreen(key: ValueKey('lunti-root')),
        );
      },
    );
  }
}
