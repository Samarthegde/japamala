import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 3)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? mantraName; // Optional: link to specific mantra practice

  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.createdAt,
    this.mantraName,
  });

  factory JournalEntry.create({
    required DateTime date,
    required String content,
    String? mantraName,
  }) {
    return JournalEntry(
      id: '${date.year}-${date.month}-${date.day}_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime(date.year, date.month, date.day), // Store date-only
      content: content,
      createdAt: DateTime.now(),
      mantraName: mantraName,
    );
  }

  // Get date-only key for grouping entries by day
  String get dateKey => '${date.year}-${date.month}-${date.day}';
}
