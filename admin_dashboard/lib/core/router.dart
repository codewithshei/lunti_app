import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/features/auth/login_page.dart';
import 'package:admin_dashboard/features/auth/services/auth_service.dart';
import 'package:admin_dashboard/features/dashboard/dashboard_page.dart';
import 'package:admin_dashboard/features/messages/messages_page.dart';
import 'package:admin_dashboard/features/orders/order_detail_page.dart';
import 'package:admin_dashboard/features/orders/orders_page.dart';
import 'package:admin_dashboard/features/products/product_form_page.dart';
import 'package:admin_dashboard/features/products/products_page.dart';
import 'package:admin_dashboard/features/reviews/reviews_page.dart';
import 'package:admin_dashboard/widgets/admin_shell.dart';

class AppRouter {
  static final GoRouter config = GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthStatusListener(),
    redirect: (context, state) {
      final auth = AuthService.instance;
      final isLoggedIn = auth.currentUser != null;
      final location = state.uri.path;
      if (!isLoggedIn && location != '/login') return '/login';
      if (isLoggedIn && location == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (context, state) => const ProductsPage(),
          ),
          GoRoute(
            path: '/products/new',
            name: 'productNew',
            builder: (context, state) => const ProductFormPage(),
          ),
          GoRoute(
            path: '/products/edit/:id',
            name: 'productEdit',
            builder: (context, state) =>
                ProductFormPage(productId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/reviews',
            name: 'reviews',
            builder: (context, state) => const ReviewsPage(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesPage(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: '/orders/detail/:id',
            name: 'orderDetail',
            builder: (context, state) =>
                OrderDetailPage(orderId: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
    ],
  );
}

class _AuthStatusListener extends ChangeNotifier {
  _AuthStatusListener() {
    AuthService.instance.authStateChanges.listen((_) => notifyListeners());
  }
}
