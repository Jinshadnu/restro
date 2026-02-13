import 'package:flutter/material.dart';
import 'package:restro/data/models/completed_task_model.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedTaskProvider extends ChangeNotifier {
  final List<CompletedTaskModel> _completedTasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<CompletedTaskModel> get completedTask => _completedTasks;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadCompletedTasks({String? userId}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _completedTasks.clear();

      final firestore = FirebaseFirestore.instance;
      Query query = firestore.collection('tasks');

      if (userId != null) {
        // Keep query scoped to the logged-in staff user's id.
        // This avoids permission-denied issues from whereIn / mixed identifiers.
        query = query.where('assignedTo', isEqualTo: userId);
      }

      final tasksSnapshot = await query.get();

      final tasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TaskModel.fromJson(data);
      }).toList();

      // Filter by completed/approved status in memory
      final filteredTasks = tasks.where((task) {
        return task.status == TaskStatus.completed ||
            task.status == TaskStatus.approved ||
            task.status == TaskStatus.verificationPending;
      }).toList();

      DateTime? _doneAt(TaskModel t) {
        return t.completedAt ?? t.verifiedAt;
      }

      filteredTasks.sort((a, b) {
        final ad = _doneAt(a);
        final bd = _doneAt(b);
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

      // Get user names for completedBy
      final userIds = filteredTasks.map((t) => t.assignedTo).toSet().toList();
      final usersMap = <String, String>{};

      for (var uid in userIds) {
        final userDoc = await firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          usersMap[uid] = userData?['name'] ?? 'Unknown';
        }
      }

      // Convert to CompletedTaskModel
      for (var task in filteredTasks) {
        final doneAt = _doneAt(task);
        if (doneAt != null) {
          _completedTasks.add(
            CompletedTaskModel(
              id: task.id,
              title: task.title,
              description: task.description,
              time: 'Completed at ${DateFormat('h:mm a').format(doneAt)}',
              completedBy: usersMap[task.assignedTo] ?? 'Unknown',
              statusColor: Colors.green,
              frequency: task.frequency,
            ),
          );
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
