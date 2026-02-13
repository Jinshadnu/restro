import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/domain/entities/task_entity.dart';

class CriticalComplianceService {
  static final CriticalComplianceService _instance =
      CriticalComplianceService._internal();
  factory CriticalComplianceService() => _instance;
  CriticalComplianceService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Check if user has incomplete critical tasks
  /// Returns true if there are incomplete critical tasks (should block navigation)
  Future<bool> hasIncompleteCriticalTasks(String userId) async {
    try {
      // Get all tasks for the user
      final tasks = await _firestoreService.getTasksForUser(userId);

      // Filter for critical tasks that are not completed/approved
      final incompleteCriticalTasks = tasks.where((task) {
        return task.grade == TaskGrade.critical && !_isTaskCompleted(task);
      }).toList();

      return incompleteCriticalTasks.isNotEmpty;
    } catch (e) {
      // If we can't check, allow navigation (fail-safe)
      print('Error checking critical tasks: $e');
      return false;
    }
  }

  /// Get list of incomplete critical tasks for display
  Future<List<TaskEntity>> getIncompleteCriticalTasks(String userId) async {
    try {
      final tasks = await _firestoreService.getTasksForUser(userId);

      return tasks
          .where((task) {
            return task.grade == TaskGrade.critical && !_isTaskCompleted(task);
          })
          .map((task) => task.toEntity())
          .toList();
    } catch (e) {
      print('Error getting critical tasks: $e');
      return [];
    }
  }

  /// Check if a task is considered completed for compliance blocking
  bool _isTaskCompleted(TaskModel task) {
    return task.status == TaskStatus.completed ||
        task.status == TaskStatus.approved ||
        task.status == TaskStatus.verificationPending;
  }

  /// Get a user-friendly message for critical compliance blocking
  String getBlockingMessage(List<TaskEntity> incompleteTasks) {
    if (incompleteTasks.isEmpty) {
      return 'CRITICAL COMPLIANCE PENDING';
    }

    final taskNames =
        incompleteTasks.map((task) => task.title).take(3).join(', ');
    final remaining =
        incompleteTasks.length > 3 ? incompleteTasks.length - 3 : 0;

    if (remaining > 0) {
      return 'CRITICAL COMPLIANCE PENDING\nComplete: $taskNames and $remaining more critical task${remaining > 1 ? 's' : ''}';
    } else {
      return 'CRITICAL COMPLIANCE PENDING\nComplete: $taskNames';
    }
  }
}
