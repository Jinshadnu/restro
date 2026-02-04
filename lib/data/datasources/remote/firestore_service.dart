import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:restro/domain/entities/task_entity.dart';
import '../../models/task_model.dart';
import '../../models/sop_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Task operations
  Future<void> createTask(TaskModel task) async {
    try {
      print('Creating task in Firestore: ${task.id}');
      await _firestore.collection('tasks').doc(task.id).set(task.toJson());
      print('Task created successfully in Firestore');
    } catch (e) {
      print('Error creating task in Firestore: $e');
      rethrow;
    }
  }

  Future<void> createTaskFromData(Map<String, dynamic> data) async {
    final id = (data['id'] ?? '').toString();
    if (id.isEmpty) {
      throw ArgumentError('Task id is required');
    }
    await _firestore.collection('tasks').doc(id).set({...data, 'id': id});
  }

  Future<void> createTaskTemplateFromData(Map<String, dynamic> data) async {
    final id = (data['id'] ?? '').toString();
    if (id.isEmpty) {
      throw ArgumentError('Template id is required');
    }
    await _firestore
        .collection('task_templates')
        .doc(id)
        .set({...data, 'id': id}, SetOptions(merge: true));
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

  Future<List<TaskModel>> getTasksForUser(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return TaskModel.fromJson(data);
    }).toList();
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
      String? rejectionVoiceNoteUrl,
      String? rejectionMarkedImageUrl,
      DateTime? rejectedAt,
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

    if (status == 'rejected') {
      updateData['rejectedAt'] =
          (rejectedAt ?? DateTime.now()).toIso8601String();
      if (rejectionVoiceNoteUrl != null && rejectionVoiceNoteUrl.isNotEmpty) {
        updateData['rejectionVoiceNoteUrl'] = rejectionVoiceNoteUrl;
      }
      if (rejectionMarkedImageUrl != null &&
          rejectionMarkedImageUrl.isNotEmpty) {
        updateData['rejectionMarkedImageUrl'] = rejectionMarkedImageUrl;
      }
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

  Future<void> reworkTask(String taskId) async {
    print('REWORK DEBUG: Starting rework for task $taskId');
    await _firestore.collection('tasks').doc(taskId).update({
      'status': 'pending',
      'rejectionReason': null,
      'rejectionVoiceNoteUrl': null,
      'rejectionMarkedImageUrl': null,
      'rejectedAt': null,
      'photoUrl': null,
      'completedAt': null,
      'verifiedAt': null,
      'isLate': false,
    });
    print('REWORK DEBUG: Task $taskId updated to pending status');
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

    final fallbackFields = <String>['id', 'sopId', 'title'];
    for (final field in fallbackFields) {
      final snapshot = await _firestore
          .collection('sops')
          .where(field, isEqualTo: id)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return SOPModel.fromJson(data);
      }
    }

    return null;
  }

  Future<void> updateSOP(String sopId, SOPModel sop) async {
    await _firestore.collection('sops').doc(sopId).update(sop.toJson());
  }

  Future<void> deleteSOP(String id) async {
    await _firestore.collection('sops').doc(id).delete();
  }

  Future<Map<String, List<String>>> getMasterChecklist() async {
    final candidates = <MapEntry<String, String>>[
      const MapEntry<String, String>('master_checklists', 'default'),
      const MapEntry<String, String>('masterChecklist', 'default'),
      const MapEntry<String, String>('master_checklist', 'default'),
      const MapEntry<String, String>('checklists', 'master'),
    ];

    Map<String, dynamic>? data;
    for (final c in candidates) {
      final doc = await _firestore.collection(c.key).doc(c.value).get();
      if (doc.exists && doc.data() != null) {
        data = doc.data();
        break;
      }
    }

    if (data == null) return <String, List<String>>{};

    dynamic raw =
        data['categories'] ?? data['items'] ?? data['checklist'] ?? data;

    Map<String, List<String>> out = <String, List<String>>{};

    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key?.toString().trim();
        if (key == null || key.isEmpty) continue;

        final value = entry.value;
        if (value is List) {
          final items = value
              .map((e) => e?.toString().trim())
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList();
          if (items.isNotEmpty) out[key] = items;
        } else if (value is String) {
          final items = value
              .split(RegExp(r'\r?\n'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (items.isNotEmpty) out[key] = items;
        }
      }
    } else if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final category = (item['category'] ?? item['title'] ?? item['name'])
              ?.toString()
              .trim();
          if (category == null || category.isEmpty) continue;
          final list = item['items'] ?? item['steps'] ?? item['checklist'];
          if (list is List) {
            final items = list
                .map((e) => e?.toString().trim())
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .toList();
            if (items.isNotEmpty) out[category] = items;
          }
        }
      }
    }

    return out;
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

    final roleVariants = <String>['staff', 'STAFF', 'Staff'];
    final staffSnapshot = await _firestore
        .collection('users')
        .where('role', whereIn: roleVariants)
        .get();

    final totalStaff = staffSnapshot.docs.length;
    final todayDateStr = DateFormat('yyyy-MM-dd').format(todayStart);
    final todayAttendanceSnapshot = await _firestore
        .collection('attendance')
        .where('dateStr', isEqualTo: todayDateStr)
        .get();

    final attendanceByUser = <String, Map<String, dynamic>>{};
    for (final doc in todayAttendanceSnapshot.docs) {
      final data = doc.data();
      final uid = (data['userId'] ?? data['staff_id'] ?? '').toString();
      if (uid.isEmpty) continue;
      attendanceByUser[uid] = data;
    }

    int presentStaff = 0;
    int lateStaff = 0;
    for (final doc in staffSnapshot.docs) {
      final uid = doc.id;
      final att = attendanceByUser[uid];
      if (att == null) continue;
      presentStaff += 1;

      final ts = _parseDateTime(att['timestamp'] ?? att['capturedAt']);
      if (ts != null) {
        final threshold = DateTime(ts.year, ts.month, ts.day, 14)
            .add(const Duration(minutes: 15));
        if (ts.isAfter(threshold)) {
          lateStaff += 1;
        }
      }
    }

    final absentStaff = (totalStaff - presentStaff).clamp(0, totalStaff);

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
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final tasksSnapshot = await _firestore.collection('tasks').get();
    final tasks = tasksSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TaskModel.fromJson(data);
    }).toList();

    final tasksDueUpToToday = tasks.where((task) {
      final due = task.dueDate;
      if (due == null) return false;
      return due.isBefore(tomorrowStart);
    }).toList();

    final totalDueToday = tasksDueUpToToday.length;
    final approvedDueToday = tasksDueUpToToday
        .where((task) =>
            task.status == TaskStatus.approved ||
            task.status == TaskStatus.completed)
        .length;
    final compliance =
        totalDueToday > 0 ? (approvedDueToday / totalDueToday * 100) : 0.0;

    // Average verification time for tasks verified today
    final verifiedToday = tasks.where((task) {
      if (task.verifiedAt == null || task.completedAt == null) return false;
      final v = task.verifiedAt!;
      return !v.isBefore(todayStart) && v.isBefore(tomorrowStart);
    }).toList();

    double avgVerificationTime = 0.0;
    if (verifiedToday.isNotEmpty) {
      final totalTime = verifiedToday.fold<double>(
        0.0,
        (sum, task) =>
            sum +
            task.verifiedAt!.difference(task.completedAt!).inMinutes.toDouble(),
      );
      // Keep returning hours as the UI expects "hrs"
      avgVerificationTime = (totalTime / verifiedToday.length) / 60.0;
    }

    // Most frequently failed task today (manager rejection or owner override)
    final rejectedToday = tasks.where((task) {
      final managerRejectedAt = task.rejectedAt;
      final ownerRejectedAt = task.ownerRejectionAt;
      final rejectedAt = ownerRejectedAt ?? managerRejectedAt;
      if (rejectedAt == null) return false;
      return !rejectedAt.isBefore(todayStart) &&
          rejectedAt.isBefore(tomorrowStart);
    }).toList();
    final taskFailures = <String, int>{};
    for (var task in rejectedToday) {
      taskFailures[task.title] = (taskFailures[task.title] ?? 0) + 1;
    }

    final mostFailedEntry = taskFailures.entries.isNotEmpty
        ? taskFailures.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    final mostFailedTask = mostFailedEntry?.key ?? 'None';
    final mostFailedTaskCount = mostFailedEntry?.value ?? 0;

    final completedToday = tasks.where((task) {
      if (task.completedAt == null) return false;
      final c = task.completedAt!;
      final isCompletedStatus = task.status == TaskStatus.completed ||
          task.status == TaskStatus.approved;
      return isCompletedStatus &&
          !c.isBefore(todayStart) &&
          c.isBefore(tomorrowStart);
    }).length;

    final pendingTasks = tasksDueUpToToday
        .where((task) =>
            task.status == TaskStatus.pending ||
            task.status == TaskStatus.inProgress)
        .length;

    final verificationPending = tasksDueUpToToday
        .where((task) => task.status == TaskStatus.verificationPending)
        .length;

    final attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('status', isEqualTo: 'pending')
        .get();

    final attendancePendingApprovals = attendanceSnapshot.docs.length;

    final roleVariants = <String>['staff', 'STAFF', 'Staff'];
    final staffSnapshot = await _firestore
        .collection('users')
        .where('role', whereIn: roleVariants)
        .get();

    final totalStaff = staffSnapshot.docs.length;
    final todayDateStr = DateFormat('yyyy-MM-dd').format(todayStart);
    final todayAttendanceSnapshot = await _firestore
        .collection('attendance')
        .where('dateStr', isEqualTo: todayDateStr)
        .get();

    final attendanceByUser = <String, Map<String, dynamic>>{};
    for (final doc in todayAttendanceSnapshot.docs) {
      final data = doc.data();
      final uid = (data['userId'] ?? data['staff_id'] ?? '').toString();
      if (uid.isEmpty) continue;
      attendanceByUser[uid] = data;
    }

    int presentStaff = 0;
    int lateStaff = 0;
    for (final doc in staffSnapshot.docs) {
      final uid = doc.id;
      final att = attendanceByUser[uid];
      if (att == null) continue;
      presentStaff += 1;

      final ts = _parseDateTime(att['timestamp'] ?? att['capturedAt']);
      if (ts != null) {
        final threshold = DateTime(ts.year, ts.month, ts.day, 14)
            .add(const Duration(minutes: 15));
        if (ts.isAfter(threshold)) {
          lateStaff += 1;
        }
      }
    }

    final absentStaff = (totalStaff - presentStaff).clamp(0, totalStaff);

    DateTime? _parseScoreDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final type = value.runtimeType.toString();
      if (type == 'Timestamp' || type.endsWith('Timestamp')) {
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

    final allDailyScoresSnapshot =
        await _firestore.collection('daily_scores').get();
    int scoreCount = 0;
    int totalScore = 0;
    for (final doc in allDailyScoresSnapshot.docs) {
      final data = doc.data();
      final date = _parseScoreDate(data['date']);
      if (date == null) continue;
      if (date.isBefore(todayStart) || !date.isBefore(tomorrowStart)) continue;

      final v = data['finalScore'];
      int? score;
      if (v is int) score = v;
      if (v is num) score = v.toInt();
      if (score == null) continue;

      scoreCount += 1;
      totalScore += score;
    }

    double shopDailyScore = 100.0;
    if (scoreCount > 0) {
      shopDailyScore = totalScore / scoreCount;
    } else {
      shopDailyScore = compliance.clamp(0.0, 100.0);
    }

    return {
      'compliance': compliance,
      'avgVerificationTime': avgVerificationTime,
      'mostFailedTask': mostFailedTask,
      'mostFailedTaskCount': mostFailedTaskCount,
      'completedToday': completedToday,
      'pendingTasks': pendingTasks,
      'verificationPending': verificationPending,
      'attendancePendingApprovals': attendancePendingApprovals,
      'totalStaff': totalStaff,
      'presentStaff': presentStaff,
      'lateStaff': lateStaff,
      'absentStaff': absentStaff,
      'shopDailyScore': shopDailyScore,
      'shopDailyScoreCount': scoreCount,
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

  Future<void> upsertUserFcmToken({
    required String userId,
    required String token,
  }) async {
    if (userId.isEmpty || token.isEmpty) return;
    await _firestore.collection('users').doc(userId).set(
      {
        'fcm_tokens': FieldValue.arrayUnion([token]),
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<String>> getUserFcmTokens(String userId) async {
    if (userId.isEmpty) return [];
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    final raw = data?['fcm_tokens'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final single = data?['fcm_token'];
    if (single != null) {
      final t = single.toString();
      return t.isNotEmpty ? [t] : [];
    }
    return [];
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

  Stream<List<Map<String, dynamic>>> streamAttendanceForDate(String dateStr) {
    final d = dateStr.trim();
    if (d.isEmpty) return Stream.value([]);

    return _firestore
        .collection('attendance')
        .where('dateStr', isEqualTo: d)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      items.sort((a, b) {
        final aTs = _parseDateTime(a['timestamp'] ?? a['capturedAt']);
        final bTs = _parseDateTime(b['timestamp'] ?? b['capturedAt']);
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });

      return items;
    });
  }

  Stream<List<Map<String, dynamic>>> streamStaffForManager(String managerId) {
    final id = managerId.trim();
    if (id.isEmpty) return Stream.value([]);

    // Query by created_by only to avoid composite indexes; filter role client-side.
    return _firestore
        .collection('users')
        .where('created_by', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((u) {
        final role = (u['role'] ?? '').toString().toLowerCase();
        return role == 'staff';
      }).toList();

      items.sort((a, b) {
        final an = (a['name'] ?? '').toString().toLowerCase();
        final bn = (b['name'] ?? '').toString().toLowerCase();
        return an.compareTo(bn);
      });

      return items;
    });
  }

  Stream<List<Map<String, dynamic>>> streamAllStaffUsers() {
    // Single-field whereIn does not require composite indexes.
    final roleVariants = <String>[
      'staff',
      'STAFF',
      'Staff',
    ];

    return _firestore
        .collection('users')
        .where('role', whereIn: roleVariants)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      items.sort((a, b) {
        final an = (a['name'] ?? '').toString().toLowerCase();
        final bn = (b['name'] ?? '').toString().toLowerCase();
        return an.compareTo(bn);
      });

      return items;
    });
  }

  Future<void> verifyAttendance(
    String attendanceId,
    bool approved, {
    String? rejectionReason,
    String? rejectionVoiceNoteUrl,
    String? verifiedBy,
  }) async {
    final updateData = <String, dynamic>{
      'status': approved ? 'verified' : 'rejected',
      'verification_status': approved ? 'approved' : 'rejected',
      'verifiedAt': DateTime.now().toIso8601String(),
    };

    if (verifiedBy != null) {
      updateData['verifiedBy'] = verifiedBy;
    }

    if (!approved) {
      updateData['rejectedAt'] = DateTime.now().toIso8601String();
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }
      if (rejectionVoiceNoteUrl != null) {
        updateData['rejectionVoiceNoteUrl'] = rejectionVoiceNoteUrl;
      }
    }

    await _firestore
        .collection('attendance')
        .doc(attendanceId)
        .update(updateData);
  }

  // Staff Roles operations
  Future<List<String>> getStaffRoles() async {
    final snapshot = await _firestore.collection('staff_roles').get();
    return snapshot.docs
        .map((doc) => doc.data()['name']?.toString().trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> addStaffRole(String name, {String? createdBy}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Role name cannot be empty');
    final docId = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    await _firestore.collection('staff_roles').doc(docId).set({
      'name': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      if (createdBy != null) 'createdBy': createdBy,
    });
  }

  Future<void> deleteStaffRole(String name) async {
    final docId = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    await _firestore.collection('staff_roles').doc(docId).delete();
  }
}
