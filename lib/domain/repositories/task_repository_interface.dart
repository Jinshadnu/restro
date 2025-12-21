import 'dart:io';

import 'package:restro/domain/entities/task_entity.dart';

abstract class TaskRepositoryInterface {
  Stream<List<TaskEntity>> getTaskStream(String userId, {String? status});
  Stream<List<TaskEntity>> getVerificationPendingTasks(String managerId);
  Stream<List<TaskEntity>> getAdminTasks();
  Future<void> createTask(TaskEntity task);
  Future<void> completeTask(String taskId, {File? photo});
  Future<void> verifyTask(String taskId, bool approved, {String? rejectionReason});
  Future<void> assignTask(String taskId, String staffId);
  Future<List<TaskEntity>> getTasksBySOP(String sopId);
}