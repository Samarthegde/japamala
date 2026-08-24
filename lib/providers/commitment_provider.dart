import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/commitment.dart';
import '../models/session.dart';

class CommitmentProvider with ChangeNotifier {
  Box<Commitment>? _box;
  Future<void>? _ready;
  bool _isLoading = true;

  List<Commitment> _commitments = [];
  List<Commitment> get commitments => _commitments;
  bool get isLoading => _isLoading;

  List<Commitment> get active =>
      _commitments.where((c) => !c.isComplete).toList();

  List<Commitment> get completed =>
      _commitments.where((c) => c.isComplete).toList();

  Future<void> init() => _ready ??= _open();

  Future<void> _open() async {
    try {
      _box = await Hive.openBox<Commitment>('commitments');
      _load();
    } catch (e) {
      debugPrint('Error initializing CommitmentProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    await init();
    _load();
  }

  void _load() {
    _commitments = (_box?.values.toList() ?? [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> add(Commitment commitment) async {
    await init();
    await _box?.put(commitment.id, commitment);
    _load();
  }

  Future<void> update(Commitment commitment) async {
    await _box?.put(commitment.id, commitment);
    _load();
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
    _load();
  }

  List<Commitment> forMantra(String mantraId) =>
      _commitments.where((c) => c.mantraId == mantraId).toList();

  /// Counts practice recorded against a vow. Only sessions that ended after it
  /// began count, so starting a sankalpa doesn't retroactively absorb old
  /// practice.
  int countFor(Commitment commitment, List<Session> sessions) {
    return sessions
        .where(
          (session) =>
              session.mantraId == commitment.mantraId &&
              !session.endTime.isBefore(commitment.startDate),
        )
        .fold(0, (sum, session) => sum + session.count);
  }

  CommitmentProgress progressFor(
    Commitment commitment,
    List<Session> sessions,
  ) {
    return CommitmentProgress(
      commitment: commitment,
      completedCount: countFor(commitment, sessions),
    );
  }

  /// Stamps a vow as fulfilled once the count reaches its target. Called after
  /// practice is recorded rather than computed on the fly, so the completion
  /// date is the day it was actually reached.
  Future<void> markCompletedIfReached(List<Session> sessions) async {
    var changed = false;
    for (final commitment in active) {
      if (countFor(commitment, sessions) >= commitment.targetCount) {
        await _box?.put(
          commitment.id,
          commitment.copyWith(completedAt: DateTime.now()),
        );
        changed = true;
      }
    }
    if (changed) _load();
  }

  @override
  void dispose() {
    _box?.close();
    super.dispose();
  }
}
