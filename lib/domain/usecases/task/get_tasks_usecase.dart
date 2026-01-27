import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/domain/repositories/task_repository_interface.dart';

class GetTasksUseCase {
  final TaskRepositoryInterface repository;

  GetTasksUseCase(this.repository);

  Stream<List<TaskEntity>> execute(String userId, {String? status}) {
    return repository.getTaskStream(userId, status: status);
  }
}
