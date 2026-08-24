import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';
import 'mantra_provider.dart';

class SessionProvider with ChangeNotifier {
  Box<Session>? _sessionBox;
  Future<void>? _ready;
  bool _isLoading = true;

  List<Session> _sessions = [];
  List<Session> get sessions => _sessions;
  bool get isLoading => _isLoading;

  /// Safe to call more than once; the box is only opened on the first call.
  Future<void> init() => _ready ??= _open();

  Future<void> _open() async {
    try {
      _sessionBox = await Hive.openBox<Session>('sessions');
      _loadSessions();
    } catch (e) {
      debugPrint('Error initializing SessionProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-reads everything from disk, after a backup restore.
  Future<void> reload() async {
    await init();
    _loadSessions();
  }

  void _loadSessions() {
    _sessions = (_sessionBox?.values.toList() ?? [])
      ..sort((a, b) => b.endTime.compareTo(a.endTime)); // Most recent first
    notifyListeners();
  }

  Future<void> addSession(Session session) async {
    // A sitting can end before startup finishes opening the box; wait for it
    // rather than throwing on a `late` field that was never assigned.
    await init();
    final box = _sessionBox;
    if (box == null) return;

    await box.put(session.id, session);
    _loadSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    await init();
    final box = _sessionBox;
    if (box == null) return;

    await box.delete(sessionId);
    _loadSessions();
  }

  List<Session> getSessionsForMantra(String mantraId) {
    return _sessions.where((session) => session.mantraId == mantraId).toList();
  }

  List<Session> getAllSessions() {
    return _sessions;
  }

  List<Session> ofKind(SessionKind kind) =>
      _sessions.where((session) => session.kind == kind).toList();

  /// Total number of recorded sittings, of every kind.
  int get totalSessions => _sessions.length;

  /// Beads counted. Breathing cycles are not beads, so only japa counts here.
  int get totalBeads => _sessions
      .where((session) => session.kind == SessionKind.japa)
      .fold(0, (sum, session) => sum + session.count);

  Duration get totalTime =>
      _sessions.fold(Duration.zero, (sum, session) => sum + session.duration);

  // --- practice days & streaks ----------------------------------------------
  //
  // A streak means "I practised", not "I counted beads" — a morning of
  // breathing or a silent sitting keeps it alive just as japa does.

  /// Practice days that have at least one recorded session, using the same
  /// 4 AM rollover as daily mantras.
  Set<DateTime> get practiceDays => {
    for (final session in _sessions)
      MantraProvider.practiceDayOf(session.endTime),
  };

  bool practisedOn(DateTime day) =>
      practiceDays.contains(MantraProvider.practiceDayOf(day));

  /// Consecutive days practised, ending today — or yesterday, so that an
  /// unfinished morning doesn't read as a broken streak.
  int get currentStreak {
    final days = practiceDays;
    if (days.isEmpty) return 0;

    var day = MantraProvider.practiceDayOf(DateTime.now());
    if (!days.contains(day)) {
      day = DateTime(day.year, day.month, day.day - 1);
      if (!days.contains(day)) return 0;
    }

    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  int get longestStreak {
    final days = practiceDays;
    if (days.isEmpty) return 0;

    final sorted = days.toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final expected = DateTime(
        previous.year,
        previous.month,
        previous.day + 1,
      );
      if (sorted[i] == expected) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }

  @override
  void dispose() {
    _sessionBox?.close();
    super.dispose();
  }
}
