import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class EmergencyTaskCreator {
  static final Uuid _uuid = Uuid();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createSimpleTask({
    required String title,
    required String description,
    required String sopId,
    required String assignedTo,
    required String assignedBy,
    required String frequency,
    required DateTime dueDate,
    required bool requiresPhoto,
  }) async {
    try {
      final taskId = _uuid.v4();

      // Create minimal task data to avoid potential issues
      final taskData = {
        'id': taskId,
        'title': title,
        'description': description,
        'sopid': sopId,
        'assignedTo': assignedTo,
        'assignedBy': assignedBy,
        'status': 'pending',
        'frequency': frequency,
        'grade': 'normal', // Default to normal
        'dueDate': dueDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'requiresPhoto': requiresPhoto,
        // Add new fields with null/default values
        'isLate': false,
        'reward': 50.0,
        'ownerRejectionAt': null,
        'ownerRejectionReason': null,
        'rejectedBy': null,
      };

      print('Creating emergency task: $taskId');
      await _firestore.collection('tasks').doc(taskId).set(taskData);
      print('Emergency task created successfully');
    } catch (e) {
      print('Emergency task creation failed: $e');
      rethrow;
    }
  }
}
