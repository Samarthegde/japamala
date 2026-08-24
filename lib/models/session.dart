import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'session.g.dart';

/// What kind of practice a session records. Stored as a string so an unknown
/// value from a newer version degrades to japa rather than crashing.
enum SessionKind { japa, breathing, meditation }

extension SessionKindExtension on SessionKind {
  String get label {
    switch (this) {
      case SessionKind.japa:
        return 'Japa';
      case SessionKind.breathing:
        return 'Breathing';
      case SessionKind.meditation:
        return 'Meditation';
    }
  }

  static SessionKind parse(String? value) {
    for (final kind in SessionKind.values) {
      if (kind.name == value) return kind;
    }
    return SessionKind.japa; // Sessions recorded before kinds existed
  }
}

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  final String id;

  /// The mantra counted. Empty for practice that isn't tied to one.
  @HiveField(1)
  final String mantraId;

  /// Beads for japa, cycles for breathing, unused for meditation.
  @HiveField(2)
  final int count;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final bool completed;

  /// Null on sessions written before other kinds of practice were recorded.
  @HiveField(6)
  final String? kindName;

  /// Display name for practice with no mantra behind it, e.g. "Box Breathing".
  @HiveField(7)
  final String? title;

  Session({
    required this.id,
    required this.mantraId,
    required this.count,
    required this.startTime,
    required this.endTime,
    required this.completed,
    this.kindName,
    this.title,
  });

  factory Session.create({
    required String mantraId,
    required int count,
    required DateTime startTime,
    required DateTime endTime,
    required bool completed,
    SessionKind kind = SessionKind.japa,
    String? title,
  }) {
    return Session(
      id: const Uuid().v4(),
      mantraId: mantraId,
      count: count,
      startTime: startTime,
      endTime: endTime,
      completed: completed,
      kindName: kind.name,
      title: title,
    );
  }

  /// A guided breathing round. [count] is cycles completed.
  factory Session.breathing({
    required String patternId,
    required String patternName,
    required int cycles,
    required DateTime startTime,
    required DateTime endTime,
    required bool completed,
  }) {
    return Session.create(
      mantraId: '',
      count: cycles,
      startTime: startTime,
      endTime: endTime,
      completed: completed,
      kind: SessionKind.breathing,
      title: patternName,
    );
  }

  /// A silent sitting. Only the duration matters.
  factory Session.meditation({
    required DateTime startTime,
    required DateTime endTime,
    required bool completed,
  }) {
    return Session.create(
      mantraId: '',
      count: 0,
      startTime: startTime,
      endTime: endTime,
      completed: completed,
      kind: SessionKind.meditation,
      title: 'Meditation',
    );
  }

  SessionKind get kind => SessionKindExtension.parse(kindName);

  Duration get duration => endTime.difference(startTime);

  /// How the count reads for this kind of practice; empty when it has none.
  String get countLabel {
    switch (kind) {
      case SessionKind.japa:
        return '$count ${count == 1 ? 'bead' : 'beads'}';
      case SessionKind.breathing:
        return '$count ${count == 1 ? 'cycle' : 'cycles'}';
      case SessionKind.meditation:
        return '';
    }
  }
}
