import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mantra.dart';
import '../models/daily_completion.dart';

class MantraProvider with ChangeNotifier {
  /// Daily mantras roll over at 4 AM rather than midnight.
  static const int resetHour = 4;

  Box<Mantra>? _mantraBox;
  Box<DailyCompletion>? _completionBox;
  Future<void>? _ready;

  List<Mantra> _mantras = [];
  bool _isLoading = true;

  List<Mantra> get mantras => _mantras;
  bool get isLoading => _isLoading;

  /// The practice day a moment belongs to. Counting at 2 AM still belongs to
  /// the previous day, because the day hasn't rolled over yet.
  static DateTime practiceDayOf(DateTime moment) {
    final shifted = moment.hour < resetHour
        ? DateTime(moment.year, moment.month, moment.day - 1)
        : moment;
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Safe to call more than once; the boxes are only opened on the first call.
  Future<void> init() => _ready ??= _open();

  Future<void> _open() async {
    try {
      _mantraBox = await Hive.openBox<Mantra>('mantras');
      _completionBox = await Hive.openBox<DailyCompletion>('daily_completions');

      await _checkAndResetDailyMantras();
      _loadMantras();
    } catch (e) {
      debugPrint('Error initializing MantraProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndResetDailyMantras() async {
    final box = _mantraBox;
    if (box == null) return;

    final today = practiceDayOf(DateTime.now());

    // Snapshot first: writing back into the box while iterating its values
    // can invalidate the iterator.
    for (final mantra in box.values.toList()) {
      if (!mantra.isDaily || mantra.lastResetDate == null) continue;

      // practiceDayOf already encodes the 4 AM boundary, so a mantra reset
      // yesterday evening is not reset again at 2 AM tonight.
      if (!practiceDayOf(mantra.lastResetDate!).isBefore(today)) continue;

      await box.put(
        mantra.id,
        mantra.copyWith(currentCount: 0, lastResetDate: DateTime.now()),
      );
    }
  }

  /// Re-reads everything from disk. Used after a backup restore writes
  /// directly into the boxes behind the provider's back.
  Future<void> reload() async {
    await init();
    _loadMantras();
  }

  void _loadMantras() {
    _mantras = _mantraBox?.values.toList() ?? [];
    notifyListeners();
  }

  /// Applies [change] to the in-memory mantra and persists it.
  ///
  /// Deliberately avoids re-listing the whole box afterwards: on the counter
  /// screen this runs on every bead, and reloading emitted a second
  /// notifyListeners() that rebuilt the entire mantra list per tap.
  Future<void> _mutate(String mantraId, Mantra Function(Mantra) change) async {
    final index = _mantras.indexWhere((mantra) => mantra.id == mantraId);
    if (index == -1) return;

    final updated = change(_mantras[index]);
    _mantras[index] = updated;
    notifyListeners();

    await _mantraBox?.put(mantraId, updated);
  }

  Future<void> addMantra(Mantra mantra) async {
    await init();
    await _mantraBox?.put(mantra.id, mantra);
    _loadMantras();
  }

  Future<void> updateMantra(Mantra mantra) async {
    await _mantraBox?.put(mantra.id, mantra);
    _loadMantras();
  }

  Future<void> deleteMantra(String mantraId) async {
    await _mantraBox?.delete(mantraId);
    _loadMantras();
  }

  Future<void> incrementCount(String mantraId) async {
    await _mutate(
      mantraId,
      (mantra) => mantra.copyWith(currentCount: mantra.currentCount + 1),
    );

    final mantra = getMantraById(mantraId);
    if (mantra != null && mantra.isDaily && mantra.isCompleted) {
      await _recordDailyCompletion(mantra);
    }
  }

  /// Undoes a bead. If that drops a daily mantra back below its target on the
  /// current practice day, the day's completion record is withdrawn too, so a
  /// mistaken tap doesn't leave a false entry in the calendar.
  Future<void> decrementCount(String mantraId) async {
    await _mutate(
      mantraId,
      (mantra) => mantra.copyWith(
        currentCount: mantra.currentCount > 0 ? mantra.currentCount - 1 : 0,
      ),
    );

    final mantra = getMantraById(mantraId);
    if (mantra != null && mantra.isDaily && !mantra.isCompleted) {
      await _clearDailyCompletion(mantra);
    }
  }

  Future<void> resetCount(String mantraId) {
    return _mutate(mantraId, (mantra) => mantra.copyWith(currentCount: 0));
  }

  Mantra? getMantraById(String id) {
    final index = _mantras.indexWhere((mantra) => mantra.id == id);
    return index == -1 ? null : _mantras[index];
  }

  // ---------------------------------------------------------------------------
  // Practice history
  //
  // A row is written only when a daily mantra reaches its target. The absence
  // of a row means the day was missed, which keeps history correct even when
  // the app isn't opened for a stretch of days.
  // ---------------------------------------------------------------------------

  Future<void> _recordDailyCompletion(Mantra mantra) async {
    final box = _completionBox;
    if (box == null) return;

    final day = practiceDayOf(DateTime.now());
    final id = DailyCompletion.idFor(mantra.id, day);
    if (box.containsKey(id)) return; // Keep the first completion time

    await box.put(
      id,
      DailyCompletion.create(
        mantraId: mantra.id,
        date: day,
        completed: true,
        completionTime: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> _clearDailyCompletion(Mantra mantra) async {
    final box = _completionBox;
    if (box == null) return;

    final id = DailyCompletion.idFor(mantra.id, practiceDayOf(DateTime.now()));
    if (!box.containsKey(id)) return;

    await box.delete(id);
    notifyListeners();
  }

  DailyCompletion? completionFor(String mantraId, DateTime day) {
    return _completionBox?.get(DailyCompletion.idFor(mantraId, _dayOnly(day)));
  }

  bool isCompletedOn(String mantraId, DateTime day) =>
      completionFor(mantraId, day)?.completed ?? false;

  /// Daily mantras that already existed on [day] — one created last week
  /// shouldn't count as missed for last month.
  List<Mantra> dailyMantrasOn(DateTime day) {
    final target = _dayOnly(day);
    return _mantras
        .where(
          (mantra) =>
              mantra.isDaily &&
              !practiceDayOf(mantra.createdDate).isAfter(target),
        )
        .toList();
  }

  /// True when every daily mantra that existed on [day] was completed.
  ///
  /// Not the same thing as the practice streak, which lives on
  /// SessionProvider and asks only whether you practised at all — breathing
  /// and meditation keep it alive too.
  bool isDayComplete(DateTime day) {
    final expected = dailyMantrasOn(day);
    if (expected.isEmpty) return false;
    return expected.every((mantra) => isCompletedOn(mantra.id, day));
  }

  // Statistics
  int get totalMantrasCompleted {
    return _mantras.where((mantra) => mantra.isCompleted).length;
  }

  @override
  void dispose() {
    _mantraBox?.close();
    _completionBox?.close();
    super.dispose();
  }
}
