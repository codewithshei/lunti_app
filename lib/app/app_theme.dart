import 'package:flutter/material.dart';

/// LUNTI brand tokens, derived from the Figma handoff note:
/// forest/sage/cream/beige palette, Playfair Display + Poppins,
/// 8/12/16/24 spacing, 12/16/20 radii, 44-52px controls.
class LuntiColors {
  static const forest = Color(0xFF344E41);
  static const ink = Color(0xFF27372D);
  static const secondary = Color(0xFF687267);

  /// Body copy tone. Darker than [secondary] so 11-12px text still clears
  /// WCAG AA when it sits on the sage tint.
  static const secondaryText = Color(0xFF57624F);

  static const sage = Color(0xFFE8ECDF);
  static const cream = Color(0xFFFAF8F2);
  static const beige = Color(0xFFDAD7CD);
  static const white = Color(0xFFFFFFFF);
  static const mutedForeground = Color(0xFF687267);

  /// Deep terracotta used for stock warnings; stays readable on cream and
  /// sage while fitting the LUNTI palette.
  static const warning = Color(0xFF9C3D2E);

  /// Star / rating accent.
  static const rating = Color(0xFFC58A2B);
}

/// Shared elevation. Every card in the app draws from this list so surfaces
/// stay consistent instead of each screen inventing its own blur radius.
class LuntiShadows {
  LuntiShadows._();

  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(0x1427372D), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> sm = <BoxShadow>[
    BoxShadow(color: Color(0x1427372D), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> lg = <BoxShadow>[
    BoxShadow(color: Color(0x2E27372D), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

/// Shared motion tokens for micro-interactions.
class LuntiMotion {
  LuntiMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// Width breakpoints used by adaptive layouts.
class LuntiBreakpoints {
  LuntiBreakpoints._();

  /// Phones in portrait.
  static const double compact = 360;

  /// Small tablets and large phones in landscape.
  static const double medium = 600;

  /// Tablets and desktop windows.
  static const double expanded = 840;
}

/// True when the current window is at least [width] logical pixels wide.
bool luntiAtLeast(double width, double breakpoint) => width >= breakpoint;

class LuntiSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const gutter = 20.0;
}

class LuntiRadii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
}

class LuntiTextStyles {
  static const _playfair = 'Playfair Display';
  static const _poppins = 'Poppins';

  static const eyebrow = TextStyle(
    fontFamily: _poppins,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: LuntiColors.ink,
  );

  static const display = TextStyle(
    fontFamily: _playfair,
    fontSize: 27,
    fontWeight: FontWeight.w600,
    height: 1.12,
    color: LuntiColors.ink,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _playfair,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    color: LuntiColors.ink,
  );

  static const cardTitle = TextStyle(
    fontFamily: _poppins,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: LuntiColors.ink,
  );

  static const price = TextStyle(
    fontFamily: _poppins,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: LuntiColors.ink,
  );

  static const caption = TextStyle(
    fontFamily: _poppins,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: LuntiColors.secondaryText,
  );

  static const body = TextStyle(
    fontFamily: _poppins,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: LuntiColors.secondaryText,
    height: 1.5,
  );

  static const onDarkBody = TextStyle(
    fontFamily: _poppins,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: LuntiColors.cream,
    height: 1.5,
  );

  static const navLabel = TextStyle(
    fontFamily: _poppins,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}

/// Subtle fade + short horizontal slide shared by every pushed route so
/// Home -> Shop -> Catalog -> Details -> Checkout feel like one flow.
class LuntiPageTransitionsBuilder extends PageTransitionsBuilder {
  const LuntiPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData buildLuntiTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: LuntiColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LuntiColors.forest,
    ).copyWith(surface: LuntiColors.cream),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Poppins', bodyColor: LuntiColors.ink),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: LuntiPageTransitionsBuilder(),
        TargetPlatform.iOS: LuntiPageTransitionsBuilder(),
        TargetPlatform.linux: LuntiPageTransitionsBuilder(),
        TargetPlatform.macOS: LuntiPageTransitionsBuilder(),
        TargetPlatform.windows: LuntiPageTransitionsBuilder(),
        TargetPlatform.fuchsia: LuntiPageTransitionsBuilder(),
      },
    ),
  );
}
