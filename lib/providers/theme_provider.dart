import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/hive_helper.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final showNavLabelsProvider = StateNotifierProvider<ShowNavLabelsNotifier, bool>(
  (_) => ShowNavLabelsNotifier(),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = HiveHelper.settings.get('theme_mode') as String?;
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await HiveHelper.settings.put('theme_mode', value);
  }

  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      await setMode(ThemeMode.light);
    } else if (state == ThemeMode.light) {
      await setMode(ThemeMode.system);
    } else {
      await setMode(ThemeMode.dark);
    }
  }

  bool get isDark => state == ThemeMode.dark;
}

class ShowNavLabelsNotifier extends StateNotifier<bool> {
  ShowNavLabelsNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final stored = HiveHelper.settings.get('show_nav_labels') as bool? ?? true;
    state = stored;
  }

  Future<void> setShowNavLabels(bool value) async {
    state = value;
    await HiveHelper.settings.put('show_nav_labels', value);
  }
}
