import 'package:restro/data/datasources/remote/firebase_storage_service.dart';

import '../../domain/repositories/task_repository_interface.dart';
import '../../domain/entities/task_entity.dart';
import '../datasources/remote/firestore_service.dart';
import '../models/task_model.dart';
import 'dart:io';
import 'dart:typed_data';

class TaskRepository implements TaskRepositoryInterface {
  final FirestoreService _firestoreService;
  final FirebaseStorageService _storageService;

  TaskRepository(this._firestoreService, this._storageService);

  Stream<List<TaskEntity>> getTasksStream(String userId, {String? status}) {
    return _firestoreService
        .getTasksStream(userId, status: status)
        .map((tasks) => tasks.map((task) => task.toEntity()).toList());
  }

  @override
  Stream<List<TaskEntity>> getVerificationPendingTasks(String managerId) {
    return _firestoreService
        .getVerificationPendingTasks(managerId)
        .map((tasks) => tasks.map((task) => task.toEntity()).toList());
  }

  @override
  Future<void> createTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    await _firestoreService.createTask(taskModel);
  }

  @override
  Future<void> completeTask(String taskId, {File? photo}) async {
    String? photoUrl;
    if (photo != null) {
      photoUrl = await _storageService.uploadTaskPhoto(taskId, photo);
    }

    // Get task to check if submission is late
    final task = await _firestoreService.getTaskById(taskId);
    final now = DateTime.now();
    bool isLate = false;

    if (task?.dueDate != null) {
      // Check if submission is more than 15 minutes late
      final lateThreshold = task!.dueDate!.add(const Duration(minutes: 15));
      isLate = now.isAfter(lateThreshold);
    }

    await _firestoreService.updateTaskStatus(
      taskId,
      'verificationPending',
      photoUrl: photoUrl,
      completedAt: now,
      isLate: isLate,
    );
  }

  @override
  Future<void> verifyTask(
    String taskId,
    bool approved, {
    String? rejectionReason,
    File? rejectionVoiceNote,
    Uint8List? rejectionMarkedImageBytes,
  }) async {
    if (approved) {
      await _firestoreService.updateTaskStatus(taskId, 'approved');
    } else {
      String? voiceUrl;
      if (rejectionVoiceNote != null) {
        voiceUrl = await _storageService.uploadTaskRejectionVoiceNote(
            taskId, rejectionVoiceNote);
      }

      String? markedUrl;
      if (rejectionMarkedImageBytes != null) {
        markedUrl = await _storageService.uploadTaskRejectionMarkedImage(
          taskId,
          rejectionMarkedImageBytes,
        );
      }
      await _firestoreService.updateTaskStatus(
        taskId,
        'rejected',
        rejectionReason: rejectionReason,
        rejectionVoiceNoteUrl: voiceUrl,
        rejectionMarkedImageUrl: markedUrl,
        rejectedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> reworkTask(String taskId) async {
    await _firestoreService.reworkTask(taskId);
  }

  @override
  Future<void> assignTask(String taskId, String staffId) async {
    await _firestoreService.assignTask(taskId, staffId);
  }

  @override
  Future<List<TaskEntity>> getTasksBySOP(String sopId) async {
    final tasks = await _firestoreService.getTasksBySOP(sopId);
    return tasks.map((task) => task.toEntity()).toList();
  }

  @override
  Stream<List<TaskEntity>> getTaskStream(String userId, {String? status}) {
    return _firestoreService
        .getTasksStream(userId, status: status)
        .map((tasks) => tasks.map((task) => task.toEntity()).toList());
  }

  @override
  Stream<List<TaskEntity>> getAdminTasks() {
    return _firestoreService
        .getAllTasks()
        .map((list) => list.map((model) => model.toEntity()).toList());
  }
}
