import 'package:vibration/vibration.dart';

enum HapticType {
  light, // Single light vibration
  medium, // Medium vibration
  heavy, // Heavy vibration
  success, // Success pattern (double vibration)
  completion, // Completion pattern (triple vibration)
  error, // Error pattern (long vibration)
}

class HapticFeedbackService {
  static bool _hasVibrator = false;
  static bool _initialized = false;

  /// Queries the device once and caches the result. Called from `main()` so
  /// that counting taps never pay for a platform channel round-trip.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      _hasVibrator = await Vibration.hasVibrator();
    } catch (_) {
      _hasVibrator = false;
    }
    _initialized = true;
  }

  static bool get hasVibrator => _hasVibrator;

  static Future<bool> get hasAmplitudeControl async {
    return await Vibration.hasAmplitudeControl();
  }

  static Future<void> _vibrate({int? duration, List<int>? pattern}) async {
    if (!_initialized) await init();
    if (!_hasVibrator) return;
    if (pattern != null) {
      await Vibration.vibrate(pattern: pattern);
    } else if (duration != null) {
      await Vibration.vibrate(duration: duration);
    }
  }

  static Future<void> vibrate(HapticType type) async {
    switch (type) {
      case HapticType.light:
        return _vibrate(duration: 50);
      case HapticType.medium:
        return _vibrate(duration: 100);
      case HapticType.heavy:
        return _vibrate(duration: 200);
      case HapticType.success:
        return _vibrate(pattern: [0, 50, 50, 50]);
      case HapticType.completion:
        return _vibrate(pattern: [0, 100, 50, 100, 50, 100]);
      case HapticType.error:
        return _vibrate(duration: 500);
    }
  }

  static Future<void> beadCount() => _vibrate(duration: 30);

  static Future<void> mantraComplete() => _vibrate(pattern: [0, 50, 50, 50]);

  static Future<void> sessionComplete() =>
      _vibrate(pattern: [0, 100, 50, 100, 50, 100]);

  static Future<void> buttonPress() => _vibrate(duration: 20);

  static Future<void> error() => _vibrate(duration: 300);
}
