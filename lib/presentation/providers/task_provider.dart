import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restro/data/repositories/task_repository.dart';
import 'package:restro/domain/usecases/task/get_tasks_usecase.dart';
import 'package:restro/domain/usecases/task/complete_task_usecase.dart';
import 'package:restro/domain/usecases/task/verify_tasks_usecase.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/services/daily_scoring_engine.dart';
import 'package:restro/domain/entities/task_entity.dart';
import '../../data/datasources/remote/firebase_storage_service.dart';
import 'dart:io';
import 'dart:typed_data';

class TaskProvider with ChangeNotifier {
  final GetTasksUseCase _getTasksUseCase;
  final CompleteTaskUseCase _completeTaskUseCase;
  final VerifyTaskUseCase _verifyTaskUseCase;
  final FirestoreService _firestoreService = FirestoreService();

  TaskProvider()
      : _getTasksUseCase = GetTasksUseCase(
          TaskRepository(FirestoreService(), FirebaseStorageService()),
        ),
        _completeTaskUseCase = CompleteTaskUseCase(
          TaskRepository(FirestoreService(), FirebaseStorageService()),
        ),
        _verifyTaskUseCase = VerifyTaskUseCase(
          TaskRepository(FirestoreService(), FirebaseStorageService()),
        );

  final List<TaskEntity> _tasks = [];
  bool _isLoading = false;
  bool _isLoadingDashboard = false;
  String _errorMessage = '';
  File? _selectedImage;
  Map<String, dynamic> _managerDashboardData = {};

  List<TaskEntity> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String get errorMessage => _errorMessage;
  File? get selectedImage => _selectedImage;
  Map<String, dynamic> get managerDashboardData => _managerDashboardData;

  Stream<List<TaskEntity>> getTasksStream(String userId, {String? status}) {
    return _getTasksUseCase.execute(userId, status: status);
  }

  Future<void> reworkTask(String taskId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final repository = TaskRepository(
        FirestoreService(),
        FirebaseStorageService(),
      );
      await repository.reworkTask(taskId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Stream<List<TaskEntity>> getVerificationPendingTasks(String managerId) {
    final repository = TaskRepository(
      FirestoreService(),
      FirebaseStorageService(),
    );
    return repository.getVerificationPendingTasks(managerId);
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        _selectedImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  Future<void> completeTask(String taskId, {File? photo}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _completeTaskUseCase.execute(taskId, photo: photo);
      _isLoading = false;
      _selectedImage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> verifyTask(
    String taskId,
    bool approved, {
    String? rejectionReason,
    File? rejectionVoiceNote,
    Uint8List? rejectionMarkedImageBytes,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _verifyTaskUseCase.execute(
        taskId,
        approved,
        rejectionReason: rejectionReason,
        rejectionVoiceNote: rejectionVoiceNote,
        rejectionMarkedImageBytes: rejectionMarkedImageBytes,
      );

      // After manager approval/rejection, refresh the assigned staff's daily score
      // so staff dashboard reflects changes immediately.
      final updatedTask = await _firestoreService.getTaskById(taskId);
      if (updatedTask != null) {
        final scoringEngine = DailyScoringEngine();
        await scoringEngine.handleTaskStatusChange(taskId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadManagerDashboard(String userId) async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      final data = await _firestoreService.getManagerDashboard(userId);
      _managerDashboardData = data;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingDashboard = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
