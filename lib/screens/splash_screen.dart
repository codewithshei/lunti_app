import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Branded first-launch screen.
///
/// Shown while the app finishes booting and the first auth state arrives, then
/// cross-faded into [RootScreen] by `AuthGate`. It deliberately owns no routing
/// or state: it only paints the LUNTI mark and a quiet loading message.
class LuntiSplashScreen extends StatefulWidget {
  const LuntiSplashScreen({super.key, this.message = 'Rooted in craft\u2026'});

  /// Short line under the wordmark. Kept as a parameter so tests and future
  /// boot steps can reuse the same visual without duplicating the widget.
  final String message;

  @override
  State<LuntiSplashScreen> createState() => _LuntiSplashScreenState();
}

class _LuntiSplashScreenState extends State<LuntiSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the OS "remove animations" setting: hold the mark at rest instead
    // of pulsing forever.
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reducedMotion && _controller.isAnimating) return;
    _reducedMotion = reduce;
    if (reduce) {
      _controller.stop();
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: Stack(
        children: [
          // Soft sage wash behind the mark so the cream canvas still feels warm
          // rather than flat.
          Positioned(
            top: -120,
            right: -80,
            child: _SplashAura(color: context.lunti.surfaceAlt, size: 320),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _SplashAura(color: context.lunti.border, size: 340),
          ),
          Center(
            child: Semantics(
              container: true,
              excludeSemantics: true,
              liveRegion: true,
              label: 'LUNTI is loading. ${widget.message}',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final pulse = Curves.easeInOut.transform(
                        _controller.value,
                      );
                      return Transform.scale(
                        scale: 0.94 + (0.06 * pulse),
                        child: Opacity(
                          opacity: 0.84 + (0.16 * pulse),
                          child: Container(
                            width: 112,
                            height: 112,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.lunti.surfaceAlt.withValues(alpha: 0.55),
                              boxShadow: [
                                BoxShadow(
                                  color: context.lunti.accent.withValues(
                                    alpha: 0.08 + (0.06 * pulse),
                                  ),
                                  blurRadius: 30 + (14 * pulse),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              width: 84,
                              height: 84,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: context.lunti.surfaceAlt,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.eco_rounded,
                                size: 42,
                                color: context.lunti.accent,
                                semanticLabel: 'LUNTI leaf',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'LUNTI',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 8,
                      color: context.lunti.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(width: 34, height: 1, color: context.lunti.border),
                  const SizedBox(height: 14),
                  Text(
                    widget.message,
                    style: context.lunti.body.copyWith(letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 22),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: EdgeInsets.only(left: i == 0 ? 0 : 7),
                                child: _LoadingDot(
                                  opacity: _dotOpacity(_controller.value, i),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Staggered triangle wave so the three dots breathe one after another.
  static double _dotOpacity(double t, int index) {
    final phase = (t + (index / 3)) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.25 + (0.75 * wave);
  }
}

class _LoadingDot extends StatelessWidget {
  const _LoadingDot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: context.lunti.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Very soft radial tint used as a background wash.
class _SplashAura extends StatelessWidget {
  const _SplashAura({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
