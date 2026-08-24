import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'commitment.g.dart';

/// A sankalpa: a resolve to complete a set number of repetitions of one
/// mantra, usually over weeks or months. Distinct from a daily target, which
/// resets every morning — this one accumulates until it's finished.
@HiveType(typeId: 4)
class Commitment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String mantraId;

  /// Total repetitions vowed.
  @HiveField(2)
  final int targetCount;

  /// Only practice from this moment on counts toward the vow.
  @HiveField(3)
  final DateTime startDate;

  /// Optional date the practitioner intends to finish by.
  @HiveField(4)
  final DateTime? deadline;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime? completedAt;

  /// Free-text intention, e.g. "for my mother's health".
  @HiveField(7)
  final String? intention;

  Commitment({
    required this.id,
    required this.mantraId,
    required this.targetCount,
    required this.startDate,
    required this.createdAt,
    this.deadline,
    this.completedAt,
    this.intention,
  });

  factory Commitment.create({
    required String mantraId,
    required int targetCount,
    DateTime? startDate,
    DateTime? deadline,
    String? intention,
  }) {
    final now = DateTime.now();
    return Commitment(
      id: const Uuid().v4(),
      mantraId: mantraId,
      targetCount: targetCount,
      startDate: startDate ?? now,
      createdAt: now,
      deadline: deadline,
      intention: intention,
    );
  }

  Commitment copyWith({
    int? targetCount,
    DateTime? deadline,
    DateTime? completedAt,
    String? intention,
    bool clearDeadline = false,
    bool clearCompletedAt = false,
  }) {
    return Commitment(
      id: id,
      mantraId: mantraId,
      targetCount: targetCount ?? this.targetCount,
      startDate: startDate,
      createdAt: createdAt,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      intention: intention ?? this.intention,
    );
  }

  bool get isComplete => completedAt != null;

  int get daysElapsed =>
      DateTime.now().difference(startDate).inDays.clamp(0, 1 << 30) + 1;

  int? get daysRemaining {
    final deadline = this.deadline;
    if (deadline == null) return null;
    return deadline.difference(DateTime.now()).inDays;
  }
}

/// A commitment paired with the practice counted against it.
class CommitmentProgress {
  final Commitment commitment;
  final int completedCount;

  const CommitmentProgress({
    required this.commitment,
    required this.completedCount,
  });

  int get remaining =>
      (commitment.targetCount - completedCount).clamp(0, 1 << 30);

  double get fraction => commitment.targetCount > 0
      ? (completedCount / commitment.targetCount).clamp(0.0, 1.0)
      : 0.0;

  /// Average repetitions per day since the vow began.
  double get pacePerDay => completedCount / commitment.daysElapsed;

  /// Days to finish at the current pace, or null before enough practice to
  /// estimate from.
  int? get projectedDaysRemaining {
    if (remaining == 0) return 0;
    final pace = pacePerDay;
    if (pace <= 0) return null;
    return (remaining / pace).ceil();
  }

  DateTime? get projectedFinishDate {
    final days = projectedDaysRemaining;
    if (days == null) return null;
    return DateTime.now().add(Duration(days: days));
  }

  /// Repetitions per day needed to hit the deadline, or null without one.
  double? get requiredPacePerDay {
    final days = commitment.daysRemaining;
    if (days == null) return null;
    if (days <= 0) return remaining.toDouble();
    return remaining / days;
  }

  /// How far ahead (positive) or behind (negative) the deadline pace.
  /// Null when there's no deadline to be measured against.
  int? get beadsAheadOfSchedule {
    final deadline = commitment.deadline;
    if (deadline == null) return null;

    final totalDays = deadline.difference(commitment.startDate).inDays + 1;
    if (totalDays <= 0) return completedCount - commitment.targetCount;

    final expected =
        commitment.targetCount * (commitment.daysElapsed / totalDays);
    return (completedCount - expected).round();
  }
}
