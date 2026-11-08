import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lunti_app/app/app_theme.dart';
import 'package:lunti_app/app/theme_controller.dart';
import 'package:lunti_app/main.dart';

/// WCAG relative-luminance contrast between two opaque colours.
double contrastRatio(Color a, Color b) {
  double luminance(Color c) {
    double channel(double s) {
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  final la = luminance(a);
  final lb = luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ThemeController.instance.resetForTest();
  });

  testWidgets('the Profile switch repaints the whole app', (tester) async {
    await tester.pumpWidget(const LuntiApp());
    await tester.pumpAndSettle();

    Color scaffoldColor() =>
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor!;

    expect(scaffoldColor(), LuntiPalette.light.background);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dark Mode'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(ThemeController.instance.isDark, isTrue);
    expect(scaffoldColor(), LuntiPalette.dark.background);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  test('the selection is written to SharedPreferences', () async {
    await ThemeController.instance.setDark(true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lunti.themeMode'), 'dark');
  });

  test('load restores a saved selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lunti.themeMode': 'dark',
    });
    await ThemeController.instance.load();
    expect(ThemeController.instance.mode, ThemeMode.dark);
  });

  test('an unknown or missing preference falls back to light', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lunti.themeMode': 'neon',
    });
    await ThemeController.instance.load();
    expect(ThemeController.instance.mode, ThemeMode.light);
  });

  test('the dark palette keeps body copy at WCAG AA', () {
    final dark = LuntiPalette.dark;
    // Body copy sits on the card surface, not the scaffold background.
    expect(contrastRatio(dark.textMuted, dark.surface), greaterThan(4.5));
    expect(contrastRatio(dark.text, dark.surface), greaterThan(4.5));
    expect(contrastRatio(dark.textMuted, dark.background), greaterThan(4.5));
  });
}
