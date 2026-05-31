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
    if (stored == 'light') {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    _showNavLabels = prefs.getBool(_navLabelsKey) ?? true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  void toggle() {
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setShowNavLabels(bool value) async {
    _showNavLabels = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_navLabelsKey, value);
  }
}
