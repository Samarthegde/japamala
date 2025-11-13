import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppTheme {
  spiritualBrown, // Default warm brown
  sereneBlue,     // Peaceful blue tones
  tranquilGreen,  // Calming green tones
  sacredPurple,   // Spiritual purple tones
  goldenLight,    // Warm golden tones
}

extension AppThemeExtension on AppTheme {
  String get displayName {
    switch (this) {
      case AppTheme.spiritualBrown:
        return 'Spiritual Brown';
      case AppTheme.sereneBlue:
        return 'Serene Blue';
      case AppTheme.tranquilGreen:
        return 'Tranquil Green';
      case AppTheme.sacredPurple:
        return 'Sacred Purple';
      case AppTheme.goldenLight:
        return 'Golden Light';
    }
  }

  ColorScheme get lightColorScheme {
    switch (this) {
      case AppTheme.spiritualBrown:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5A3C),
          brightness: Brightness.light,
        );
      case AppTheme.sereneBlue:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        );
      case AppTheme.tranquilGreen:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B9B7A),
          brightness: Brightness.light,
        );
      case AppTheme.sacredPurple:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B68EE),
          brightness: Brightness.light,
        );
      case AppTheme.goldenLight:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.light,
        );
    }
  }

  ColorScheme get darkColorScheme {
    switch (this) {
      case AppTheme.spiritualBrown:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5A3C),
          brightness: Brightness.dark,
        );
      case AppTheme.sereneBlue:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.dark,
        );
      case AppTheme.tranquilGreen:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B9B7A),
          brightness: Brightness.dark,
        );
      case AppTheme.sacredPurple:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B68EE),
          brightness: Brightness.dark,
        );
      case AppTheme.goldenLight:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
        );
    }
  }
}

class ThemeProvider with ChangeNotifier {
  late Box _settingsBox;
  AppTheme _currentTheme = AppTheme.spiritualBrown;
  bool _isDarkMode = false;
  bool _hapticEnabled = true;

  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;
  bool get hapticEnabled => _hapticEnabled;

  ThemeData get currentThemeData {
    final colorScheme = _isDarkMode
        ? _currentTheme.darkColorScheme
        : _currentTheme.lightColorScheme;

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    );
  }

  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _currentTheme = AppTheme.values[_settingsBox.get('theme', defaultValue: 0)];
    _isDarkMode = _settingsBox.get('darkMode', defaultValue: false);
    _hapticEnabled = _settingsBox.get('hapticEnabled', defaultValue: true);
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _settingsBox.put('theme', theme.index);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _settingsBox.put('darkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    await _settingsBox.put('hapticEnabled', _hapticEnabled);
    notifyListeners();
  }
}
