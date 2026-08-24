import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'mantra.g.dart';

@HiveType(typeId: 0)
class Mantra extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int targetCount;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final DateTime createdDate;

  @HiveField(5)
  int currentCount;

  @HiveField(6)
  final bool isDaily;

  @HiveField(7)
  DateTime? lastResetDate;

  /// Beads in one mala. Null means plain flat counting, which is what every
  /// mantra created before rounds existed does.
  @HiveField(8)
  final int? beadsPerRound;

  Mantra({
    required this.id,
    required this.name,
    required this.targetCount,
    this.description,
    required this.createdDate,
    this.currentCount = 0,
    this.isDaily = false,
    this.lastResetDate,
    this.beadsPerRound,
  });

  factory Mantra.create({
    required String name,
    required int targetCount,
    String? description,
    bool isDaily = false,
    int? beadsPerRound,
  }) {
    return Mantra(
      id: const Uuid().v4(),
      name: name,
      targetCount: targetCount,
      description: description,
      createdDate: DateTime.now(),
      currentCount: 0,
      isDaily: isDaily,
      lastResetDate: isDaily ? DateTime.now() : null,
      beadsPerRound: beadsPerRound,
    );
  }

  /// [clearDescription] and [clearLastResetDate] exist because a plain
  /// `??` fallback can never set a nullable field back to null — passing
  /// `description: null` would silently keep the old value.
  Mantra copyWith({
    String? name,
    int? targetCount,
    String? description,
    int? currentCount,
    bool? isDaily,
    DateTime? lastResetDate,
    int? beadsPerRound,
    bool clearDescription = false,
    bool clearLastResetDate = false,
    bool clearBeadsPerRound = false,
  }) {
    return Mantra(
      id: id,
      name: name ?? this.name,
      targetCount: targetCount ?? this.targetCount,
      description: clearDescription ? null : (description ?? this.description),
      createdDate: createdDate,
      currentCount: currentCount ?? this.currentCount,
      isDaily: isDaily ?? this.isDaily,
      lastResetDate: clearLastResetDate
          ? null
          : (lastResetDate ?? this.lastResetDate),
      beadsPerRound: clearBeadsPerRound
          ? null
          : (beadsPerRound ?? this.beadsPerRound),
    );
  }

  bool get isCompleted => currentCount >= targetCount;

  double get progress => targetCount > 0 ? currentCount / targetCount : 0.0;

  // --- Mala rounds -----------------------------------------------------------
  // Japa is traditionally counted in malas of 108 beads. Practitioners think
  // in rounds ("five malas today"), not in raw totals.

  /// Whether this mantra is counted in rounds rather than as a flat total.
  bool get usesRounds => (beadsPerRound ?? 0) > 0;

  /// Beads counted so far within the current, unfinished round.
  int get beadsInCurrentRound =>
      usesRounds ? currentCount % beadsPerRound! : currentCount;

  /// Whole malas finished.
  int get completedRounds => usesRounds ? currentCount ~/ beadsPerRound! : 0;

  /// Malas needed to reach the target.
  int get totalRounds => usesRounds ? (targetCount / beadsPerRound!).ceil() : 0;

  /// Progress through the current round, for the counter's inner ring.
  double get roundProgress {
    if (!usesRounds) return progress;
    if (isCompleted) return 1.0;
    return beadsInCurrentRound / beadsPerRound!;
  }

  /// True when [currentCount] sits exactly on a round boundary — the moment a
  /// mala is finished and the bell should sound.
  bool get isOnRoundBoundary =>
      usesRounds && currentCount > 0 && currentCount % beadsPerRound! == 0;
}
