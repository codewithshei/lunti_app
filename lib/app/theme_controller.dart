import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active [ThemeMode], persists it, and notifies listeners so the
/// whole app repaints instantly — no restart, no full reload.
///
/// The app only offers light and dark in the UI, but the controller speaks
/// [ThemeMode] so a "follow the system" option can be added without touching
/// the widget tree again.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'lunti.themeMode';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  /// Whether the dark palette is active. The Profile tile binds to this.
  bool get isDark => _mode == ThemeMode.dark;

  /// Restores the saved selection. Call once from `main()` before `runApp`.
  ///
  /// Failures are non-fatal: a missing preference or an unavailable platform
  /// store leaves the app on the light palette.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = _modeFromStorage(prefs.getString(_prefsKey));
    } catch (error) {
      debugPrint('Could not read the saved theme: $error');
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (error) {
      debugPrint('Could not save the theme: $error');
    }
  }

  /// Toggles between the light and dark palettes.
  Future<void> setDark(bool dark) =>
      setMode(dark ? ThemeMode.dark : ThemeMode.light);

  ThemeMode _modeFromStorage(String? stored) {
    return switch (stored) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  /// Test helper: widget tests never call [load], so they start on the light
  /// palette unless a previous test changed it.
  @visibleForTesting
  void resetForTest() {
    _mode = ThemeMode.light;
    notifyListeners();
  }
}
