
import 'dart:io';

import 'package:restro/domain/repositories/task_repository_interface.dart';

class CompleteTaskUseCase {
  final TaskRepositoryInterface repository;

  CompleteTaskUseCase(this.repository);

  Future<void> execute(String taskId, {File? photo}) async {
    await repository.completeTask(taskId, photo: photo);
  }
}

