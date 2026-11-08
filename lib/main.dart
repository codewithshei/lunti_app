import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app/app_theme.dart';
import 'data/mock_app_state.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/root_screen.dart';
import 'widgets/dev_iphone_chrome.dart';
import 'services/catalog_store.dart';
import 'services/shopping_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Restore the bag and wishlist for the account that is already signed in on
  // this device (or the guest scope) before the first frame. Every identity has
  // its own snapshot, so another account's cart can never appear here.
  String initialScope = MockAppState.guestShoppingScope;
  try {
    initialScope = FirebaseAuth.instance.currentUser?.uid ?? initialScope;
  } catch (error) {
    // Auth is unavailable on this platform; the guest scope is the safe default.
    debugPrint('Could not read the signed-in account: $error');
  }
  await MockAppState.initializePersistence(scope: initialScope);

  // Seed any bundled products missing from Firestore so the mobile app and
  // the admin dashboard share one catalog. Signed-in accounts retry this in
  // AuthGate because security rules reject writes before authentication.
  // Guests still browse the bundled catalog, so launch never waits for login
  // or for this network round-trip: the splash covers the app boot and the
  // catalog stream picks up seeded products when they arrive.
  unawaited(CatalogStore.instance.ensureSeeded());

  // Start the live catalog for real-time updates.
  CatalogStore.instance.start();

  // Keep a signed-in customer's bag/wishlist backed up in Firestore. This is
  // best-effort; the local snapshot remains the source of truth.
  ShoppingSyncService.instance.start();

  runApp(const LuntiApp());
}

class LuntiApp extends StatelessWidget {
  const LuntiApp({super.key});

  /// DEV-ONLY presentation knob: --dart-define=LUNTI_FRAME=iphone draws
  /// iOS status bar / Dynamic Island / home indicator for desktop previews.
  static const bool _iphoneFrame =
      String.fromEnvironment('LUNTI_FRAME') == 'iphone';

  @override
  Widget build(BuildContext context) {
    // Widget tests build LuntiApp without calling main(), so keep the existing
    // RootScreen available when Firebase has not been initialized.
    final Widget home = Firebase.apps.isEmpty
        ? const RootScreen()
        : const AuthGate();

    return MaterialApp(
      title: 'LUNTI',
      debugShowCheckedModeBanner: false,
      theme: buildLuntiTheme(),
      home: _iphoneFrame ? DevIphoneChrome(child: home) : home,
    );
  }
}
