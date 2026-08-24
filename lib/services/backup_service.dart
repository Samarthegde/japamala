import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/commitment.dart';
import '../models/daily_completion.dart';
import '../models/journal_entry.dart';
import '../models/mantra.dart';
import '../models/session.dart';

/// Exports and restores everything the app stores. All practice data lives on
/// one device, so without this a lost phone loses every record.
class BackupService {
  /// Bumped when the shape changes, so a future version can migrate rather
  /// than misread an old file.
  static const int formatVersion = 1;

  static Future<Map<String, dynamic>> buildBackup() async {
    final mantras = await Hive.openBox<Mantra>('mantras');
    final sessions = await Hive.openBox<Session>('sessions');
    final completions = await Hive.openBox<DailyCompletion>(
      'daily_completions',
    );
    final journal = await Hive.openBox<JournalEntry>('journal_entries');
    final commitments = await Hive.openBox<Commitment>('commitments');

    return {
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'mantras': mantras.values.map(_mantraToJson).toList(),
      'sessions': sessions.values.map(_sessionToJson).toList(),
      'completions': completions.values.map(_completionToJson).toList(),
      'journal': journal.values.map(_journalToJson).toList(),
      'commitments': commitments.values.map(_commitmentToJson).toList(),
    };
  }

  /// Writes the backup to a file and returns it, ready to be shared.
  static Future<File> exportToFile() async {
    final backup = await buildBackup();
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${directory.path}/japamala-backup-$stamp.json');
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );
  }

  /// Merges a backup into the current data. Existing entries with the same id
  /// are overwritten; anything not in the file is left alone, so restoring
  /// never silently deletes practice history.
  static Future<BackupSummary> restore(String jsonContents) async {
    final decoded = jsonDecode(jsonContents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('That file is not a Japamala backup.');
    }

    final version = decoded['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw FormatException(
        'This backup was made by a newer version of Japamala (format '
        '$version). Update the app and try again.',
      );
    }

    final mantras = await Hive.openBox<Mantra>('mantras');
    final sessions = await Hive.openBox<Session>('sessions');
    final completions = await Hive.openBox<DailyCompletion>(
      'daily_completions',
    );
    final journal = await Hive.openBox<JournalEntry>('journal_entries');
    final commitmentBox = await Hive.openBox<Commitment>('commitments');

    var summary = const BackupSummary();

    for (final raw in _listOf(decoded['mantras'])) {
      final mantra = _mantraFromJson(raw);
      await mantras.put(mantra.id, mantra);
      summary = summary.copyWith(mantras: summary.mantras + 1);
    }
    for (final raw in _listOf(decoded['sessions'])) {
      final session = _sessionFromJson(raw);
      await sessions.put(session.id, session);
      summary = summary.copyWith(sessions: summary.sessions + 1);
    }
    for (final raw in _listOf(decoded['completions'])) {
      final completion = _completionFromJson(raw);
      await completions.put(completion.id, completion);
      summary = summary.copyWith(completions: summary.completions + 1);
    }
    for (final raw in _listOf(decoded['journal'])) {
      final entry = _journalFromJson(raw);
      await journal.put(entry.id, entry);
      summary = summary.copyWith(journal: summary.journal + 1);
    }
    for (final raw in _listOf(decoded['commitments'])) {
      final commitment = _commitmentFromJson(raw);
      await commitmentBox.put(commitment.id, commitment);
      summary = summary.copyWith(commitments: summary.commitments + 1);
    }

    return summary;
  }

  static List<Map<String, dynamic>> _listOf(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  static Map<String, dynamic> _mantraToJson(Mantra m) => {
    'id': m.id,
    'beadsPerRound': m.beadsPerRound,
    'name': m.name,
    'targetCount': m.targetCount,
    'description': m.description,
    'createdDate': m.createdDate.toIso8601String(),
    'currentCount': m.currentCount,
    'isDaily': m.isDaily,
    'lastResetDate': m.lastResetDate?.toIso8601String(),
  };

  static Mantra _mantraFromJson(Map<String, dynamic> j) => Mantra(
    id: j['id'] as String,
    name: j['name'] as String,
    targetCount: j['targetCount'] as int,
    description: j['description'] as String?,
    createdDate: DateTime.parse(j['createdDate'] as String),
    currentCount: j['currentCount'] as int? ?? 0,
    isDaily: j['isDaily'] as bool? ?? false,
    lastResetDate: _parseOrNull(j['lastResetDate']),
    beadsPerRound: j['beadsPerRound'] as int?,
  );

  static Map<String, dynamic> _sessionToJson(Session s) => {
    'id': s.id,
    'mantraId': s.mantraId,
    'count': s.count,
    'startTime': s.startTime.toIso8601String(),
    'endTime': s.endTime.toIso8601String(),
    'completed': s.completed,
    'kind': s.kindName,
    'title': s.title,
  };

  static Session _sessionFromJson(Map<String, dynamic> j) => Session(
    id: j['id'] as String,
    mantraId: j['mantraId'] as String,
    count: j['count'] as int,
    startTime: DateTime.parse(j['startTime'] as String),
    endTime: DateTime.parse(j['endTime'] as String),
    completed: j['completed'] as bool? ?? false,
    // Absent in backups taken before other kinds of practice were
    // recorded; those sessions were all japa.
    kindName: j['kind'] as String?,
    title: j['title'] as String?,
  );

  static Map<String, dynamic> _completionToJson(DailyCompletion c) => {
    'id': c.id,
    'mantraId': c.mantraId,
    'date': c.date.toIso8601String(),
    'completed': c.completed,
    'completionTime': c.completionTime?.toIso8601String(),
  };

  static DailyCompletion _completionFromJson(Map<String, dynamic> j) =>
      DailyCompletion(
        id: j['id'] as String,
        mantraId: j['mantraId'] as String,
        date: DateTime.parse(j['date'] as String),
        completed: j['completed'] as bool? ?? false,
        completionTime: _parseOrNull(j['completionTime']),
      );

  static Map<String, dynamic> _journalToJson(JournalEntry e) => {
    'id': e.id,
    'date': e.date.toIso8601String(),
    'content': e.content,
    'createdAt': e.createdAt.toIso8601String(),
    'mantraName': e.mantraName,
  };

  static JournalEntry _journalFromJson(Map<String, dynamic> j) => JournalEntry(
    id: j['id'] as String,
    date: DateTime.parse(j['date'] as String),
    content: j['content'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    mantraName: j['mantraName'] as String?,
  );

  static Map<String, dynamic> _commitmentToJson(Commitment c) => {
    'id': c.id,
    'mantraId': c.mantraId,
    'targetCount': c.targetCount,
    'startDate': c.startDate.toIso8601String(),
    'deadline': c.deadline?.toIso8601String(),
    'createdAt': c.createdAt.toIso8601String(),
    'completedAt': c.completedAt?.toIso8601String(),
    'intention': c.intention,
  };

  static Commitment _commitmentFromJson(Map<String, dynamic> j) => Commitment(
    id: j['id'] as String,
    mantraId: j['mantraId'] as String,
    targetCount: j['targetCount'] as int,
    startDate: DateTime.parse(j['startDate'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
    deadline: _parseOrNull(j['deadline']),
    completedAt: _parseOrNull(j['completedAt']),
    intention: j['intention'] as String?,
  );

  static DateTime? _parseOrNull(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}

class BackupSummary {
  final int mantras;
  final int sessions;
  final int completions;
  final int journal;
  final int commitments;

  const BackupSummary({
    this.mantras = 0,
    this.sessions = 0,
    this.completions = 0,
    this.journal = 0,
    this.commitments = 0,
  });

  BackupSummary copyWith({
    int? mantras,
    int? sessions,
    int? completions,
    int? journal,
    int? commitments,
  }) => BackupSummary(
    mantras: mantras ?? this.mantras,
    sessions: sessions ?? this.sessions,
    completions: completions ?? this.completions,
    journal: journal ?? this.journal,
    commitments: commitments ?? this.commitments,
  );

  @override
  String toString() =>
      '$mantras mantras, $sessions sessions, '
      '$completions completed days, $journal journal entries, '
      '$commitments vows';
}
