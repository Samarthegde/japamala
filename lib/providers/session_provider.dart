import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';

class SessionProvider with ChangeNotifier {
  late Box<Session> _sessionBox;
  bool _isLoading = true;

  List<Session> _sessions = [];
  List<Session> get sessions => _sessions;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    try {
      _sessionBox = await Hive.openBox<Session>('sessions');
      await _loadSessions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SessionProvider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSessions() async {
    _sessions = _sessionBox.values.toList();
    notifyListeners();
  }

  Future<void> addSession(Session session) async {
    await _sessionBox.put(session.id, session);
    await _loadSessions();
    debugPrint('Added session: ${session.id}');
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionBox.delete(sessionId);
    await _loadSessions();
  }

  List<Session> getSessionsForMantra(String mantraId) {
    return _sessions.where((session) => session.mantraId == mantraId).toList();
  }

  List<Session> getAllSessions() {
    return _sessions;
  }

  @override
  void dispose() {
    _sessionBox.close();
    super.dispose();
  }
}
