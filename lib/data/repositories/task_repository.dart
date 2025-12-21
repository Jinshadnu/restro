import 'package:restro/data/datasources/remote/firebase_storage_service.dart';

import '../../domain/repositories/task_repository_interface.dart';
import '../../domain/entities/task_entity.dart';
import '../datasources/remote/firestore_service.dart';
import '../models/task_model.dart';
import 'dart:io';

class TaskRepository implements TaskRepositoryInterface {
  final FirestoreService _firestoreService;
  final FirebaseStorageService _storageService;

  TaskRepository(this._firestoreService, this._storageService);

  Stream<List<TaskEntity>> getTasksStream(String userId, {String? status}) {
    return _firestoreService
        .getTasksStream(userId, status: status)
        .map((tasks) => tasks.map((task) => task as TaskEntity).toList());
  }

  @override
  Stream<List<TaskEntity>> getVerificationPendingTasks(String managerId) {
    return _firestoreService
        .getVerificationPendingTasks(managerId)
        .map((tasks) => tasks.map((task) => task as TaskEntity).toList());
  }

  Future<void> createTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    await _firestoreService.createTask(taskModel);
  }

  Future<void> completeTask(String taskId, {File? photo}) async {
    String? photoUrl;
    if (photo != null) {
      photoUrl = await _storageService.uploadTaskPhoto(taskId, photo);
    }

    await _firestoreService.updateTaskStatus(
      taskId,
      'verificationPending',
      photoUrl: photoUrl,
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<void> verifyTask(String taskId, bool approved,
      {String? rejectionReason}) async {
    if (approved) {
      await _firestoreService.updateTaskStatus(taskId, 'approved');
    } else {
      await _firestoreService.updateTaskStatus(
        taskId,
        'rejected',
        rejectionReason: rejectionReason,
      );
      // Re-assign task (reset to pending)
      await _firestoreService.updateTaskStatus(taskId, 'pending');
    }
  }

  @override
  Future<void> assignTask(String taskId, String staffId) async {
    await _firestoreService.assignTask(taskId, staffId);
  }

  @override
  Future<List<TaskEntity>> getTasksBySOP(String sopId) async {
    final tasks = await _firestoreService.getTasksBySOP(sopId);
    return tasks.map((task) => task as TaskEntity).toList();
  }

  @override
  Stream<List<TaskEntity>> getTaskStream(String userId, {String? status}) {
    return _firestoreService
        .getTasksStream(userId, status: status)
        .map((tasks) => tasks.map((task) => task as TaskEntity).toList());
  }

  Stream<List<TaskEntity>> getAdminTasks() {
    return _firestoreService
        .getAllTasks()
        .map((list) => list.map((model) => model as TaskEntity).toList());
  }
}
