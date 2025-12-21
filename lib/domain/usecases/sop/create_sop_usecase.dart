import 'package:restro/domain/entities/sop_entity.dart';
import 'package:restro/domain/repositories/sop_repository_interface.dart';

class CreateSOPUseCase {
  final SOPRepositoryInterface repository;

  CreateSOPUseCase(this.repository);

  Future<void> execute(SOPEntity sop) async{
    await repository.createSOP(sop);
  }

}