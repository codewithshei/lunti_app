import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'pressable.dart';

/// One story card in the Home banner carousel.
class HomeCarouselSlide {
  const HomeCarouselSlide({
    required this.image,
    required this.eyebrow,
    required this.headline,
    required this.actionLabel,
    required this.onTap,
  });

  final String image;
  final String eyebrow;
  final String headline;
  final String actionLabel;
  final VoidCallback onTap;
}

/// Swipeable, auto-advancing banner carousel for the Home screen.
///
/// Each slide is a full-width rounded photo card with a soft forest gradient
/// and a short craft story from Cardona, Rizal. Swiping pauses the timer until
/// the next interval so the reader is never interrupted mid-slide.
class HomeCarousel extends StatefulWidget {
  const HomeCarousel({super.key, required this.slides});

  final List<HomeCarouselSlide> slides;

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.slides.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 198,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (index) {
              setState(() => _index = index);
              // Give the reader a full interval after a manual swipe.
              _restartTimer();
            },
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuntiSpacing.gutter,
                ),
                child: _SlideCard(slide: slide),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? LuntiColors.forest : LuntiColors.beige,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final HomeCarouselSlide slide;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${slide.eyebrow}. ${slide.headline}. ${slide.actionLabel}.',
      child: PressableScale(
        onTap: slide.onTap,
        pressedScale: 0.985,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LuntiRadii.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                slide.image,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/hero_craft.jpg',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x1427372D),
                      Color(0x3327372D),
                      Color(0xE627372D),
                    ],
                    stops: [0, 0.42, 1],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slide.eyebrow.toUpperCase(),
                      style: LuntiTextStyles.eyebrow.copyWith(
                        color: LuntiColors.sage,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.headline,
                      style: LuntiTextStyles.sectionTitle.copyWith(
                        color: LuntiColors.cream,
                        fontSize: 23,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          slide.actionLabel,
                          style: LuntiTextStyles.cardTitle.copyWith(
                            color: LuntiColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: LuntiColors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
