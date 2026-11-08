import 'dart:async';

import 'package:admin_dashboard/core/router.dart';
import 'package:admin_dashboard/firebase_options.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed demo products in the background. Product writes need a signed-in
  // session under the Firestore rules, so failure here is expected before
  // login; the login screen retries seeding after authentication.
  unawaited(AdminDatabase().seedProducts());

  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LUNTI Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(),
      routerConfig: AppRouter.config,
    );
  }
}
