import 'package:flutter/foundation.dart';
import 'package:restro/services/daily_scoring_engine.dart';

class DailyScoreProvider with ChangeNotifier {
  final DailyScoringEngine _scoringEngine = DailyScoringEngine();

  DailyScore? _today;
  DailyScore? get today => _today;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadToday(String userId) async {
    if (userId.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _today = await _scoringEngine.getDailyScore(userId, today);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshScore(String userId) async {
    await loadToday(userId);
  }

  Future<void> initializeDailyScores() async {
    try {
      await _scoringEngine.initializeDailyScores();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recalculateScores(DateTime date) async {
    try {
      await _scoringEngine.recalculateAllScores(date);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
