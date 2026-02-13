import 'package:restro/services/scoring_engine.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyScore {
  final String userId;
  final DateTime date;
  final int baseScore;
  final int finalScore;
  final List<DeductionRule> deductions;
  final String status;
  final int color;
  final DateTime calculatedAt;

  const DailyScore({
    required this.userId,
    required this.date,
    required this.baseScore,
    required this.finalScore,
    required this.deductions,
    required this.status,
    required this.color,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'baseScore': baseScore,
      'finalScore': finalScore,
      'deductions': deductions
          .map((d) => {
                'type': d.type.toString(),
                'points': d.points,
                'description': d.description,
              })
          .toList(),
      'status': status,
      'color': color,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory DailyScore.fromJson(Map<String, dynamic> json) {
    return DailyScore(
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      baseScore: json['baseScore'],
      finalScore: json['finalScore'],
      deductions: (json['deductions'] as List)
          .map((d) => DeductionRule(
                type: _deductionTypeFromString(d['type']),
                points: d['points'],
                description: d['description'],
              ))
          .toList(),
      status: json['status'],
      color: json['color'],
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }

  static DeductionType _deductionTypeFromString(String typeString) {
    switch (typeString) {
      case 'DeductionType.missedCriticalTask':
        return DeductionType.missedCriticalTask;
      case 'DeductionType.missedRoutineTask':
        return DeductionType.missedRoutineTask;
      case 'DeductionType.lateSubmission':
        return DeductionType.lateSubmission;
      case 'DeductionType.lateVerification':
        return DeductionType.lateVerification;
      case 'DeductionType.ownerOverride':
        return DeductionType.ownerOverride;
      case 'DeductionType.managerRejection':
        return DeductionType.managerRejection;
      default:
        return DeductionType.missedRoutineTask;
    }
  }
}

class ScoreTrackingService {
  static final ScoreTrackingService _instance =
      ScoreTrackingService._internal();
  factory ScoreTrackingService() => _instance;
  ScoreTrackingService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate and store daily score for a user
  Future<DailyScore> calculateAndStoreDailyScore(
      String userId, DateTime date) async {
    try {
      // Get all tasks for the user
      final tasks = await _firestoreService.getTasksForUser(userId);
      final taskEntities = tasks.map((task) => task.toEntity()).toList();

      // Calculate score using scoring engine
      final calculation = ScoringEngine.calculateDailyScore(taskEntities, date);

      // Create daily score object
      final dailyScore = DailyScore(
        userId: userId,
        date: date,
        baseScore: calculation.baseScore,
        finalScore: calculation.finalScore,
        deductions: calculation.deductions,
        status: ScoringEngine.getScoreStatus(calculation.finalScore),
        color: ScoringEngine.getScoreColor(calculation.finalScore),
        calculatedAt: DateTime.now(),
      );

      // Store in Firestore
      await _storeDailyScore(dailyScore);

      return dailyScore;
    } catch (e) {
      print('Error calculating daily score: $e');
      rethrow;
    }
  }

  /// Store daily score in Firestore
  Future<void> _storeDailyScore(DailyScore dailyScore) async {
    final dateKey = _formatDateKey(dailyScore.date);
    final docId = '${dailyScore.userId}_$dateKey';

    await _firestore
        .collection('daily_scores')
        .doc(docId)
        .set(dailyScore.toJson());
  }

  /// Get daily score for a user and date
  Future<DailyScore?> getDailyScore(String userId, DateTime date) async {
    try {
      final dateKey = _formatDateKey(date);
      final docId = '${userId}_$dateKey';

      final doc = await _firestore.collection('daily_scores').doc(docId).get();

      if (!doc.exists) return null;

      return DailyScore.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting daily score: $e');
      return null;
    }
  }

  /// Get weekly score summary for a user
  Future<List<DailyScore>> getWeeklyScores(
      String userId, DateTime weekStart) async {
    final scores = <DailyScore>[];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final score = await getDailyScore(userId, date);
      if (score != null) {
        scores.add(score);
      }
    }

    return scores;
  }

  /// Get monthly score summary for a user
  Future<List<DailyScore>> getMonthlyScores(
      String userId, int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay =
        DateTime(year, month + 1, 0).subtract(const Duration(days: 1));

    return getRangeScores(userId, firstDay, lastDay);
  }

  /// Get score range for a user
  Future<List<DailyScore>> getRangeScores(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection('daily_scores')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date')
          .get();

      return query.docs
          .map((doc) => DailyScore.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting range scores: $e');
      return [];
    }
  }

  /// Calculate score summary for a range
  Future<Map<String, dynamic>> getScoreSummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final scores = await getRangeScores(userId, startDate, endDate);

    if (scores.isEmpty) {
      return {
        'totalDays': 0,
        'averageScore': 0,
        'highestScore': 0,
        'lowestScore': 0,
        'totalDeductions': 0,
        'mostCommonDeduction': null,
      };
    }

    final totalScore = scores.fold(0, (sum, score) => sum + score.finalScore);
    final averageScore = totalScore / scores.length;
    final highestScore =
        scores.map((s) => s.finalScore).reduce((a, b) => a > b ? a : b);
    final lowestScore =
        scores.map((s) => s.finalScore).reduce((a, b) => a < b ? a : b);

    // Count all deductions
    final allDeductions = <DeductionType, int>{};
    for (final score in scores) {
      for (final deduction in score.deductions) {
        allDeductions[deduction.type] =
            (allDeductions[deduction.type] ?? 0) + 1;
      }
    }

    final totalDeductions =
        allDeductions.values.fold(0, (sum, count) => sum + count);
    final mostCommonDeduction = allDeductions.entries.isNotEmpty
        ? allDeductions.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    return {
      'totalDays': scores.length,
      'averageScore': averageScore.round(),
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'totalDeductions': totalDeductions,
      'mostCommonDeduction': mostCommonDeduction,
    };
  }

  /// Format date as YYYY-MM-DD for document ID
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Auto-calculate scores for today (can be called daily)
  Future<void> calculateTodayScoresForAllStaff() async {
    try {
      // Get all staff users
      final staffUsers = await _firestoreService.getUsersByRole('staff');
      final today = DateTime.now();

      for (final staff in staffUsers) {
        await calculateAndStoreDailyScore(staff['id'], today);
      }
    } catch (e) {
      print('Error calculating today\'s scores for all staff: $e');
    }
  }
}
