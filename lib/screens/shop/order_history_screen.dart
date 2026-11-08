import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/router.dart';
import '../../data/mock_app_state.dart';
import '../../services/order_service.dart';
import '../auth/auth_widgets.dart';
import '../../utils/order_display.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/lunti_skeleton.dart';
import '../../widgets/lunti_states.dart';
import '../../widgets/order_status_pill.dart';
import '../../widgets/payment_badge.dart';

/// Order history. When Firebase is available the list is a live Firestore
/// `StreamBuilder`, so status changes made in the admin dashboard appear here
/// without reloading. Widget tests (no Firebase) keep using local prototype
/// orders.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({
    super.key,
    required this.onBack,
    required this.onViewOrder,
    this.onBrowseShop,
  });

  final VoidCallback onBack;
  final void Function(Order order) onViewOrder;

  /// Optional empty-state action back to the shop landing.
  final VoidCallback? onBrowseShop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandHeader(
              bagListenable: MockAppState.bagCount,
              onBack: onBack,
              onBagPressed: null,
              showBadge: false,
            ),
            Expanded(
              child: Firebase.apps.isEmpty
                  ? _buildOrders(context, null)
                  : StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListView(
                            padding: const EdgeInsets.all(
                              LuntiSpacing.gutter,
                            ),
                            children: const [
                              LuntiShimmer(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SkeletonBox(width: 190, height: 30),
                                    SizedBox(height: 12),
                                    SkeletonBox(width: 250, height: 12),
                                  ],
                                ),
                              ),
                              SizedBox(height: LuntiSpacing.lg),
                              SkeletonListTile(),
                              SizedBox(height: LuntiSpacing.sm),
                              SkeletonListTile(),
                              SizedBox(height: LuntiSpacing.sm),
                              SkeletonListTile(),
                            ],
                          );
                        }
                        return _buildOrders(context, snapshot.data);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrders(BuildContext context, User? user) {
    // Guests get an honest prompt rather than an empty "no orders" list.
    if (Firebase.apps.isNotEmpty && user == null) {
      return ListView(
        padding: const EdgeInsets.all(LuntiSpacing.gutter),
        children: [
          Text('Order history', style: LuntiTextStyles.display),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Track each order from workshop to doorstep.',
            style: LuntiTextStyles.body,
          ),
          const SizedBox(height: LuntiSpacing.lg),
          AuthRequiredCard(
            icon: Icons.receipt_long_outlined,
            title: 'Sign in to view your profile and order history',
            body: 'Your orders, addresses and tracking updates are saved to '
                'your LUNTI account.',
            actionLabel: 'Sign In',
            onPressed: () => AppRouter.openSignIn(
              context,
              title: 'Sign in to view your orders',
              subtitle:
                  'Order history and live tracking stay with your LUNTI '
                  'account.',
            ),
          ),
        ],
      );
    }

    if (user == null) {
      return ValueListenableBuilder<List<Order>>(
        valueListenable: MockAppState.orders,
        builder: (context, orders, _) => _OrderList(
          orders: orders,
          onViewOrder: onViewOrder,
          onBrowseShop: onBrowseShop,
        ),
      );
    }

    return StreamBuilder<List<Order>>(
      stream: OrderService.instance.watchUserOrders(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return ListView(
            padding: const EdgeInsets.all(LuntiSpacing.gutter),
            children: const [
              LuntiShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 190, height: 30),
                    SizedBox(height: 12),
                    SkeletonBox(width: 250, height: 12),
                  ],
                ),
              ),
              SizedBox(height: LuntiSpacing.lg),
              SkeletonListTile(),
              SizedBox(height: LuntiSpacing.sm),
              SkeletonListTile(),
              SizedBox(height: LuntiSpacing.sm),
              SkeletonListTile(),
            ],
          );
        }
        if (snapshot.hasError) {
          return _OrderList(
            orders: MockAppState.orders.value,
            onViewOrder: onViewOrder,
            onBrowseShop: onBrowseShop,
            notice:
                'Could not load live orders. Showing this '
                'session\'s prototype orders.',
          );
        }
        return _OrderList(
          orders: snapshot.data ?? const <Order>[],
          onViewOrder: onViewOrder,
          onBrowseShop: onBrowseShop,
        );
      },
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.onViewOrder,
    this.onBrowseShop,
    this.notice,
  });

  final List<Order> orders;
  final void Function(Order order) onViewOrder;
  final VoidCallback? onBrowseShop;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(LuntiSpacing.gutter),
        children: [
          Text('Order history', style: LuntiTextStyles.display),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Every order you place with LUNTI will appear here.',
            style: LuntiTextStyles.body,
          ),
          if (notice != null) ...[
            const SizedBox(height: LuntiSpacing.sm),
            _NoticeBanner(message: notice!),
          ],
          const SizedBox(height: LuntiSpacing.lg),
          LuntiEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message:
                'When you place an order, you can follow its status here.',
            actionLabel: onBrowseShop == null ? null : 'Browse the shop',
            onAction: onBrowseShop,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(LuntiSpacing.gutter),
      children: [
        Text('Order history', style: LuntiTextStyles.display),
        const SizedBox(height: LuntiSpacing.xs),
        Text(
          'Track each order from workshop to doorstep.',
          style: LuntiTextStyles.body,
        ),
        if (notice != null) ...[
          const SizedBox(height: LuntiSpacing.sm),
          _NoticeBanner(message: notice!),
        ],
        const SizedBox(height: LuntiSpacing.md),
        for (final order in orders)
          Padding(
            padding: const EdgeInsets.only(bottom: LuntiSpacing.sm),
            child: _OrderCard(order: order, onTap: () => onViewOrder(order)),
          ),
        const SizedBox(height: LuntiSpacing.lg),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LuntiColors.white,
      borderRadius: BorderRadius.circular(LuntiRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LuntiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(order.id, style: LuntiTextStyles.cardTitle),
                  ),
                  OrderStatusPill(status: order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(formatOrderDate(order.createdAt),
                  style: LuntiTextStyles.caption),
              const SizedBox(height: LuntiSpacing.sm),
              const Divider(color: LuntiColors.beige, height: 1),
              const SizedBox(height: LuntiSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.itemCount} item(s)',
                          style: LuntiTextStyles.body,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\u20B1${order.total}',
                          style: LuntiTextStyles.price,
                        ),
                        const SizedBox(height: 4),
                        PaymentStatusBadge(
                          compact: true,
                          status: order.paymentStatusDisplay,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'View details',
                    style: LuntiTextStyles.caption.copyWith(
                      color: LuntiColors.forest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: LuntiColors.forest,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.sm),
      decoration: BoxDecoration(
        color: LuntiColors.sage,
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: LuntiColors.secondary,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: LuntiTextStyles.caption)),
        ],
      ),
    );
  }
}
