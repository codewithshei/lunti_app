import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/mock_app_state.dart';
import '../../services/order_format.dart';
import '../../services/order_service.dart';
import '../../widgets/brand_header.dart';
import 'widgets/receipt_download_button.dart';

/// Order tracking. In production the current status comes from a live Firestore
/// snapshot of the order document, so admin status updates appear immediately.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    super.key,
    required this.order,
    required this.onBack,
  });

  final Order order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final live = OrderService.isAvailable
        ? StreamBuilder<Order?>(
            stream: OrderService.instance.watchOrder(order.id),
            builder: (context, snapshot) {
              return _TrackingBody(
                order: snapshot.data ?? order,
                onBack: onBack,
              );
            },
          )
        : _TrackingBody(order: order, onBack: onBack);

    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(bottom: false, child: live),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.order, required this.onBack});

  final Order order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final timestamps = _timestampsFor(order);
    var currentIndex = _kSteps.indexWhere((step) => step.status == order.status);
    if (currentIndex < 0) currentIndex = 0;

    return Column(
      children: <Widget>[
        BrandHeader(
          bagListenable: MockAppState.bagCount,
          onBack: onBack,
          onBagPressed: () {},
          showBadge: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(LuntiSpacing.gutter),
            children: <Widget>[
              Text('Order tracking', style: context.lunti.display),
              const SizedBox(height: LuntiSpacing.xs),
              Text(order.id, style: context.lunti.caption),
              const SizedBox(height: LuntiSpacing.sm),
              if (isCancelled)
                _CancelledCard(order: order)
              else ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(LuntiSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.lunti.surfaceAlt,
                    borderRadius: BorderRadius.circular(LuntiRadii.sm),
                  ),
                  child: Text(
                    'Status: ${order.status.label} · updates in real time.',
                    style: context.lunti.body.copyWith(
                      color: context.lunti.text,
                    ),
                  ),
                ),
                const SizedBox(height: LuntiSpacing.md),
                Container(
                  padding: const EdgeInsets.all(LuntiSpacing.md),
                  decoration: BoxDecoration(
                    color: context.lunti.surface,
                    borderRadius: BorderRadius.circular(LuntiRadii.md),
                  ),
                  child: _TrackingTimeline(
                    currentIndex: currentIndex,
                    timestamps: timestamps,
                  ),
                ),
              ],
              const SizedBox(height: LuntiSpacing.md),
              ReceiptDownloadButton(order: order),
              const SizedBox(height: LuntiSpacing.md),
              Text(
                'This is a prototype tracking view. No real courier is '
                'connected.',
                style: context.lunti.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Maps each status to the moment it was reached so the timeline can show a
  /// real timestamp per step.
  ///
  /// Legacy orders with an empty history still get the order date for the
  /// placement step; steps without a recorded timestamp show '—'.
  static Map<OrderStatus, DateTime> _timestampsFor(Order order) {
    final timestamps = <OrderStatus, DateTime>{};
    for (final entry in order.statusHistory) {
      timestamps[entry.status] = entry.at;
    }
    timestamps.putIfAbsent(OrderStatus.pending, () => order.createdAt);
    return timestamps;
  }
}

/// One happy-path fulfilment step.
class _TimelineStep {
  const _TimelineStep(this.status, this.label, this.icon, this.detail);

  final OrderStatus status;
  final String label;
  final IconData icon;
  final String detail;
}

const List<_TimelineStep> _kSteps = <_TimelineStep>[
  _TimelineStep(
    OrderStatus.pending,
    'Order placed',
    Icons.schedule,
    'We received your order.',
  ),
  _TimelineStep(
    OrderStatus.approved,
    'Approved',
    Icons.check_circle_outline,
    'LUNTI confirmed your order.',
  ),
  _TimelineStep(
    OrderStatus.packed,
    'Packed',
    Icons.inventory_2,
    'Your pieces were wrapped with care.',
  ),
  _TimelineStep(
    OrderStatus.shipped,
    'Shipped',
    Icons.local_shipping,
    'Your order is on its way.',
  ),
  _TimelineStep(
    OrderStatus.completed,
    'Completed',
    Icons.task_alt,
    'Delivered — enjoy your pieces.',
  ),
];

enum _StepState { todo, current, done }

/// Animated vertical stepper.
///
/// A single controller drives both the staggered reveal of the steps and the
/// progressive fill of the connecting line, so the timeline walks up to the
/// current status instead of jumping to it. When the status changes the walk
/// simply restarts towards the new step.
class _TrackingTimeline extends StatefulWidget {
  const _TrackingTimeline({
    required this.currentIndex,
    required this.timestamps,
  });

  final int currentIndex;
  final Map<OrderStatus, DateTime> timestamps;

  @override
  State<_TrackingTimeline> createState() => _TrackingTimelineState();
}

class _TrackingTimelineState extends State<_TrackingTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _TrackingTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Progress measured in segments between steps: the connector after
        // step i is full once the progress passes i + 1.
        final progress = _controller.value * widget.currentIndex;
        return Column(
          children: <Widget>[
            for (int i = 0; i < _kSteps.length; i++) _buildStep(i, progress),
          ],
        );
      },
    );
  }

  Widget _buildStep(int index, double progress) {
    final step = _kSteps[index];
    final isCurrent = index == widget.currentIndex;
    final isDone = index < widget.currentIndex;
    final isReached = index <= widget.currentIndex;
    final timestamp = widget.timestamps[step.status];
    final state = isDone
        ? _StepState.done
        : isCurrent
            ? _StepState.current
            : _StepState.todo;

    // Stagger: each step fades and slides in just after the previous one.
    final interval = Interval(
      (index * 0.14).clamp(0.0, 1.0),
      (index * 0.14 + 0.5).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    );
    final reveal = interval.transform(_controller.value.clamp(0.0, 1.0));

    final timeLabel = isReached && timestamp != null
        ? formatOrderDateTime(timestamp)
        : '—';

    return Opacity(
      opacity: reveal,
      child: Transform.translate(
        offset: Offset(0, (1 - reveal) * 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              children: <Widget>[
                _StepBadge(icon: step.icon, state: state),
                if (index < _kSteps.length - 1)
                  _StepConnector(
                    fill: (progress - index).clamp(0.0, 1.0),
                  ),
              ],
            ),
            const SizedBox(width: LuntiSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      step.label,
                      style: context.lunti.cardTitle.copyWith(
                        color: isReached
                            ? context.lunti.text
                            : context.lunti.textFaint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(timeLabel, style: context.lunti.caption),
                    const SizedBox(height: 2),
                    Text(
                      isCurrent
                          ? 'In progress'
                          : isDone
                              ? 'Completed'
                              : 'Pending',
                      style: context.lunti.caption.copyWith(
                        color: isReached
                            ? context.lunti.textFaint
                            : context.lunti.border,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(step.detail, style: context.lunti.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.icon, required this.state});

  final IconData icon;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final reached = state != _StepState.todo;
    // Every badge keeps the same 38px box so the connector below always
    // starts at the same offset.
    return Container(
      width: 38,
      height: 38,
      decoration: state == _StepState.current
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.lunti.accent, width: 1.5),
            )
          : null,
      alignment: Alignment.center,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: reached ? context.lunti.accent : context.lunti.border,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 17,
          color: reached ? context.lunti.surface : context.lunti.textFaint,
        ),
      ),
    );
  }
}

/// The track between two steps, filled from the top by [fill] (0..1).
///
/// The badge above is 38px tall and this track is 43px, so every step row is
/// 81px and the line always ends exactly where the next badge starts.
class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.fill});

  final double fill;

  static const double height = 43;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      height: height,
      child: ColoredBox(
        color: context.lunti.border,
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: fill.clamp(0.0, 1.0),
            widthFactor: 1,
            child: ColoredBox(color: context.lunti.accent),
          ),
        ),
      ),
    );
  }
}

/// Cancelled orders get a distinct treatment: a red-toned card with the reason
/// and no timeline, so the screen never implies progress that never happened.
class _CancelledCard extends StatelessWidget {
  const _CancelledCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    DateTime? cancelledAt;
    for (final entry in order.statusHistory) {
      if (entry.status == OrderStatus.cancelled) cancelledAt = entry.at;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.cancel_outlined,
            size: 22,
            color: context.lunti.warning,
          ),
          const SizedBox(width: LuntiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Order cancelled',
                  style: context.lunti.cardTitle.copyWith(
                    color: context.lunti.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This order was cancelled. Contact LUNTI if you need help '
                  'placing a new order.',
                  style: context.lunti.body.copyWith(
                    color: context.lunti.warning,
                  ),
                ),
                if (cancelledAt != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Cancelled on ${formatOrderDateTime(cancelledAt)}',
                    style: context.lunti.caption.copyWith(
                      color: context.lunti.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
