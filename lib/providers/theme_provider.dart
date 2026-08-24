import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// How beads are counted on the counter screen.
enum CounterGesture {
  /// Drag down the screen to pull each bead, as on a real mala.
  swipe,

  /// Tap anywhere to count.
  tap,
}

extension CounterGestureExtension on CounterGesture {
  String get label {
    switch (this) {
      case CounterGesture.swipe:
        return 'Swipe the mala';
      case CounterGesture.tap:
        return 'Tap to count';
    }
  }

  String get hint {
    switch (this) {
      case CounterGesture.swipe:
        return 'Drag down to pull each bead. Tap to show controls.';
      case CounterGesture.tap:
        return 'Tap anywhere on the counter to count a bead.';
    }
  }
}

enum AppTheme {
  spiritualBrown, // Default warm brown
  sereneBlue, // Peaceful blue tones
  tranquilGreen, // Calming green tones
  sacredPurple, // Spiritual purple tones
  goldenLight, // Warm golden tones
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
  Box? _settingsBox;
  Future<void>? _ready;

  AppTheme _currentTheme = AppTheme.spiritualBrown;
  ThemeMode _themeMode = ThemeMode.system;
  bool _hapticEnabled = true;
  bool _soundEnabled = true;
  bool _keepScreenOn = true;
  bool _volumeKeyCounting = true;
  CounterGesture _counterGesture = CounterGesture.swipe;

  /// Cleared once the user has pulled their first bead, so the coach mark
  /// shows exactly once.
  bool _seenSwipeCoach = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 6, minute: 0);

  AppTheme get currentTheme => _currentTheme;
  ThemeMode get themeMode => _themeMode;
  bool get hapticEnabled => _hapticEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get keepScreenOn => _keepScreenOn;
  bool get volumeKeyCounting => _volumeKeyCounting;
  CounterGesture get counterGesture => _counterGesture;
  bool get seenSwipeCoach => _seenSwipeCoach;
  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;

  ThemeData get lightThemeData => _themeDataFor(_currentTheme.lightColorScheme);

  ThemeData get darkThemeData => _themeDataFor(_currentTheme.darkColorScheme);

  ThemeData _themeDataFor(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: colorScheme.brightness,
    );
  }

  /// Safe to call more than once; the box is only opened on the first call.
  Future<void> init() => _ready ??= _open();

  Future<void> _open() async {
    try {
      final box = await Hive.openBox('settings');
      _settingsBox = box;

      _currentTheme =
          AppTheme.values[(box.get('theme', defaultValue: 0) as int).clamp(
            0,
            AppTheme.values.length - 1,
          )];
      _themeMode = _readThemeMode(box);
      _hapticEnabled = box.get('hapticEnabled', defaultValue: true);
      _soundEnabled = box.get('soundEnabled', defaultValue: true);
      _keepScreenOn = box.get('keepScreenOn', defaultValue: true);
      _volumeKeyCounting = box.get('volumeKeyCounting', defaultValue: true);
      _counterGesture =
          CounterGesture.values[(box.get('counterGesture', defaultValue: 0)
                  as int)
              .clamp(0, CounterGesture.values.length - 1)];
      _seenSwipeCoach = box.get('seenSwipeCoach', defaultValue: false);
      _reminderEnabled = box.get('reminderEnabled', defaultValue: false);
      _reminderTime = TimeOfDay(
        hour: (box.get('reminderHour', defaultValue: 6) as int).clamp(0, 23),
        minute: (box.get('reminderMinute', defaultValue: 0) as int).clamp(
          0,
          59,
        ),
      );
    } catch (e) {
      // Settings are all defaultable, so a failure here degrades to defaults
      // rather than taking the app down.
      debugPrint('Error initializing ThemeProvider: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Falls back to the older boolean setting so an upgrade keeps the user's
  /// existing choice instead of silently jumping to system.
  ThemeMode _readThemeMode(Box box) {
    final stored = box.get('themeMode');
    if (stored is int && stored >= 0 && stored < ThemeMode.values.length) {
      return ThemeMode.values[stored];
    }
    final legacyDarkMode = box.get('darkMode');
    if (legacyDarkMode is bool) {
      return legacyDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
    return ThemeMode.system;
  }

  Future<void> _put(String key, Object? value) async {
    try {
      await _settingsBox?.put(key, value);
    } catch (e) {
      debugPrint('Could not save setting "$key": $e');
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    await _put('theme', theme.index);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _put('themeMode', mode.index);
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    notifyListeners();
    await _put('hapticEnabled', enabled);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    await _put('soundEnabled', enabled);
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    _keepScreenOn = enabled;
    notifyListeners();
    await _put('keepScreenOn', enabled);
  }

  Future<void> setVolumeKeyCounting(bool enabled) async {
    _volumeKeyCounting = enabled;
    notifyListeners();
    await _put('volumeKeyCounting', enabled);
  }

  Future<void> setCounterGesture(CounterGesture gesture) async {
    _counterGesture = gesture;
    notifyListeners();
    await _put('counterGesture', gesture.index);
  }

  Future<void> markSwipeCoachSeen() async {
    if (_seenSwipeCoach) return;
    _seenSwipeCoach = true;
    notifyListeners();
    await _put('seenSwipeCoach', true);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    notifyListeners();
    await _put('reminderEnabled', enabled);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    await _put('reminderHour', time.hour);
    await _put('reminderMinute', time.minute);
  }
}
