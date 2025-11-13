import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'session.g.dart';

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String mantraId;

  @HiveField(2)
  final int count;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final bool completed;

  Session({
    required this.id,
    required this.mantraId,
    required this.count,
    required this.startTime,
    required this.endTime,
    required this.completed,
  });

  factory Session.create({
    required String mantraId,
    required int count,
    required DateTime startTime,
    required DateTime endTime,
    required bool completed,
  }) {
    return Session(
      id: const Uuid().v4(),
      mantraId: mantraId,
      count: count,
      startTime: startTime,
      endTime: endTime,
      completed: completed,
    );
  }

  Duration get duration => endTime.difference(startTime);
}
