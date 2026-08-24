import 'package:flutter/material.dart';

/// The four positions of a breath cycle. Any pattern here is expressed as
/// these four, with zero-length phases simply skipped.
enum BreathPhase { inhale, holdIn, exhale, holdOut }

extension BreathPhaseExtension on BreathPhase {
  String get label {
    switch (this) {
      case BreathPhase.inhale:
        return 'Inhale';
      case BreathPhase.holdIn:
        return 'Hold';
      case BreathPhase.exhale:
        return 'Exhale';
      case BreathPhase.holdOut:
        return 'Pause';
    }
  }
}

enum BreathingLevel { beginner, intermediate, advanced }

extension BreathingLevelExtension on BreathingLevel {
  String get label {
    switch (this) {
      case BreathingLevel.beginner:
        return 'Beginner';
      case BreathingLevel.intermediate:
        return 'Intermediate';
      case BreathingLevel.advanced:
        return 'Advanced';
    }
  }

  Color get color {
    switch (this) {
      case BreathingLevel.beginner:
        return Colors.green;
      case BreathingLevel.intermediate:
        return Colors.orange;
      case BreathingLevel.advanced:
        return Colors.deepPurple;
    }
  }
}

/// Grouping by what the pattern is for, which is how people actually choose.
enum BreathingGoal { calm, focus, energise, sleep }

extension BreathingGoalExtension on BreathingGoal {
  String get label {
    switch (this) {
      case BreathingGoal.calm:
        return 'Calm';
      case BreathingGoal.focus:
        return 'Focus';
      case BreathingGoal.energise:
        return 'Energise';
      case BreathingGoal.sleep:
        return 'Sleep';
    }
  }

  IconData get icon {
    switch (this) {
      case BreathingGoal.calm:
        return Icons.spa;
      case BreathingGoal.focus:
        return Icons.center_focus_strong;
      case BreathingGoal.energise:
        return Icons.bolt;
      case BreathingGoal.sleep:
        return Icons.nightlight_round;
    }
  }
}

/// Durations are milliseconds, not whole seconds: coherent breathing is 5.5
/// seconds a side, which the old integer-seconds model couldn't express.
@immutable
class BreathingPattern {
  final String id;
  final String name;

  /// Traditional name, where the pattern has one.
  final String? sanskritName;

  final String description;

  /// What it's good for, in one line.
  final String benefit;

  /// How to actually do it — the part a diagram can't convey.
  final String technique;

  final Duration inhale;
  final Duration holdIn;
  final Duration exhale;
  final Duration holdOut;

  /// Nadi Shodhana alternates sides each cycle; everything else doesn't.
  final bool alternateNostrils;

  /// Per-phase coaching that overrides the generic wording.
  final Map<BreathPhase, String> cues;

  final int defaultCycles;
  final BreathingLevel level;
  final BreathingGoal goal;
  final IconData icon;

  const BreathingPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.benefit,
    required this.technique,
    required this.inhale,
    required this.exhale,
    required this.defaultCycles,
    required this.level,
    required this.goal,
    required this.icon,
    this.sanskritName,
    this.holdIn = Duration.zero,
    this.holdOut = Duration.zero,
    this.alternateNostrils = false,
    this.cues = const {},
  });

  Duration durationOf(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return inhale;
      case BreathPhase.holdIn:
        return holdIn;
      case BreathPhase.exhale:
        return exhale;
      case BreathPhase.holdOut:
        return holdOut;
    }
  }

  /// Phases with a non-zero duration, in cycle order.
  List<BreathPhase> get activePhases => BreathPhase.values
      .where((phase) => durationOf(phase) > Duration.zero)
      .toList();

  Duration get cycleDuration => inhale + holdIn + exhale + holdOut;

  Duration estimatedDuration(int cycles) => cycleDuration * cycles;

  /// "4-7-8" style summary, using the phases that actually run.
  String get rhythm =>
      activePhases.map((phase) => _formatSeconds(durationOf(phase))).join('-');

  String cueFor(BreathPhase phase) => cues[phase] ?? _defaultCue(phase);

  String _defaultCue(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return 'Breathe in slowly';
      case BreathPhase.holdIn:
        return 'Hold your breath';
      case BreathPhase.exhale:
        return 'Breathe out slowly';
      case BreathPhase.holdOut:
        return 'Rest, lungs empty';
    }
  }

  static String _formatSeconds(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return seconds == seconds.roundToDouble()
        ? '${seconds.round()}'
        : seconds.toStringAsFixed(1);
  }

  static const List<BreathingPattern> all = [
    BreathingPattern(
      id: 'coherent',
      name: 'Coherent Breathing',
      description: 'Five and a half seconds in, five and a half out.',
      benefit: 'Settles heart rate and steadies the nervous system.',
      technique:
          'Breathe evenly through the nose, with no pause at either end. The '
          'aim is a smooth, unbroken wave rather than distinct steps. This is '
          'the rate at which heart rhythm and breath fall into step.',
      inhale: Duration(milliseconds: 5500),
      exhale: Duration(milliseconds: 5500),
      defaultCycles: 20,
      level: BreathingLevel.beginner,
      goal: BreathingGoal.calm,
      icon: Icons.waves,
    ),
    BreathingPattern(
      id: 'belly',
      name: 'Deep Belly Breathing',
      sanskritName: 'Adham Pranayama',
      description: 'Slow diaphragmatic breathing, exhale longer than inhale.',
      benefit: 'The simplest way to leave a stress response.',
      technique:
          'Rest one hand on your belly. Let it rise as you breathe in and fall '
          'as you breathe out — your chest should barely move. If only your '
          'chest is moving, breathe more slowly and less deeply.',
      inhale: Duration(seconds: 4),
      exhale: Duration(seconds: 6),
      defaultCycles: 15,
      level: BreathingLevel.beginner,
      goal: BreathingGoal.calm,
      icon: Icons.self_improvement,
      cues: {
        BreathPhase.inhale: 'Let your belly rise',
        BreathPhase.exhale: 'Let your belly fall',
      },
    ),
    BreathingPattern(
      id: 'extended-exhale',
      name: 'Extended Exhale',
      description: 'Exhale twice as long as the inhale.',
      benefit:
          'A longer out-breath is what actually triggers the calming '
          'response.',
      technique:
          'Breathe in through the nose, then out slowly through slightly '
          'pursed lips, as though cooling a spoonful of soup. Keep the exhale '
          'smooth to the very end rather than letting it collapse.',
      inhale: Duration(seconds: 4),
      exhale: Duration(seconds: 8),
      defaultCycles: 12,
      level: BreathingLevel.beginner,
      goal: BreathingGoal.calm,
      icon: Icons.trending_down,
    ),
    BreathingPattern(
      id: 'box',
      name: 'Box Breathing',
      sanskritName: 'Sama Vritti',
      description: 'Equal counts of four: in, hold, out, hold.',
      benefit: 'Steadies attention under pressure.',
      technique:
          'Keep all four sides equal. Picture tracing the edges of a square, '
          'one edge per phase. If four seconds feels strained, drop to three '
          'and build up.',
      inhale: Duration(seconds: 4),
      holdIn: Duration(seconds: 4),
      exhale: Duration(seconds: 4),
      holdOut: Duration(seconds: 4),
      defaultCycles: 12,
      level: BreathingLevel.intermediate,
      goal: BreathingGoal.focus,
      icon: Icons.crop_square,
    ),
    BreathingPattern(
      id: 'triangle',
      name: 'Triangle Breathing',
      description: 'In, hold, out — three equal sides, no pause at the bottom.',
      benefit: 'A gentler step toward box breathing.',
      technique:
          'Three equal phases with no rest at the end. Easier to sustain than '
          'box breathing because the lungs never sit empty.',
      inhale: Duration(seconds: 4),
      holdIn: Duration(seconds: 4),
      exhale: Duration(seconds: 4),
      defaultCycles: 12,
      level: BreathingLevel.beginner,
      goal: BreathingGoal.focus,
      icon: Icons.change_history,
    ),
    BreathingPattern(
      id: 'four-seven-eight',
      name: '4-7-8 Breathing',
      description: 'In for four, hold for seven, out for eight.',
      benefit: 'Well suited to falling asleep.',
      technique:
          'Rest the tip of your tongue behind your upper front teeth. Inhale '
          'quietly through the nose, then exhale through the mouth with a soft '
          'whoosh. Four cycles is plenty at first — this one is strong.',
      inhale: Duration(seconds: 4),
      holdIn: Duration(seconds: 7),
      exhale: Duration(seconds: 8),
      defaultCycles: 8,
      level: BreathingLevel.intermediate,
      goal: BreathingGoal.sleep,
      icon: Icons.bedtime,
      cues: {BreathPhase.exhale: 'Out through the mouth, softly'},
    ),
    BreathingPattern(
      id: 'peaceful',
      name: 'Peaceful Breathing',
      description: 'An unhurried, natural rhythm.',
      benefit: 'An easy place to start, and a good bridge into meditation.',
      technique:
          'Nothing forced. Follow the gentle rise and fall, and let the breath '
          'find its own depth. Good before japa or seated meditation.',
      inhale: Duration(seconds: 4),
      holdIn: Duration(seconds: 1),
      exhale: Duration(seconds: 6),
      holdOut: Duration(seconds: 2),
      defaultCycles: 15,
      level: BreathingLevel.beginner,
      goal: BreathingGoal.calm,
      icon: Icons.eco,
    ),
    BreathingPattern(
      id: 'nadi-shodhana',
      name: 'Alternate Nostril',
      sanskritName: 'Nadi Shodhana',
      description: 'Breathe through one nostril at a time, switching sides.',
      benefit: 'Traditionally said to balance the two sides of the system.',
      technique:
          'Use the right thumb to close the right nostril and the ring finger '
          'to close the left. Breathe in through the open side, close both to '
          'hold, then release the other side to breathe out. The side you '
          'breathe out of is the side you next breathe in through.',
      inhale: Duration(seconds: 4),
      holdIn: Duration(seconds: 4),
      exhale: Duration(seconds: 4),
      defaultCycles: 12,
      level: BreathingLevel.intermediate,
      goal: BreathingGoal.focus,
      icon: Icons.swap_horiz,
      alternateNostrils: true,
    ),
    BreathingPattern(
      id: 'ujjayi',
      name: 'Ocean Breath',
      sanskritName: 'Ujjayi',
      description: 'Slow breathing with a soft constriction in the throat.',
      benefit: 'The sound gives the mind something to rest on.',
      technique:
          'Narrow the back of the throat slightly, as if fogging a mirror, but '
          'keep the mouth closed. Both in and out breaths make a quiet ocean '
          'sound. Let the sound stay soft — straining defeats it.',
      inhale: Duration(seconds: 5),
      exhale: Duration(seconds: 5),
      defaultCycles: 15,
      level: BreathingLevel.intermediate,
      goal: BreathingGoal.focus,
      icon: Icons.water,
      cues: {
        BreathPhase.inhale: 'In, with a soft ocean sound',
        BreathPhase.exhale: 'Out, with a soft ocean sound',
      },
    ),
    BreathingPattern(
      id: 'bhramari',
      name: 'Humming Bee',
      sanskritName: 'Bhramari',
      description: 'A long humming exhale.',
      benefit: 'The vibration quiets a busy mind quickly.',
      technique:
          'Close your ears with your thumbs and rest your fingers lightly over '
          'your eyes. Breathe in through the nose, then hum steadily all the '
          'way out, keeping the lips closed and teeth slightly apart.',
      inhale: Duration(seconds: 4),
      exhale: Duration(seconds: 8),
      defaultCycles: 10,
      level: BreathingLevel.beginner,
      goal: BreathingGoal.calm,
      icon: Icons.graphic_eq,
      cues: {BreathPhase.exhale: 'Hum all the way out'},
    ),
    BreathingPattern(
      id: 'sitali',
      name: 'Cooling Breath',
      sanskritName: 'Sitali',
      description: 'Inhale across the tongue, exhale through the nose.',
      benefit: 'Cooling — useful in heat, or when irritated.',
      technique:
          'Curl the sides of your tongue into a tube and breathe in through '
          'it; the air feels cool. If your tongue does not curl, press it '
          'behind the teeth and sip air through them instead. Exhale through '
          'the nose.',
      inhale: Duration(seconds: 4),
      holdIn: Duration(seconds: 2),
      exhale: Duration(seconds: 6),
      defaultCycles: 12,
      level: BreathingLevel.intermediate,
      goal: BreathingGoal.calm,
      icon: Icons.ac_unit,
      cues: {
        BreathPhase.inhale: 'Sip cool air across the tongue',
        BreathPhase.exhale: 'Out through the nose',
      },
    ),
    BreathingPattern(
      id: 'energising',
      name: 'Energising Breath',
      description: 'A brisk inhale with a short, active exhale.',
      benefit: 'A lift when you are flagging, without caffeine.',
      technique:
          'Breathe in fully and let the out-breath be quick and light. Stop if '
          'you feel light-headed — this one is stimulating by design, and is '
          'best avoided late in the evening.',
      inhale: Duration(seconds: 2),
      exhale: Duration(seconds: 2),
      defaultCycles: 20,
      level: BreathingLevel.advanced,
      goal: BreathingGoal.energise,
      icon: Icons.bolt,
      cues: {
        BreathPhase.inhale: 'Full breath in',
        BreathPhase.exhale: 'Short breath out',
      },
    ),
  ];

  static BreathingPattern? byId(String id) {
    for (final pattern in all) {
      if (pattern.id == id) return pattern;
    }
    return null;
  }
}
