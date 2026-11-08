import 'package:flutter/material.dart';

/// LUNTI palette for one brightness.
///
/// Screens read a SEMANTIC ROLE (background / surface / text / accent / border)
/// through `context.lunti` instead of hardcoding a [Color]. Both themes in
/// this file register one of these as a [ThemeExtension], so a role resolves
/// against the active theme and every widget that paints with it rebuilds when
/// the mode changes.
@immutable
class LuntiPalette extends ThemeExtension<LuntiPalette> {
  const LuntiPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.warning,
    required this.rating,
  });

  /// Scaffold / screen background.
  final Color background;

  /// Cards and other raised surfaces.
  final Color surface;

  /// Tinted fills: selected chips, skeletons, empty states, scrims.
  final Color surfaceAlt;

  /// Headlines and primary copy.
  final Color text;

  /// Secondary copy and inactive icons.
  final Color textMuted;

  /// Decorative tertiary tone: dividers, hints, inactive nav labels. Lighter
  /// than [textMuted] so small text stays readable on the sage tint.
  final Color textFaint;

  /// Brand green: buttons, links, active states.
  final Color accent;

  /// Text and icons drawn on top of [accent].
  final Color onAccent;

  /// Hairlines, dividers and outlined controls.
  final Color border;

  /// Stock warnings and destructive accents.
  final Color warning;

  /// Star / rating accent.
  final Color rating;

  /// Light: the warm sand palette the app shipped with.
  static const LuntiPalette light = LuntiPalette(
    background: Color(0xFFFAF8F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE8ECDF),
    text: Color(0xFF27372D),
    textMuted: Color(0xFF57624F),
    textFaint: Color(0xFF687267),
    accent: Color(0xFF344E41),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0xFFDAD7CD),
    warning: Color(0xFF9C3D2E),
    rating: Color(0xFFC58A2B),
  );

  /// Dark: deep charcoal sage, soft sage accents, warm cream text.
  ///
  /// [text] and [textMuted] stay high-contrast against [background] and
  /// [surface] so Playfair Display headlines and Poppins body copy keep WCAG AA.
  static const LuntiPalette dark = LuntiPalette(
    background: Color(0xFF141E18),
    surface: Color(0xFF202C24),
    surfaceAlt: Color(0xFF2A382F),
    text: Color(0xFFF4F1E6),
    textMuted: Color(0xFFB7C4B2),
    textFaint: Color(0xFF8FA08C),
    accent: Color(0xFFA9C6A0),
    onAccent: Color(0xFF141E18),
    border: Color(0xFF33423A),
    warning: Color(0xFFE8A08C),
    rating: Color(0xFFD9B26A),
  );

  // ---- Text styles ------------------------------------------------------
  // Same families, sizes and weights as the original LuntiTextStyles; only
  // the colours follow the palette.

  static const _playfair = 'Playfair Display';
  static const _poppins = 'Poppins';

  TextStyle get eyebrow => TextStyle(
        fontFamily: _poppins,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: text,
      );

  TextStyle get display => TextStyle(
        fontFamily: _playfair,
        fontSize: 27,
        fontWeight: FontWeight.w600,
        height: 1.12,
        color: text,
      );

  TextStyle get sectionTitle => TextStyle(
        fontFamily: _playfair,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: text,
      );

  TextStyle get cardTitle => TextStyle(
        fontFamily: _poppins,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: text,
      );

  TextStyle get price => TextStyle(
        fontFamily: _poppins,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: text,
      );

  TextStyle get caption => TextStyle(
        fontFamily: _poppins,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  TextStyle get body => TextStyle(
        fontFamily: _poppins,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.5,
      );

  /// Body copy on a tinted fill. Kept as a named role so call sites that
  /// spell out the intent keep working; it resolves to the same value as
  /// [body], which is already cream-on-sage in the dark palette.
  TextStyle get onDarkBody => body;

  TextStyle get navLabel => const TextStyle(
        fontFamily: _poppins,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );

  @override
  LuntiPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? accent,
    Color? onAccent,
    Color? border,
    Color? warning,
    Color? rating,
  }) {
    return LuntiPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      border: border ?? this.border,
      warning: warning ?? this.warning,
      rating: rating ?? this.rating,
    );
  }

  @override
  LuntiPalette lerp(LuntiPalette other, double t) {
    return LuntiPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
    );
  }
}

/// The active palette for this context, or the light one when no
/// [LuntiPalette] is registered (widget tests that pump a screen directly).
extension LuntiPaletteX on BuildContext {
  LuntiPalette get lunti =>
      Theme.of(this).extension<LuntiPalette>() ?? LuntiPalette.light;
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

/// Builds the light or dark Material 3 theme around [palette].
ThemeData _buildLuntiTheme(LuntiPalette palette, Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
    ).copyWith(
      primary: palette.accent,
      onPrimary: palette.onAccent,
      surface: palette.surface,
      onSurface: palette.text,
      outline: palette.border,
      outlineVariant: palette.border,
    ),
    extensions: <ThemeExtension<dynamic>>[palette],
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: palette.text,
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        side: BorderSide(color: palette.border),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.onAccent
            : palette.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.accent
            : palette.surfaceAlt,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.accent
            : palette.border,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.accent,
      contentTextStyle: TextStyle(color: palette.onAccent),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuntiRadii.lg)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
    ),
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

/// Light theme: the warm sand palette.
ThemeData buildLuntiTheme() =>
    _buildLuntiTheme(LuntiPalette.light, Brightness.light);

/// Dark theme: deep charcoal sage with soft sage accents and cream text.
ThemeData buildLuntiDarkTheme() =>
    _buildLuntiTheme(LuntiPalette.dark, Brightness.dark);
