import 'package:restro/data/datasources/local/database_helper.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:uuid/uuid.dart';

class AutoAssignmentService {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;
  final Uuid _uuid = const Uuid();

  AutoAssignmentService(this._dbHelper, this._firestoreService);

  /// Auto-assign tasks based on SOP frequency
  /// This should be called daily (via background task or notification)
  Future<void> autoAssignTasks() async {
    try {
      // Get all SOPs
      final sops = await _dbHelper.getAllSOPs();

      // Get all staff members
      final users = await _dbHelper.getAllUsers();
      final staffMembers = users.where((u) => u.role == 'staff').toList();

      if (staffMembers.isEmpty) {
        print('No staff members found for auto-assignment');
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var sop in sops) {
        bool shouldAssign = false;
        DateTime? dueDate;

        switch (sop.frequency) {
          case TaskFrequency.daily:
            shouldAssign = true;
            dueDate = today.add(const Duration(days: 1));
            break;

          case TaskFrequency.weekly:
            // Assign on Monday (1) of each week
            if (now.weekday == 1) {
              shouldAssign = true;
              dueDate = today.add(const Duration(days: 7));
            }
            break;

          case TaskFrequency.monthly:
            // Assign on the 1st of each month
            if (now.day == 1) {
              shouldAssign = true;
              final nextMonth = DateTime(now.year, now.month + 1, 1);
              dueDate = nextMonth;
            }
            break;
        }

        if (shouldAssign) {
          // Check if task already exists for today
          final existingTasks = await _dbHelper.getTasksByUser(
            staffMembers.first.id, // Check with first staff member
          );

          final todayTasks = existingTasks.where((task) {
            if (task.sopid != sop.id) return false;
            if (task.dueDate == null) return false;
            final taskDate = DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            );
            return taskDate.isAtSameMomentAs(today);
          }).toList();

          // If no task exists for today, create one
          if (todayTasks.isEmpty) {
            // Assign to staff members in round-robin fashion
            final staffIndex = sop.id.hashCode % staffMembers.length;
            final assignedStaff = staffMembers[staffIndex];

            // Get manager/admin to assign by
            final managers = users
                .where((u) => u.role == 'manager' || u.role == 'admin')
                .toList();

            if (managers.isNotEmpty) {
              final assignedBy = managers.first;

              final task = TaskModel(
                id: _uuid.v4(),
                title: sop.title,
                description: sop.description,
                sopid: sop.id,
                assignedTo: assignedStaff.id,
                assignedBy: assignedBy.id,
                status: TaskStatus.pending,
                frequency: sop.frequency,
                dueDate: dueDate,
                createdAt: DateTime.now(),
                requiresPhoto: sop.requiresPhoto,
              );

              // Save to local database first
              await _dbHelper.insertTask(task);

              // Sync to Firestore
              try {
                await _firestoreService.createTask(task);
                await _dbHelper.markTaskSynced(task.id);
              } catch (e) {
                print('Failed to sync task to Firestore: $e');
                // Task is saved locally and will sync later
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error in auto-assignment: $e');
    }
  }

  /// Generate checklist tasks from SOP
  Future<List<TaskModel>> generateChecklistFromSOP(
    SOPModel sop,
    String assignedTo,
    String assignedBy,
  ) async {
    final tasks = <TaskModel>[];
    final now = DateTime.now();
    DateTime? dueDate;

    switch (sop.frequency) {
      case TaskFrequency.daily:
        dueDate = now.add(const Duration(days: 1));
        break;
      case TaskFrequency.weekly:
        dueDate = now.add(const Duration(days: 7));
        break;
      case TaskFrequency.monthly:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        dueDate = nextMonth;
        break;
    }

    // Create a task for each step in the SOP
    for (int i = 0; i < sop.steps.length; i++) {
      final step = sop.steps[i];
      final task = TaskModel(
        id: _uuid.v4(),
        title: '${sop.title} - Step ${i + 1}',
        description: step,
        sopid: sop.id,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        status: TaskStatus.pending,
        frequency: sop.frequency,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        requiresPhoto: sop.requiresPhoto,
      );

      tasks.add(task);
    }

    // If SOP has no steps, create a single task
    if (tasks.isEmpty) {
      final task = TaskModel(
        id: _uuid.v4(),
        title: sop.title,
        description: sop.description,
        sopid: sop.id,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        status: TaskStatus.pending,
        frequency: sop.frequency,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        requiresPhoto: sop.requiresPhoto,
      );
      tasks.add(task);
    }

    return tasks;
  }
}
