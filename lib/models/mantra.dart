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

  Mantra({
    required this.id,
    required this.name,
    required this.targetCount,
    this.description,
    required this.createdDate,
    this.currentCount = 0,
    this.isDaily = false,
    this.lastResetDate,
  });

  factory Mantra.create({
    required String name,
    required int targetCount,
    String? description,
    bool isDaily = false,
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
    );
  }

  Mantra copyWith({
    String? name,
    int? targetCount,
    String? description,
    int? currentCount,
    DateTime? lastResetDate,
  }) {
    return Mantra(
      id: id,
      name: name ?? this.name,
      targetCount: targetCount ?? this.targetCount,
      description: description ?? this.description,
      createdDate: createdDate,
      currentCount: currentCount ?? this.currentCount,
      isDaily: isDaily,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  bool get isCompleted => currentCount >= targetCount;

  double get progress => targetCount > 0 ? currentCount / targetCount : 0.0;
}
