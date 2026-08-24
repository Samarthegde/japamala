import 'package:hive/hive.dart';

part 'daily_completion.g.dart';

@HiveType(typeId: 2)
class DailyCompletion extends HiveObject {
  @HiveField(0)
  final String id; // Format: "mantraId_date"

  @HiveField(1)
  final String mantraId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final bool completed;

  @HiveField(4)
  final DateTime? completionTime;

  DailyCompletion({
    required this.id,
    required this.mantraId,
    required this.date,
    required this.completed,
    this.completionTime,
  });

  /// Deterministic key for a mantra on a given practice day, so a completion
  /// can be looked up directly instead of scanning the box.
  static String idFor(String mantraId, DateTime date) =>
      '${mantraId}_${date.year}-${date.month}-${date.day}';

  factory DailyCompletion.create({
    required String mantraId,
    required DateTime date,
    required bool completed,
    DateTime? completionTime,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    return DailyCompletion(
      id: idFor(mantraId, day),
      mantraId: mantraId,
      date: day, // Store date-only, so lookups don't have to strip the time
      completed: completed,
      completionTime: completionTime,
    );
  }

  // Get date-only (without time) for comparison
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);
}
