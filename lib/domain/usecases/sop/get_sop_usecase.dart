import 'package:restro/domain/entities/sop_entity.dart';
import 'package:restro/domain/repositories/sop_repository_interface.dart';

class GetSOPsUseCase {
  final SOPRepositoryInterface repository;

  GetSOPsUseCase(this.repository);

  Future<List<SOPEntity>> execute() async {
    return await repository.getSOPs();
  }
}

