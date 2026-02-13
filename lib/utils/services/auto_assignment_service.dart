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

  bool _looksLikeId(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    if (v.contains(' ')) return false;
    if (v.length < 18) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(v);
  }

  /// Auto-assign tasks based on SOP frequency
  /// This should be called daily (via background task or notification)
  Future<int> autoAssignTasks() async {
    try {
      var createdCount = 0;
      var syncedCount = 0;

      // Get all SOPs
      final sops = await _dbHelper.getAllSOPs();

      // Get all staff members
      final users = await _dbHelper.getAllUsers();
      final staffMembers = users
          .where((u) => u.role.toString().toLowerCase() == 'staff')
          .toList();

      print(
          'AutoAssignmentService.autoAssignTasks: sops=${sops.length} users=${users.length} staff=${staffMembers.length}');

      if (staffMembers.isEmpty) {
        print('No staff members found for auto-assignment');
        return 0;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var sop in sops) {
        final sopId = sop.id.toString().trim();
        final sopTitle = sop.title.toString().trim();
        final sopDesc = sop.description.toString().trim();

        if (sopId.isEmpty || sopTitle.isEmpty || sopDesc.isEmpty) {
          print(
              'AutoAssignmentService.autoAssignTasks: skipping invalid SOP (id/title/description missing)');
          continue;
        }

        if (_looksLikeId(sopTitle) || sopTitle.toLowerCase() == 'sopid') {
          print(
              'AutoAssignmentService.autoAssignTasks: skipping SOP with invalid title sop=$sopId title=$sopTitle');
          continue;
        }

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
          // Auto Schedule expectation: assign this SOP to ALL staff members.
          // Duplicate prevention uses createdAt(today), not dueDate.

          final assigners = users.where((u) {
            final r = u.role.toString().toLowerCase();
            return r == 'manager' || r == 'admin' || r == 'owner';
          }).toList();

          final fallbackNonStaff = users
              .where((u) => u.role.toString().toLowerCase() != 'staff')
              .toList();

          final assignedBy = assigners.isNotEmpty
              ? assigners.first
              : (fallbackNonStaff.isNotEmpty ? fallbackNonStaff.first : null);

          if (assignedBy == null) {
            print(
                'AutoAssignmentService.autoAssignTasks: skipping sop=${sop.id} because no assigner (admin/manager/owner) exists');
            continue;
          }

          final assignedById = assignedBy.id.toString().trim();
          if (assignedById.isEmpty) {
            print(
                'AutoAssignmentService.autoAssignTasks: skipping sop=$sopId because assignedBy id is empty');
            continue;
          }

          if (assignedById.toLowerCase() == 'staffid') {
            print(
                'AutoAssignmentService.autoAssignTasks: skipping sop=$sopId because assignedBy is placeholder staffId');
            continue;
          }

          for (final staff in staffMembers) {
            final staffId = staff.id.toString().trim();
            if (staffId.isEmpty) {
              print(
                  'AutoAssignmentService.autoAssignTasks: skipping staff with empty id for sop=$sopId');
              continue;
            }

            if (staffId.toLowerCase() == 'staffid') {
              print(
                  'AutoAssignmentService.autoAssignTasks: skipping placeholder staffId for sop=$sopId');
              continue;
            }
            final existingTasks = await _dbHelper.getTasksByUser(staff.id);
            final alreadyAssignedToday = existingTasks.any((task) {
              if (task.sopid != sopId) return false;
              final created = task.createdAt;
              final createdDay =
                  DateTime(created.year, created.month, created.day);
              return createdDay.isAtSameMomentAs(today);
            });

            if (alreadyAssignedToday) {
              print(
                  'AutoAssignmentService.autoAssignTasks: skip sop=${sop.id} for staff=${staff.id} (already assigned today)');
              continue;
            }

            print(
                'AutoAssignmentService.autoAssignTasks: creating task sop=$sopId assignedTo=$staffId assignedBy=$assignedById');

            final task = TaskModel(
              id: _uuid.v4(),
              title: sopTitle,
              description: sopDesc,
              sopid: sopId,
              assignedTo: staffId,
              assignedBy: assignedById,
              status: TaskStatus.pending,
              frequency: sop.frequency,
              grade: sop.isCritical == true
                  ? TaskGrade.critical
                  : TaskGrade.normal,
              dueDate: dueDate,
              createdAt: DateTime.now(),
              requiresPhoto: sop.requiresPhoto,
              // New owner override fields (null for new tasks)
              ownerRejectionAt: null,
              ownerRejectionReason: null,
              rejectedBy: null,
            );

            await _dbHelper.insertTask(task);
            createdCount += 1;

            try {
              await _firestoreService.createTask(task);
              await _dbHelper.markTaskSynced(task.id);
              syncedCount += 1;
            } catch (e) {
              print('Failed to sync task to Firestore: $e');
            }
          }
        }
      }

      print(
          'AutoAssignmentService.autoAssignTasks: created=$createdCount synced=$syncedCount');
      return syncedCount;
    } catch (e) {
      print('Error in auto-assignment: $e');
      return 0;
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
        grade: sop.isCritical == true ? TaskGrade.critical : TaskGrade.normal,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        requiresPhoto: sop.requiresPhoto,
        // New owner override fields (null for new tasks)
        ownerRejectionAt: null,
        ownerRejectionReason: null,
        rejectedBy: null,
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
        grade: sop.isCritical == true ? TaskGrade.critical : TaskGrade.normal,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        requiresPhoto: sop.requiresPhoto,
        // New owner override fields (null for new tasks)
        ownerRejectionAt: null,
        ownerRejectionReason: null,
        rejectedBy: null,
      );
      tasks.add(task);
    }

    return tasks;
  }
}
