import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'dart:math' as math;

enum DeductionType {
  criticalMiss, // -15 points: Grade A task missed deadline
  routineMiss, // -5 points: Grade B task missed deadline
  lateSubmission, // -2 points: Staff submitted after deadline
  verificationLag, // -2 points: Manager failed to verify within 30 mins
  ownerOverride, // -20 points: Owner rejected after manager approval
  managerRejection, // 0 points: Manager rejected (no penalty)
}

class DeductionRule {
  final DeductionType type;
  final int points;
  final String description;
  final String? targetUserId; // Who gets the deduction (staff or manager)

  const DeductionRule({
    required this.type,
    required this.points,
    required this.description,
    this.targetUserId,
  });
}

class DailyScore {
  String userId;
  DateTime date;
  int baseScore;
  int finalScore;
  List<DeductionRule> deductions;
  DateTime calculatedAt;
  String status;
  int color;

  DailyScore({
    required this.userId,
    required this.date,
    required this.baseScore,
    required this.finalScore,
    required this.deductions,
    required this.calculatedAt,
    required this.status,
    required this.color,
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
                'targetUserId': d.targetUserId,
              })
          .toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'status': status,
      'color': color,
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
                targetUserId: d['targetUserId'],
              ))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt']),
      status: json['status'],
      color: json['color'],
    );
  }

  static DeductionType _deductionTypeFromString(String typeString) {
    switch (typeString) {
      case 'DeductionType.criticalMiss':
        return DeductionType.criticalMiss;
      case 'DeductionType.routineMiss':
        return DeductionType.routineMiss;
      case 'DeductionType.lateSubmission':
        return DeductionType.lateSubmission;
      case 'DeductionType.verificationLag':
        return DeductionType.verificationLag;
      case 'DeductionType.ownerOverride':
        return DeductionType.ownerOverride;
      case 'DeductionType.managerRejection':
        return DeductionType.managerRejection;
      default:
        return DeductionType.routineMiss;
    }
  }
}

class DailyScoringEngine {
  static const int DAILY_BASE_SCORE = 100;
  static const int VERIFICATION_TIMEOUT_MINUTES = 30;
  static const int LATE_SUBMISSION_GRACE_MINUTES = 15;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate daily score for a specific user and date
  Future<DailyScore> calculateDailyScore(String userId, DateTime date) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetDateEnd = targetDate.add(const Duration(days: 1));
    final deductions = <DeductionRule>[];

    // Get all tasks for the user
    final tasks = await _firestoreService.getTasksForUser(userId);
    final taskEntities = tasks.map((task) => task.toEntity()).toList();

    // Include tasks due on or before the target date (overdue tasks should
    // impact today's score as well).
    final dayTasks = taskEntities.where((task) {
      final due = task.dueDate;
      if (due == null) return false;
      return due.isBefore(targetDateEnd);
    }).toList();

    // Check each task for deductions
    for (final task in dayTasks) {
      await _checkTaskForDeductions(task, deductions, targetDate);
    }

    // Calculate final score
    int totalDeduction =
        deductions.fold(0, (sum, deduction) => sum + deduction.points);
    int finalScore = DAILY_BASE_SCORE + totalDeduction;
    finalScore = finalScore < 0 ? 0 : finalScore;

    return DailyScore(
      userId: userId,
      date: targetDate,
      baseScore: DAILY_BASE_SCORE,
      finalScore: finalScore,
      deductions: deductions,
      calculatedAt: DateTime.now(),
      status: _getScoreStatus(finalScore),
      color: _getScoreColor(finalScore),
    );
  }

  /// Check individual task for potential deductions
  Future<void> _checkTaskForDeductions(
    TaskEntity task,
    List<DeductionRule> deductions,
    DateTime targetDate,
  ) async {
    final now = DateTime.now();

    // Rule 1: Critical Miss (-15 points)
    if (task.grade == TaskGrade.critical && _isTaskMissed(task, now)) {
      deductions.add(DeductionRule(
        type: DeductionType.criticalMiss,
        points: -15,
        description: 'Critical Task (Grade A) Missed Deadline',
        targetUserId: task.assignedTo,
      ));
    }

    // Rule 2: Routine Miss (-5 points)
    if (task.grade == TaskGrade.normal && _isTaskMissed(task, now)) {
      deductions.add(DeductionRule(
        type: DeductionType.routineMiss,
        points: -5,
        description: 'Routine Task (Grade B) Missed Deadline',
        targetUserId: task.assignedTo,
      ));
    }

    // Rule 3: Late Submission (-2 points)
    if (task.isLate && task.status != TaskStatus.pending) {
      deductions.add(DeductionRule(
        type: DeductionType.lateSubmission,
        points: -2,
        description: 'Late Submission',
        targetUserId: task.assignedTo,
      ));
    }

    // Rule 4: Verification Lag (-2 points to Manager)
    if (_isVerificationLag(task, now)) {
      deductions.add(DeductionRule(
        type: DeductionType.verificationLag,
        points: -2,
        description: 'Manager Failed to Verify Within 30 Minutes',
        targetUserId: task.assignedBy, // Manager gets the deduction
      ));
    }

    // Rule 5: Owner Override (-20 points to Manager)
    if (_hasOwnerOverride(task)) {
      deductions.add(DeductionRule(
        type: DeductionType.ownerOverride,
        points: -20,
        description: 'Owner Override After Manager Approval',
        targetUserId: task.assignedBy, // Manager gets the deduction
      ));
    }

    // Rule 6: Manager Rejection (0 points - no penalty)
    if (task.status == TaskStatus.rejected) {
      deductions.add(DeductionRule(
        type: DeductionType.managerRejection,
        points: 0,
        description: 'Manager Rejection (No Penalty)',
        targetUserId: task.assignedTo,
      ));
    }
  }

  /// Check if a task is missed (not completed after deadline)
  bool _isTaskMissed(TaskEntity task, DateTime currentTime) {
    if (task.dueDate == null) return false;

    final isCompleted = task.status == TaskStatus.completed ||
        task.status == TaskStatus.approved;

    // Task is missed if deadline passed and not completed
    return currentTime.isAfter(task.dueDate!) && !isCompleted;
  }

  /// Check if verification is late (manager didn't review within 30 minutes)
  bool _isVerificationLag(TaskEntity task, DateTime currentTime) {
    if (task.completedAt == null || task.verifiedAt == null) return false;

    final completionTime = task.completedAt!;
    final verificationTime = task.verifiedAt!;
    final timeDifference = verificationTime.difference(completionTime);

    // Late if verification took more than 30 minutes
    return timeDifference.inMinutes > VERIFICATION_TIMEOUT_MINUTES;
  }

  /// Check if there was an owner override (owner rejected after manager approval)
  bool _hasOwnerOverride(TaskEntity task) {
    if (task.ownerRejectionAt == null || task.rejectedBy == null) {
      return false;
    }

    // Check if task was previously approved/verified before owner rejection
    final wasApproved = task.verifiedAt != null;
    final ownerRejectionAfterApproval = task.ownerRejectionAt!.isAfter(
      task.verifiedAt ?? task.createdAt,
    );

    return wasApproved && ownerRejectionAfterApproval;
  }

  /// Store daily score in Firestore
  Future<void> storeDailyScore(DailyScore dailyScore) async {
    final dateKey = _formatDateKey(dailyScore.date);
    final docId = '${dailyScore.userId}_$dateKey';

    await _firestore
        .collection('daily_scores')
        .doc(docId)
        .set(dailyScore.toJson());
  }

  /// Get daily score for a user and date
  Future<DailyScore?> getDailyScore(String userId, DateTime date) async {
    final dateKey = _formatDateKey(date);
    final docId = '${userId}_$dateKey';

    final doc = await _firestore.collection('daily_scores').doc(docId).get();

    if (!doc.exists) return null;

    return DailyScore.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Initialize daily score for a specific user
  Future<void> initializeDailyScore(String userId, DateTime date) async {
    final dateKey = _formatDateKey(date);
    final docId = '${userId}_$dateKey';

    final dailyScore = DailyScore(
      userId: userId,
      date: date,
      baseScore: DAILY_BASE_SCORE,
      finalScore: DAILY_BASE_SCORE,
      deductions: [],
      calculatedAt: DateTime.now(),
      status: 'Excellent',
      color: 0xFF4CAF50,
    );

    await _firestore
        .collection('daily_scores')
        .doc(docId)
        .set(dailyScore.toJson());
  }

  Future<void> checkMissedTasksForUser(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await calculateAndStoreScore(userId, today);
  }

  /// Apply deductions for a specific user
  Future<void> applyDeductionsForUser(String userId,
      List<Map<String, dynamic>> deductions, DateTime date) async {
    final dateKey = _formatDateKey(date);
    final docId = '${userId}_$dateKey';
    final scoreRef = _firestore.collection('daily_scores').doc(docId);

    // Get current score
    final scoreDoc = await scoreRef.get();
    DailyScore currentScore;

    if (scoreDoc.exists) {
      currentScore =
          DailyScore.fromJson(scoreDoc.data() as Map<String, dynamic>);
    } else {
      // Initialize with base score if doesn't exist
      currentScore = DailyScore(
        userId: userId,
        date: date,
        baseScore: DAILY_BASE_SCORE,
        finalScore: DAILY_BASE_SCORE,
        deductions: [],
        calculatedAt: DateTime.now(),
        status: 'Excellent',
        color: 0xFF4CAF50,
      );
    }

    // Add new deductions
    deductions.forEach((deduction) {
      currentScore.deductions.add(DeductionRule(
        type: DailyScore._deductionTypeFromString(deduction['type']),
        points: deduction['points'],
        description: deduction['description'],
        targetUserId: deduction['targetUserId'],
      ));
    });

    // Recalculate final score
    final totalDeduction =
        currentScore.deductions.fold(0, (sum, d) => sum + d.points);
    currentScore.finalScore = math.max(0, DAILY_BASE_SCORE + totalDeduction);
    currentScore.calculatedAt = DateTime.now();
    currentScore.status = _getScoreStatus(currentScore.finalScore);
    currentScore.color = _getScoreColor(currentScore.finalScore);

    await scoreRef.set(currentScore.toJson());
  }

  Future<void> initializeDailyScores() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all staff users
    final staffSnapshot = await _firestore
        .collection('users')
        .where('role', whereIn: ['staff', 'cleaner', 'waiter', 'chef']).get();

    for (final doc in staffSnapshot.docs) {
      final userId = doc.id;
      final dateKey = _formatDateKey(today);
      final docId = '${userId}_$dateKey';

      // Check if score already exists for today
      final existingScore =
          await _firestore.collection('daily_scores').doc(docId).get();

      if (!existingScore.exists) {
        // Initialize with 100 points
        final initialScore = DailyScore(
          userId: userId,
          date: today,
          baseScore: DAILY_BASE_SCORE,
          finalScore: DAILY_BASE_SCORE,
          deductions: [],
          calculatedAt: DateTime.now(),
          status: 'Excellent',
          color: 0xFF4CAF50, // Green
        );

        await _firestore
            .collection('daily_scores')
            .doc(docId)
            .set(initialScore.toJson());
        print('Initialized daily score for user $userId: $DAILY_BASE_SCORE');
      }
    }
  }

  /// Recalculate scores for all users for a specific date
  Future<void> recalculateAllScores(DateTime date) async {
    // Get all staff users
    final staffSnapshot = await _firestore
        .collection('users')
        .where('role', whereIn: ['staff', 'cleaner', 'waiter', 'chef']).get();

    for (final doc in staffSnapshot.docs) {
      final userId = doc.id;
      final score = await calculateDailyScore(userId, date);
      await storeDailyScore(score);
      print('Recalculated score for user $userId: ${score.finalScore}');
    }
  }

  /// Handle task status change and update scores accordingly
  Future<void> handleTaskStatusChange(String taskId) async {
    final task = await _firestoreService.getTaskById(taskId);
    if (task == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Recalculate scores for both staff and manager for today
    await calculateAndStoreScore(task.assignedTo, today);

    if (task.assignedBy != task.assignedTo) {
      await calculateAndStoreScore(task.assignedBy, today);
    }
  }

  /// Calculate and store score for a user
  Future<void> calculateAndStoreScore(String userId, DateTime date) async {
    final score = await calculateDailyScore(userId, date);
    await storeDailyScore(score);
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getScoreStatus(int score) {
    if (score >= 95) return 'Excellent';
    if (score >= 85) return 'Good';
    if (score >= 75) return 'Average';
    if (score >= 60) return 'Below Average';
    return 'Poor';
  }

  int _getScoreColor(int score) {
    if (score >= 95) return 0xFF4CAF50; // Green
    if (score >= 85) return 0xFF8BC34A; // Light Green
    if (score >= 75) return 0xFFFFC107; // Amber
    if (score >= 60) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }
}
