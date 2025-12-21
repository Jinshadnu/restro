
import 'package:restro/domain/repositories/task_repository_interface.dart';

class VerifyTaskUseCase {
  final TaskRepositoryInterface repository;

  VerifyTaskUseCase(this.repository);

  Future<void> execute(String taskId, bool approved, {String? rejectionReason}) async {
    await repository.verifyTask(taskId, approved, rejectionReason: rejectionReason);
  }
}

