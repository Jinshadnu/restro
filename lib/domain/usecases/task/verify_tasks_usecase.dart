import 'dart:io';
import 'dart:typed_data';

import 'package:restro/domain/repositories/task_repository_interface.dart';

class VerifyTaskUseCase {
  final TaskRepositoryInterface repository;

  VerifyTaskUseCase(this.repository);

  Future<void> execute(
    String taskId,
    bool approved, {
    String? rejectionReason,
    File? rejectionVoiceNote,
    Uint8List? rejectionMarkedImageBytes,
  }) async {
    await repository.verifyTask(
      taskId,
      approved,
      rejectionReason: rejectionReason,
      rejectionVoiceNote: rejectionVoiceNote,
      rejectionMarkedImageBytes: rejectionMarkedImageBytes,
    );
  }
}
