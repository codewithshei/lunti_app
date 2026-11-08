import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// DEV-ONLY iPhone-style presentation chrome for desktop previews:
/// draws an iOS status bar (9:41, signal, wifi, battery), a Dynamic
/// Island pill and a home indicator over the app, and pads the app via
/// MediaQuery so real SafeArea-consuming content sits below/above them.
/// Enabled with --dart-define=LUNTI_FRAME=iphone. Real iOS devices get
/// the OS chrome instead, so this never ships.
class DevIphoneChrome extends StatelessWidget {
  const DevIphoneChrome({super.key, required this.child});

  final Widget child;

  static const double _statusHeight = 54;
  static const double _homeHeight = 28;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: MediaQuery.of(context).padding +
            const EdgeInsets.fromLTRB(0, _statusHeight, 0, _homeHeight),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _statusHeight,
            child: _IphoneStatusBar(),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 60,
            top: 11,
            child: Container(
              width: 120,
              height: 34,
              decoration: BoxDecoration(
                color: context.lunti.text,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _homeHeight,
            child: _HomeIndicator(),
          ),
        ],
      ),
    );
  }
}

class _IphoneStatusBar extends StatelessWidget {
  const _IphoneStatusBar();

  @override
  Widget build(BuildContext context) {
    final iconColor = context.lunti.text;
    return Container(
      color: context.lunti.background,
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      child: Row(
        children: [
          Text(
            '9:41',
            style: context.lunti.cardTitle.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              fontFamily: null,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          Container(
            width: 17,
            height: 11,
            margin: const EdgeInsets.only(right: 5),
            child: CustomPaint(painter: _SignalPainter(color: iconColor)),
          ),
          Icon(Icons.wifi, size: 15, color: iconColor),
          const SizedBox(width: 4),
          Container(
            width: 25,
            height: 12,
            margin: const EdgeInsets.only(left: 2),
            child: CustomPaint(painter: _BatteryPainter(color: iconColor)),
          ),
        ],
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  const _SignalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final barHeight = size.height * (0.45 + i * 0.18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * (size.width / 4 - 0.5),
            size.height - barHeight,
            size.width / 4 - 1.5,
            barHeight,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = color;
    final body = Rect.fromLTWH(0.5, 0.5, size.width - 5, size.height - 1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      stroke,
    );
    // charge level fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.deflate(2.5),
        const Radius.circular(2),
      ),
      fill,
    );
    // battery nub
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 3, size.height * 0.25, 2, size.height * 0.5),
        const Radius.circular(1),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: 140,
        height: 5,
        decoration: BoxDecoration(
          color: context.lunti.text,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
