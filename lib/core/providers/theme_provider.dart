import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';

// Mode tema: light, dark, atau auto (otomatis berdasarkan jam)
enum AppThemeMode { light, dark, auto }

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode_v2';

  @override
  AppThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    if (saved == 'dark') return AppThemeMode.dark;
    if (saved == 'auto') return AppThemeMode.auto;
    return AppThemeMode.light;
  }

  Future<void> setMode(AppThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = mode;
    await prefs.setString(_key, mode.name);
  }

  /// Siklus toggle: Light → Dark → Auto → Light
  Future<void> toggle() async {
    switch (state) {
      case AppThemeMode.light:
        await setMode(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        await setMode(AppThemeMode.auto);
        break;
      case AppThemeMode.auto:
        await setMode(AppThemeMode.light);
        break;
    }
  }

  /// Konversi ke ThemeMode Flutter (digunakan MaterialApp)
  /// Mode auto: light pukul 06:00–17:59, dark pukul 18:00–05:59
  ThemeMode get flutterThemeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.auto:
        final hour = DateTime.now().hour;
        // Terang jam 06:00 pagi s/d 17:59 sore, gelap sisanya
        return (hour >= 6 && hour < 18) ? ThemeMode.light : ThemeMode.dark;
    }
  }

  bool get isDark => flutterThemeMode == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});
