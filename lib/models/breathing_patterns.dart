enum BreathingPattern {
  fourSevenEight, // 4-7-8 breathing
  boxBreathing,   // 4-4-4-4 box breathing
  peaceful,       // Slow, natural breathing
}

extension BreathingPatternExtension on BreathingPattern {
  String get displayName {
    switch (this) {
      case BreathingPattern.fourSevenEight:
        return '4-7-8 Breathing';
      case BreathingPattern.boxBreathing:
        return 'Box Breathing';
      case BreathingPattern.peaceful:
        return 'Peaceful Breathing';
    }
  }

  String get description {
    switch (this) {
      case BreathingPattern.fourSevenEight:
        return 'Inhale for 4 seconds, hold for 7 seconds, exhale for 8 seconds. Excellent for relaxation.';
      case BreathingPattern.boxBreathing:
        return 'Inhale for 4, hold for 4, exhale for 4, hold for 4. Used by Navy SEALs for stress control.';
      case BreathingPattern.peaceful:
        return 'Natural breathing rhythm. Focus on the gentle rise and fall of your breath.';
    }
  }

  Map<String, int> get phases {
    switch (this) {
      case BreathingPattern.fourSevenEight:
        return {'inhale': 4, 'hold': 7, 'exhale': 8, 'pause': 0};
      case BreathingPattern.boxBreathing:
        return {'inhale': 4, 'hold': 4, 'exhale': 4, 'pause': 4};
      case BreathingPattern.peaceful:
        return {'inhale': 4, 'hold': 1, 'exhale': 6, 'pause': 2};
    }
  }
}
