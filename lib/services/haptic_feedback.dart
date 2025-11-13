import 'package:vibration/vibration.dart';

enum HapticType {
  light,      // Single light vibration
  medium,     // Medium vibration
  heavy,      // Heavy vibration
  success,    // Success pattern (double vibration)
  completion, // Completion pattern (triple vibration)
  error,      // Error pattern (long vibration)
}

class HapticFeedbackService {
  static Future<bool> get hasVibrator async {
    return await Vibration.hasVibrator() ?? false;
  }

  static Future<bool> get hasAmplitudeControl async {
    return await Vibration.hasAmplitudeControl() ?? false;
  }

  static Future<void> vibrate(HapticType type) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == false) return;

    switch (type) {
      case HapticType.light:
        await Vibration.vibrate(duration: 50);
        break;

      case HapticType.medium:
        await Vibration.vibrate(duration: 100);
        break;

      case HapticType.heavy:
        await Vibration.vibrate(duration: 200);
        break;

      case HapticType.success:
        await Vibration.vibrate(pattern: [0, 50, 50, 50]);
        break;

      case HapticType.completion:
        await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
        break;

      case HapticType.error:
        await Vibration.vibrate(duration: 500);
        break;
    }
  }

  static Future<void> beadCount() async {
    final deviceHasVibrator = await hasVibrator;
    if (deviceHasVibrator) {
      await Vibration.vibrate(duration: 30);
    }
  }

  static Future<void> mantraComplete() async {
    final deviceHasVibrator = await hasVibrator;
    if (deviceHasVibrator) {
      await Vibration.vibrate(pattern: [0, 50, 50, 50]);
    }
  }

  static Future<void> sessionComplete() async {
    final deviceHasVibrator = await hasVibrator;
    if (deviceHasVibrator) {
      await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
    }
  }

  static Future<void> buttonPress() async {
    final deviceHasVibrator = await hasVibrator;
    if (deviceHasVibrator) {
      await Vibration.vibrate(duration: 20);
    }
  }

  static Future<void> error() async {
    final deviceHasVibrator = await hasVibrator;
    if (deviceHasVibrator) {
      await Vibration.vibrate(duration: 300);
    }
  }
}
