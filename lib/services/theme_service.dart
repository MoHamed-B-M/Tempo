import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _navLabelsKey = 'show_nav_labels';

  ThemeMode _mode = ThemeMode.dark;
  bool _showNavLabels = true;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get showNavLabels => _showNavLabels;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    switch (stored) {
      case 'light':
        _mode = ThemeMode.light;
      case 'system':
        _mode = ThemeMode.system;
      default:
        _mode = ThemeMode.dark;
    }
    _showNavLabels = prefs.getBool(_navLabelsKey) ?? true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await prefs.setString(_themeKey, value);
  }

  void toggle() {
    if (_mode == ThemeMode.dark) {
      setMode(ThemeMode.light);
    } else if (_mode == ThemeMode.light) {
      setMode(ThemeMode.system);
    } else {
      setMode(ThemeMode.dark);
    }
  }

  Future<void> setShowNavLabels(bool value) async {
    _showNavLabels = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_navLabelsKey, value);
  }
}
