import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/mock_app_state.dart';
import '../widgets/brand_header.dart';
import '../widgets/common.dart';
import '../widgets/controls.dart';

/// "Our Craft & Artisans" story, opened from the Home banner.
///
/// The page explains the Cardona, Rizal workshop in three steps (sourcing,
/// shaping, finishing) and closes with a sticky "Explore Collection" action
/// that routes to the real catalog. Photos are the bundled workshop assets.
class CraftStoryScreen extends StatelessWidget {
  const CraftStoryScreen({super.key, required this.onExploreCollection});

  /// Opens the catalog. Supplied by the root router so the Shop tab (and its
  /// nested navigator) handles product taps correctly.
  final VoidCallback onExploreCollection;

  static const _steps = <_CraftStep>[
    _CraftStep(
      number: '01',
      title: 'Sourcing',
      copy:
          'Bamboo is gathered from local growers around Cardona, Rizal, then '
          'seasoned until it is ready to work.',
      image: 'assets/images/craft_sourcing.jpg',
    ),
    _CraftStep(
      number: '02',
      title: 'Shaping',
      copy:
          'Artisans measure, cut and shape each piece by hand, following the '
          'natural grain instead of forcing it.',
      image: 'assets/images/craft_shaping.jpg',
    ),
    _CraftStep(
      number: '03',
      title: 'Finishing',
      copy:
          'Sanding, engraving and a food-safe finish bring out the character '
          'of every piece before it is checked and packed.',
      image: 'assets/images/craft_finishing.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  BrandHeader(
                    bagListenable: MockAppState.bagCount,
                    onBack: () => Navigator.of(context).maybePop(),
                    onBagPressed: null,
                    showBadge: false,
                  ),
                  const SizedBox(height: LuntiSpacing.md),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: _StoryHero(),
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EyebrowLabel(text: 'Our craft & artisans'),
                        SizedBox(height: LuntiSpacing.xs),
                        Text(
                          'Made slowly,\nby local hands.',
                          style: context.lunti.display,
                        ),
                        SizedBox(height: LuntiSpacing.sm),
                        Text(
                          'LUNTI works with bamboo crafters in Cardona, Rizal. '
                          'Every piece starts in the grove, passes through the '
                          'workshop, and leaves with a little room for your own '
                          'story.',
                          style: context.lunti.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: Text(
                      'From grove to home',
                      style: context.lunti.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.sm),
                  for (final step in _steps)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        LuntiSpacing.gutter,
                        0,
                        LuntiSpacing.gutter,
                        LuntiSpacing.sm,
                      ),
                      child: _StepCard(step: step),
                    ),
                  const SizedBox(height: LuntiSpacing.sm),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: LuntiSpacing.gutter,
                    ),
                    child: _ArtisanCard(),
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                ],
              ),
            ),
            _StickyCta(onPressed: onExploreCollection),
          ],
        ),
      ),
    );
  }
}

class _CraftStep {
  const _CraftStep({
    required this.number,
    required this.title,
    required this.copy,
    required this.image,
  });

  final String number;
  final String title;
  final String copy;
  final String image;
}

/// Auto-sliding hero carousel.
///
/// The workshop photos are pre-cropped to the banner frame's aspect ratio, so
/// [BoxFit.cover] fills the 16px-rounded card with no letterboxing or
/// stretching. Slides advance every four seconds, loop, and stay put while the
/// admin is swiping.
class _StoryHero extends StatefulWidget {
  const _StoryHero();

  @override
  State<_StoryHero> createState() => _StoryHeroState();
}

class _StoryHeroState extends State<_StoryHero> {
  static const _slideDuration = Duration(seconds: 4);

  static const _slides = <String>[
    'assets/images/craft_hero1.jpg',
    'assets/images/craft_hero2.jpg',
    'assets/images/craft_hero3.jpg',
    'assets/images/craft_hero4.jpg',
    'assets/images/craft_hero5.jpg',
  ];

  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_slideDuration, (_) => _advance());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    // Leave the slide alone while the reader is mid-swipe.
    if (_controller.position.isScrollingNotifier.value) return;
    _go(_page + 1);
  }

  void _go(int page) {
    final next = page % _slides.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LuntiRadii.md),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) => Image.asset(
                _slides[index],
                fit: BoxFit.cover,
                semanticLabel: 'LUNTI bamboo workshop in Cardona, Rizal',
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC1B2A20)],
                ),
              ),
            ),
            Positioned(
              left: LuntiSpacing.md,
              right: LuntiSpacing.md,
              bottom: LuntiSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARDONA, RIZAL',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: context.lunti.surfaceAlt,
                    ),
                  ),
                  SizedBox(height: LuntiSpacing.xs),
                  Text(
                    'Local hands.\nLasting character.',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: context.lunti.background,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _page == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _page == i
                            ? context.lunti.background
                            : context.lunti.background.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _CraftStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.sm),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
            child: SizedBox(
              width: 88,
              height: 88,
              child: Image.asset(step.image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: LuntiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP ${step.number}',
                  style: context.lunti.eyebrow.copyWith(
                    color: context.lunti.textFaint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(step.title, style: context.lunti.cardTitle),
                const SizedBox(height: 4),
                Text(step.copy, style: context.lunti.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtisanCard extends StatelessWidget {
  const _ArtisanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.lunti.accent,
        borderRadius: BorderRadius.circular(LuntiRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(LuntiRadii.md),
            child: AspectRatio(
              aspectRatio: 342 / 132,
              child: Image.asset(
                'assets/images/hero_craft.jpg',
                fit: BoxFit.cover,
                semanticLabel: 'Bamboo artisan shaping a piece by hand',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, LuntiSpacing.md, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE ARTISANS',
                  style: context.lunti.eyebrow.copyWith(
                    color: context.lunti.surfaceAlt,
                  ),
                ),
                const SizedBox(height: LuntiSpacing.xs),
                Text(
                  'Every curve is shaped by someone who knows the material.',
                  style: context.lunti.sectionTitle.copyWith(
                    color: context.lunti.background,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: LuntiSpacing.sm),
                Text(
                  'No two pieces leave the workshop exactly alike. Small '
                  'differences in grain, tone and engraving are part of the '
                  'craft, not a defect.',
                  style: context.lunti.onDarkBody,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCta extends StatelessWidget {
  const _StickyCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LuntiSpacing.gutter,
        LuntiSpacing.sm,
        LuntiSpacing.gutter,
        LuntiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.lunti.background,
        border: Border(top: BorderSide(color: context.lunti.border)),
      ),
      child: PrimaryButton(
        label: 'Explore Collection',
        expand: true,
        onPressed: onPressed,
      ),
    );
  }
}
