import 'package:flutter/material.dart';

/// Light, airy palette for the LUNTI admin studio.
///
/// The customer app keeps its cream/forest identity; the dashboard mirrors it
/// with a misty sage canvas, floating white cards and muted pastel accents so
/// dense tables stay readable during long shifts without feeling clinical.
class AdminColors {
  AdminColors._();

  // Canvas & surfaces
  static const Color background = Color(0xFFF5F8F2);
  static const Color backgroundAlt = Color(0xFFEAF1E4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5EC);
  static const Color surfaceMuted = Color(0xFFE6EEDF);
  static const Color border = Color(0xFFE1E9DA);
  static const Color borderStrong = Color(0xFFC9D7C0);

  // Brand
  static const Color forest = Color(0xFF344E41);
  static const Color sage = Color(0xFFC8DABE);
  static const Color sageDeep = Color(0xFF6E9675);

  /// Pastel green used for primary action buttons, so the main call to action
  /// reads as part of the light studio theme rather than a dark block.
  static const Color sageGreen = Color(0xFF87A96B);
  static const Color cream = Color(0xFFFAF8F2);
  static const Color ink = Color(0xFF24352B);
  static const Color text = Color(0xFF2C3B31);
  static const Color muted = Color(0xFF5F6E63);

  // Semantic (darkened so tinted badges keep readable contrast)
  static const Color success = Color(0xFF357049);
  static const Color warning = Color(0xFF8A5F16);
  static const Color info = Color(0xFF33617F);
  static const Color danger = Color(0xFF9C3F3F);
  static const Color violet = Color(0xFF6D5A94);
  static const Color teal = Color(0xFF2F6B68);

  // Pastel washes for tinted cards and highlights
  static const Color mint = Color(0xFFE3F0DF);
  static const Color blush = Color(0xFFF7E9E4);
  static const Color sky = Color(0xFFE4EEF5);
  static const Color lilac = Color(0xFFEEE9F6);
  static const Color butter = Color(0xFFF8F1DE);

  // Shadows
  static const Color shadow = Color(0x14233A2A);
  static const Color shadowStrong = Color(0x1F233A2A);
}

ThemeData buildAdminTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AdminColors.forest,
        brightness: Brightness.light,
        surface: AdminColors.surface,
      ).copyWith(
        primary: AdminColors.forest,
        onPrimary: AdminColors.cream,
        primaryContainer: AdminColors.sage,
        onPrimaryContainer: AdminColors.ink,
        secondary: AdminColors.sageDeep,
        onSecondary: AdminColors.cream,
        secondaryContainer: AdminColors.mint,
        onSecondaryContainer: AdminColors.ink,
        tertiary: AdminColors.info,
        onTertiary: AdminColors.cream,
        error: AdminColors.danger,
        onError: Colors.white,
        surface: AdminColors.surface,
        onSurface: AdminColors.text,
        surfaceContainerHighest: AdminColors.surfaceAlt,
        outline: AdminColors.border,
        outlineVariant: AdminColors.border,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AdminColors.background,
  );

  final textTheme = base.textTheme.apply(
    bodyColor: AdminColors.text,
    displayColor: AdminColors.ink,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontFamily: 'PlayfairDisplay',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AdminColors.ink,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontFamily: 'PlayfairDisplay',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AdminColors.ink,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AdminColors.ink,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AdminColors.ink,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AdminColors.text,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: AdminColors.text,
        height: 1.45,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(color: AdminColors.muted),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    cardTheme: CardThemeData(
      color: AdminColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminColors.border),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AdminColors.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AdminColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AdminColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AdminColors.surface,
      hintStyle: const TextStyle(color: AdminColors.muted),
      labelStyle: const TextStyle(color: AdminColors.muted),
      floatingLabelStyle: const TextStyle(
        color: AdminColors.forest,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: AdminColors.muted,
      suffixIconColor: AdminColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.sageDeep, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.disabled)
              ? AdminColors.surfaceMuted
              : AdminColors.sageGreen,
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.disabled)
              ? AdminColors.muted
              : Colors.white,
        ),
        // A little lift on hover so the primary action feels tappable.
        elevation: WidgetStateProperty.resolveWith<double>(
          (states) {
            if (states.contains(WidgetState.disabled)) return 0;
            return states.contains(WidgetState.hovered) ? 3 : 1.5;
          },
        ),
        shadowColor: WidgetStatePropertyAll(AdminColors.shadowStrong),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.18),
        ),
        minimumSize: WidgetStatePropertyAll(const Size(0, 46)),
        padding: WidgetStatePropertyAll(
          const EdgeInsets.symmetric(horizontal: 20),
        ),
        textStyle: WidgetStatePropertyAll(
          const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.forest,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        side: const BorderSide(color: AdminColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AdminColors.forest,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AdminColors.surfaceAlt,
      selectedColor: AdminColors.sage,
      disabledColor: AdminColors.surfaceMuted,
      side: const BorderSide(color: AdminColors.border),
      labelStyle: const TextStyle(
        color: AdminColors.text,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AdminColors.ink,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AdminColors.ink,
      contentTextStyle: const TextStyle(color: AdminColors.cream),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AdminColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AdminColors.border),
      ),
    ),
    iconTheme: const IconThemeData(color: AdminColors.text, size: 20),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AdminColors.forest,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AdminColors.surface
            : AdminColors.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AdminColors.forest
            : AdminColors.surfaceMuted,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AdminColors.forest
            : AdminColors.borderStrong,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AdminColors.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(color: AdminColors.cream, fontSize: 12),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AdminColors.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AdminColors.border),
          ),
        ),
      ),
    ),
  );
}
