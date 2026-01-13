import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restro/domain/entities/task_entity.dart';
import '../../models/task_model.dart';
import '../../models/sop_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Task operations
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toJson());
  }

  Future<void> createTaskFromData(Map<String, dynamic> data) async {
    final id = (data['id'] ?? '').toString();
    if (id.isEmpty) {
      throw ArgumentError('Task id is required');
    }
    await _firestore.collection('tasks').doc(id).set({...data, 'id': id});
  }

  Stream<List<TaskModel>> getTasksStream(String userId, {String? status}) {
    Query query =
        _firestore.collection('tasks').where('assignedTo', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TaskModel.fromJson(data);
      }).toList();
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
      DateTime? verifiedAt,
      bool? isLate}) async {
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

    if (isLate != null) {
      updateData['isLate'] = isLate;
    }

    await _firestore.collection('tasks').doc(taskId).update(updateData);
  }

  Future<void> assignTask(String taskId, String staffId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'assignedTo': staffId,
      'status': 'pending',
    });
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _firestore.collection('tasks').doc(taskId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return TaskModel.fromJson(data);
    }
    return null;
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
          final data = doc.data();
          data['id'] = doc.id;
          sops.add(SOPModel.fromJson(data));
        } catch (e) {
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

    final attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('status', isEqualTo: 'pending')
        .get();

    final attendancePendingApprovals = attendanceSnapshot.docs.length;

    double healthScore = 100.0;
    healthScore -= pendingTasks * 2;
    healthScore -= verificationPending * 3;
    healthScore -= attendancePendingApprovals * 1;
    healthScore = healthScore.clamp(0.0, 100.0);

    return {
      'completedToday': completedToday,
      'pendingTasks': pendingTasks,
      'verificationPending': verificationPending,
      'attendancePendingApprovals': attendancePendingApprovals,
      'healthScore': healthScore,
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

  Future<Map<String, String>> getUserIdNameMap() async {
    final snapshot = await _firestore.collection('users').get();
    final map = <String, String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] ?? data['fullName'] ?? 'Unknown').toString();

      // Map document ID
      map[doc.id] = name;

      // Map explicit 'id' field if present (some parts of app use this)
      final fieldId = data['id'];
      if (fieldId != null) {
        final key = fieldId.toString();
        if (key.isNotEmpty) {
          map[key] = name;
        }
      }
    }

    return map;
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final roleVariants = <String>{
      role,
      role.toLowerCase(),
      role.toUpperCase(),
      '${role[0].toUpperCase()}${role.substring(1).toLowerCase()}',
    }.toList();

    final snapshot = await _firestore
        .collection('users')
        .where('role', whereIn: roleVariants)
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

  Future<List<Map<String, dynamic>>> getStaffForManager(
      String managerId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('created_by', isEqualTo: managerId)
        .get();

    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['id'] == null) {
        data['id'] = doc.id;
      }
      data['documentId'] = doc.id;
      return data;
    }).toList();

    return users
        .where(
          (u) => (u['role'] ?? '').toString().toLowerCase() == 'staff',
        )
        .toList();
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

  Future<void> syncAttendance(Map<String, dynamic> data) async {
    await _firestore
        .collection('attendance')
        .doc(data['id'])
        .set(data, SetOptions(merge: true));
  }

  // Attendance operations
  Future<void> createAttendance(Map<String, dynamic> attendanceData) async {
    await _firestore
        .collection('attendance')
        .doc(attendanceData['id'])
        .set(attendanceData);
  }

  Future<QuerySnapshot> getTodayAttendance(String userId) async {
    try {
      // Get today's date at midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Prefer deterministic documentId to avoid composite index requirements.
      // Our app writes attendance as: <uid>_YYYY-MM-DD
      final docId = '${userId}_$dateStr';

      // Return as QuerySnapshot for compatibility with existing callers.
      // This query does NOT require a composite index.
      return await _firestore
          .collection('attendance')
          .where(FieldPath.documentId, isEqualTo: docId)
          .limit(1)
          .get();
    } on FirebaseException catch (e) {
      print('Firebase Error in getTodayAttendance: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error in getTodayAttendance: $e');
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unknown-error',
        message: e.toString(),
      );
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final tsType = value.runtimeType.toString();
    if (tsType == 'Timestamp' || tsType.endsWith('Timestamp')) {
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Stream<List<Map<String, dynamic>>> getPendingAttendances(String managerId) {
    return _firestore
        .collection('attendance')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      items.sort((a, b) {
        final aTs = _parseDateTime(a['timestamp']);
        final bTs = _parseDateTime(b['timestamp']);
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });

      return items;
    });
  }

  Future<void> verifyAttendance(String attendanceId, bool approved,
      {String? rejectionReason, String? verifiedBy}) async {
    final updateData = <String, dynamic>{
      'status': approved ? 'verified' : 'rejected',
      'verification_status': approved ? 'approved' : 'rejected',
      'verifiedAt': DateTime.now().toIso8601String(),
    };

    if (verifiedBy != null) {
      updateData['verifiedBy'] = verifiedBy;
    }

    if (!approved && rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }

    await _firestore
        .collection('attendance')
        .doc(attendanceId)
        .update(updateData);
  }
}
