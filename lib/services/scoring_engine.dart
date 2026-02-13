import 'package:restro/domain/entities/task_entity.dart';

enum DeductionType {
  missedCriticalTask,
  missedRoutineTask,
  lateSubmission,
  lateVerification,
  ownerOverride,
  managerRejection,
}

class DeductionRule {
  final DeductionType type;
  final int points;
  final String description;

  const DeductionRule({
    required this.type,
    required this.points,
    required this.description,
  });
}

class ScoreCalculation {
  final int baseScore;
  final int finalScore;
  final List<DeductionRule> deductions;
  final DateTime calculationDate;

  const ScoreCalculation({
    required this.baseScore,
    required this.finalScore,
    required this.deductions,
    required this.calculationDate,
  });
}

class ScoringEngine {
  static const int DAILY_BASE_SCORE = 100;

  static const List<DeductionRule> DEDUCTION_RULES = [
    DeductionRule(
      type: DeductionType.missedCriticalTask,
      points: -15,
      description: 'Missed Critical Task (Grade A)',
    ),
    DeductionRule(
      type: DeductionType.missedRoutineTask,
      points: -5,
      description: 'Missed Routine Task (Grade B)',
    ),
    DeductionRule(
      type: DeductionType.lateSubmission,
      points: -2,
      description: 'Late Submission',
    ),
    DeductionRule(
      type: DeductionType.lateVerification,
      points: -2,
      description: 'Late Verification by Manager',
    ),
    DeductionRule(
      type: DeductionType.ownerOverride,
      points: -20,
      description: 'Owner Override (⚠️ Major Penalty)',
    ),
    DeductionRule(
      type: DeductionType.managerRejection,
      points: -5,
      description: 'Manager Rejection',
    ),
  ];

  /// Calculate daily score based on tasks for a specific date
  static ScoreCalculation calculateDailyScore(
    List<TaskEntity> tasks,
    DateTime date,
  ) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final deductions = <DeductionRule>[];

    // Filter tasks for the specific date
    final dayTasks = tasks.where((task) {
      final taskDate = task.dueDate != null
          ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
          : null;
      return taskDate != null && taskDate.isAtSameMomentAs(targetDate);
    }).toList();

    // Check each task for deductions
    for (final task in dayTasks) {
      _checkTaskForDeductions(task, deductions);
    }

    // Calculate final score
    int totalDeduction =
        deductions.fold(0, (sum, deduction) => sum + deduction.points);
    int finalScore = DAILY_BASE_SCORE + totalDeduction;

    // Ensure score doesn't go below 0
    finalScore = finalScore < 0 ? 0 : finalScore;

    return ScoreCalculation(
      baseScore: DAILY_BASE_SCORE,
      finalScore: finalScore,
      deductions: deductions,
      calculationDate: DateTime.now(),
    );
  }

  /// Check individual task for potential deductions
  static void _checkTaskForDeductions(
    TaskEntity task,
    List<DeductionRule> deductions,
  ) {
    final now = DateTime.now();

    // Rule 1: Missed Critical Task (-15 points)
    if (task.grade == TaskGrade.critical && _isTaskMissed(task, now)) {
      deductions.add(DEDUCTION_RULES.firstWhere(
        (rule) => rule.type == DeductionType.missedCriticalTask,
      ));
    }

    // Rule 2: Missed Routine Task (-5 points)
    if (task.grade == TaskGrade.normal && _isTaskMissed(task, now)) {
      deductions.add(DEDUCTION_RULES.firstWhere(
        (rule) => rule.type == DeductionType.missedRoutineTask,
      ));
    }

    // Rule 3: Late Submission (-2 points)
    if (task.isLate && task.status != TaskStatus.pending) {
      deductions.add(DEDUCTION_RULES.firstWhere(
        (rule) => rule.type == DeductionType.lateSubmission,
      ));
    }

    // Rule 4: Late Verification (-2 points)
    if (_isLateVerification(task, now)) {
      deductions.add(DEDUCTION_RULES.firstWhere(
        (rule) => rule.type == DeductionType.lateVerification,
      ));
    }

    // Rule 5: Owner Override (-20 points)
    if (_hasOwnerOverride(task)) {
      deductions.add(DEDUCTION_RULES.firstWhere(
        (rule) => rule.type == DeductionType.ownerOverride,
      ));
    }

    if (task.status == TaskStatus.rejected) {
      deductions.add(DEDUCTION_RULES.firstWhere(
        (rule) => rule.type == DeductionType.managerRejection,
      ));
    }
  }

  /// Check if a task is missed (not completed after deadline)
  static bool _isTaskMissed(TaskEntity task, DateTime currentTime) {
    if (task.dueDate == null) return false;

    final isCompleted = task.status == TaskStatus.completed ||
        task.status == TaskStatus.approved;

    // Task is missed if deadline passed and not completed
    return currentTime.isAfter(task.dueDate!) && !isCompleted;
  }

  /// Check if verification is late (manager didn't review within 30 minutes)
  static bool _isLateVerification(TaskEntity task, DateTime currentTime) {
    if (task.completedAt == null || task.verifiedAt == null) return false;

    final completionTime = task.completedAt!;
    final verificationTime = task.verifiedAt!;
    final timeDifference = verificationTime.difference(completionTime);

    // Late if verification took more than 30 minutes
    return timeDifference.inMinutes > 30;
  }

  /// Check if there was an owner override (owner rejected after manager approval)
  static bool _hasOwnerOverride(TaskEntity task) {
    // Owner override occurs when:
    // 1. Task was approved by manager (status is approved or verification completed)
    // 2. Later rejected by owner (ownerRejectionAt is set)
    // 3. Owner rejection happened after manager approval

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

  /// Get deduction rule by type
  static DeductionRule? getDeductionRule(DeductionType type) {
    try {
      return DEDUCTION_RULES.firstWhere((rule) => rule.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Calculate score for a date range (week, month, etc.)
  static ScoreCalculation calculateRangeScore(
    List<TaskEntity> tasks,
    DateTime startDate,
    DateTime endDate,
  ) {
    final deductions = <DeductionRule>[];

    // Filter tasks within date range
    final rangeTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      return !task.dueDate!.isBefore(startDate) &&
          !task.dueDate!.isAfter(endDate);
    }).toList();

    // Check each task for deductions
    for (final task in rangeTasks) {
      _checkTaskForDeductions(task, deductions);
    }

    // Calculate final score (base score for each day in range)
    final days = endDate.difference(startDate).inDays + 1;
    int totalDeduction =
        deductions.fold(0, (sum, deduction) => sum + deduction.points);
    int finalScore = (DAILY_BASE_SCORE * days) + totalDeduction;

    // Ensure score doesn't go below 0
    finalScore = finalScore < 0 ? 0 : finalScore;

    return ScoreCalculation(
      baseScore: DAILY_BASE_SCORE * days,
      finalScore: finalScore,
      deductions: deductions,
      calculationDate: DateTime.now(),
    );
  }

  /// Get human-readable score status
  static String getScoreStatus(int score) {
    if (score >= 95) return 'Excellent';
    if (score >= 85) return 'Good';
    if (score >= 75) return 'Satisfactory';
    if (score >= 60) return 'Needs Improvement';
    return 'Poor';
  }

  /// Get color for score display
  static int getScoreColor(int score) {
    if (score >= 95) return 0xFF4CAF50; // Green
    if (score >= 85) return 0xFF8BC34A; // Light Green
    if (score >= 75) return 0xFFFFC107; // Amber
    if (score >= 60) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }
}
