import 'package:flutter/material.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/utils/navigation/app_routes.dart';

class CriticalComplianceBlocker extends StatelessWidget {
  final List<TaskEntity> incompleteTasks;
  final VoidCallback? onTaskCompleted;

  const CriticalComplianceBlocker({
    super.key,
    required this.incompleteTasks,
    this.onTaskCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.red.shade200, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  size: 48,
                  color: Colors.red.shade700,
                ),
              ),

              const SizedBox(height: 24),

              // Critical Compliance Text
              Text(
                'CRITICAL COMPLIANCE PENDING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Complete the following critical tasks to continue:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 24),

              // Incomplete Tasks List
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: incompleteTasks.length,
                  itemBuilder: (context, index) {
                    final task = incompleteTasks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(task.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the first PENDING critical task's details screen
                    final pendingCriticalTasks = incompleteTasks
                        .where((task) => task.status == TaskStatus.pending)
                        .toList();

                    if (pendingCriticalTasks.isNotEmpty) {
                      final firstPendingTask = pendingCriticalTasks.first;
                      final taskModel = TaskModel.fromEntity(firstPendingTask);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.taskDetails,
                        (route) => false,
                        arguments: taskModel,
                      );
                    } else if (incompleteTasks.isNotEmpty) {
                      // Fallback: if no pending critical tasks, go to first incomplete critical task
                      final firstTask = incompleteTasks.first;
                      final taskModel = TaskModel.fromEntity(firstTask);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.taskDetails,
                        (route) => false,
                        arguments: taskModel,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'COMPLETE CRITICAL TASKS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.verificationPending:
        return 'Verification Pending';
      case TaskStatus.rejected:
        return 'Rejected';
      default:
        return 'Incomplete';
    }
  }
}
