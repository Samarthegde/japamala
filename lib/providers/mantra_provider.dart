import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mantra.dart';
import '../models/daily_completion.dart';

class MantraProvider with ChangeNotifier {
  late Box<Mantra> _mantraBox;
  late Box<DailyCompletion> _completionBox;

  List<Mantra> _mantras = [];
  bool _isLoading = true;

  List<Mantra> get mantras => _mantras;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    try {
      _mantraBox = await Hive.openBox<Mantra>('mantras');
      _completionBox = await Hive.openBox<DailyCompletion>('daily_completions');

      await _checkAndResetDailyMantras();
      await _loadMantras();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing MantraProvider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndResetDailyMantras() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fourAM = DateTime(now.year, now.month, now.day, 4, 0, 0);

    // Check if it's past 4 AM and we haven't reset today
    for (final mantra in _mantraBox.values) {
      if (mantra.isDaily && mantra.lastResetDate != null) {
        final lastReset = mantra.lastResetDate!;
        final lastResetDate = DateTime(lastReset.year, lastReset.month, lastReset.day);

        // If it's past 4 AM and we haven't reset today, reset the mantra
        if (now.isAfter(fourAM) && lastResetDate.isBefore(today)) {
          final updatedMantra = mantra.copyWith(
            currentCount: 0,
            lastResetDate: now,
          );
          await _mantraBox.put(mantra.id, updatedMantra);
        }
      }
    }
  }

  Future<void> _loadMantras() async {
    _mantras = _mantraBox.values.toList();
    notifyListeners();
  }

  Future<void> addMantra(Mantra mantra) async {
    await _mantraBox.put(mantra.id, mantra);
    await _loadMantras();
    debugPrint('Added mantra: ${mantra.name}, total mantras: ${_mantras.length}');
  }

  Future<void> updateMantra(Mantra mantra) async {
    await _mantraBox.put(mantra.id, mantra);
    await _loadMantras();
  }

  Future<void> deleteMantra(String mantraId) async {
    await _mantraBox.delete(mantraId);
    await _loadMantras();
  }

  Future<void> incrementCount(String mantraId) async {
    final mantra = _mantraBox.get(mantraId);
    if (mantra != null) {
      final updatedMantra = mantra.copyWith(currentCount: mantra.currentCount + 1);
      await _mantraBox.put(mantraId, updatedMantra);
      await _loadMantras();
    }
  }

  Future<void> resetCount(String mantraId) async {
    final mantra = _mantraBox.get(mantraId);
    if (mantra != null) {
      final updatedMantra = mantra.copyWith(currentCount: 0);
      await _mantraBox.put(mantraId, updatedMantra);
      await _loadMantras();
    }
  }

  Mantra? getMantraById(String id) {
    return _mantraBox.get(id);
  }

  // Statistics
  int get totalMantrasCompleted {
    return _mantras.where((mantra) => mantra.isCompleted).length;
  }

  @override
  void dispose() {
    _mantraBox.close();
    _completionBox.close();
    super.dispose();
  }
}
