import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restro/domain/entities/task_entity.dart';
import '../../models/task_model.dart';
import '../../models/sop_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Task operations
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toJson());
  }

  Stream<List<TaskModel>> getTasksStream(String userId, {String? status}) {
    // Get user document to find both the 'id' field and document ID
    // Tasks might be assigned using either format, so we need to check both
    return _firestore
        .collection('users')
        .where('id', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .asyncExpand((userSnapshot) {
      String? documentId;
      if (userSnapshot.docs.isNotEmpty) {
        documentId = userSnapshot
            .docs.first.id; // e.g., "staff_FI4ga4zsb7Y8tn80m9xAJ5YyMv72"
      }

      // Query tasks where assignedTo matches either userId or documentId
      final List<String> assignedToValues = [userId];
      if (documentId != null && documentId != userId) {
        assignedToValues.add(documentId);
      }

      Query query = _firestore.collection('tasks');

      // Use 'whereIn' if we have multiple values, otherwise use 'isEqualTo'
      if (assignedToValues.length > 1) {
        query = query.where('assignedTo', whereIn: assignedToValues);
      } else {
        query = query.where('assignedTo', isEqualTo: userId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Return stream of task changes
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return TaskModel.fromJson(data);
        }).toList();
      });
    });
  }

  Stream<List<TaskModel>> getVerificationPendingTasks(String managerId) {
    return _firestore
        .collection('tasks')
        .where('assignedBy', isEqualTo: managerId)
        .where('status', isEqualTo: 'verificationPending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TaskModel.fromJson(data);
      }).toList();
    });
  }

  Future<void> updateTaskStatus(String taskId, String status,
      {String? rejectionReason,
      String? photoUrl,
      DateTime? completedAt,
      DateTime? verifiedAt}) async {
    final updateData = <String, dynamic>{
      'status': status,
    };

    if (status == 'rejected' && rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }

    if (status == 'approved') {
      updateData['verifiedAt'] =
          (verifiedAt ?? DateTime.now()).toIso8601String();
    }

    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }

    if (completedAt != null) {
      updateData['completedAt'] = completedAt.toIso8601String();
    }

    await _firestore.collection('tasks').doc(taskId).update(updateData);
  }

  Future<void> assignTask(String taskId, String staffId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'assignedTo': staffId,
      'status': 'pending',
    });
  }

  Future<List<TaskModel>> getTasksBySOP(String sopId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('sopid', isEqualTo: sopId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TaskModel.fromJson(data);
    }).toList();
  }

  // SOP operations
  Future<void> createSOP(SOPModel sop) async {
    await _firestore.collection('sops').doc(sop.id).set(sop.toJson());
  }

  Future<List<SOPModel>> getSOPs() async {
    try {
      final snapshot = await _firestore.collection('sops').get();
      final List<SOPModel> sops = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final sop = SOPModel.fromJson(data);
          sops.add(sop);
        } catch (e) {
          // Log error for individual SOP but continue loading others
          print('Error parsing SOP document ${doc.id}: $e');
        }
      }

      return sops;
    } catch (e) {
      print('Error fetching SOPs from Firestore: $e');
      rethrow;
    }
  }

  Future<SOPModel?> getSOPById(String id) async {
    final doc = await _firestore.collection('sops').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return SOPModel.fromJson(data);
    }
    return null;
  }

  Future<void> updateSOP(String sopId, SOPModel sop) async {
    await _firestore.collection('sops').doc(sopId).update(sop.toJson());
  }

  Future<void> deleteSOP(String id) async {
    await _firestore.collection('sops').doc(id).delete();
  }

  Future<List<SOPModel>> getSOPsByFrequency(String frequency) async {
    final snapshot = await _firestore
        .collection('sops')
        .where('frequency', isEqualTo: frequency)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SOPModel.fromJson(data);
    }).toList();
  }

  // Dashboard data
  Future<Map<String, dynamic>> getManagerDashboard(String userId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Get all tasks assigned by this user (admin/manager)
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('assignedBy', isEqualTo: userId) // 🔥 FIXED: userId, not role
        .get();

    final tasks = tasksSnapshot.docs
        .map((doc) => TaskModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    final completedToday = tasks
        .where((task) =>
            task.status == TaskStatus.approved &&
            task.completedAt != null &&
            task.completedAt!.isAfter(todayStart))
        .length;

    final pendingTasks = tasks
        .where((task) =>
            task.status == TaskStatus.pending ||
            task.status == TaskStatus.inProgress)
        .length;

    final verificationPending = tasks
        .where((task) => task.status == TaskStatus.verificationPending)
        .length;

    return {
      'completedToday': completedToday,
      'pendingTasks': pendingTasks,
      'verificationPending': verificationPending,
      'totalTasks': tasks.length,
    };
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final tasksSnapshot = await _firestore.collection('tasks').get();

    final tasks = tasksSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TaskModel.fromJson(data);
    }).toList();

    final totalTasks = tasks.length;

    final pendingTasks = tasks
        .where((task) =>
            task.status == TaskStatus.pending ||
            task.status == TaskStatus.inProgress)
        .length;

    final completed =
        tasks.where((task) => task.status == TaskStatus.approved).length;

    final verificationPending = tasks
        .where((task) => task.status == TaskStatus.verificationPending)
        .length;

    return {
      'totalTasks': totalTasks,
      'pendingTasks': pendingTasks,
      'completed': completed,
      'verificationPending': verificationPending,
    };
  }

  Future<Map<String, dynamic>> getOwnerDashboard() async {
    final tasksSnapshot = await _firestore.collection('tasks').get();
    final tasks = tasksSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TaskModel.fromJson(data);
    }).toList();

    final totalTasks = tasks.length;
    final approvedTasks =
        tasks.where((task) => task.status == TaskStatus.approved).length;
    final compliance =
        totalTasks > 0 ? (approvedTasks / totalTasks * 100) : 0.0;

    // Calculate average verification time
    final verifiedTasks = tasks
        .where((task) => task.verifiedAt != null && task.completedAt != null)
        .toList();

    double avgVerificationTime = 0.0;
    if (verifiedTasks.isNotEmpty) {
      final totalTime = verifiedTasks.fold<double>(
        0.0,
        (sum, task) =>
            sum +
            task.verifiedAt!.difference(task.completedAt!).inHours.toDouble(),
      );
      avgVerificationTime = totalTime / verifiedTasks.length;
    }

    // Most frequently failed task
    final rejectedTasks =
        tasks.where((task) => task.status == TaskStatus.rejected).toList();
    final taskFailures = <String, int>{};
    for (var task in rejectedTasks) {
      taskFailures[task.title] = (taskFailures[task.title] ?? 0) + 1;
    }

    final mostFailedTask = taskFailures.entries.isNotEmpty
        ? taskFailures.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

    return {
      'compliance': compliance,
      'avgVerificationTime': avgVerificationTime,
      'mostFailedTask': mostFailedTask,
    };
  }

  Stream<List<TaskModel>> getAllTasks() {
    return FirebaseFirestore.instance
        .collection("tasks")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final taskData = {...data, 'id': doc.id}; // create a new map with id
        return TaskModel.fromJson(taskData);
      }).toList();
    });
  }

  // User operations
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Use the 'id' field from the document (not the document ID)
      // This ensures tasks are assigned with the correct user ID format
      if (data['id'] == null) {
        // Fallback to document ID if 'id' field doesn't exist
        data['id'] = doc.id;
      }
      // Also include documentId for reference if needed
      data['documentId'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

}
