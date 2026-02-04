import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restro/domain/repositories/task_repository_interface.dart';

class TaskSubmissionController extends ChangeNotifier {
  final TaskRepositoryInterface _taskRepository;
  final String _taskId;
  final DateTime? _dueDate;

  File? _photo;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isLate = false;

  TaskSubmissionController({
    required TaskRepositoryInterface taskRepository,
    required String taskId,
    DateTime? dueDate,
  })  : _taskRepository = taskRepository,
        _taskId = taskId,
        _dueDate = dueDate {
    _checkIfLate();
  }

  File? get photo => _photo;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isLate => _isLate;

  void _checkIfLate() {
    if (_dueDate != null) {
      final now = DateTime.now();
      _isLate = now.isAfter(_dueDate.add(const Duration(minutes: 15)));
      notifyListeners();
    }
  }

  Future<void> capturePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        _photo = File(image.path);
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> submitTask() async {
    if (_photo == null) {
      _errorMessage = 'Please take a photo to complete the task';
      notifyListeners();
      return false;
    }

    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      await _taskRepository.completeTask(
        _taskId,
        photo: _photo,
      );

      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit task: ${e.toString()}';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
