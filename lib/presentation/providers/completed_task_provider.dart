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

      String? documentId;
      List<String> assignedToValues = [];

      if (userId != null) {
        // Resolve both userId and documentId like FirestoreService.getTasksStream
        final userSnapshot = await firestore
            .collection('users')
            .where('id', isEqualTo: userId)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          documentId = userSnapshot.docs.first.id;
        }

        assignedToValues = [userId];
        if (documentId != null && documentId != userId) {
          assignedToValues.add(documentId);
        }

        // Filter by assignedTo (using whereIn only once in this query)
        if (assignedToValues.length > 1) {
          query = query.where('assignedTo', whereIn: assignedToValues);
        } else {
          query = query.where('assignedTo', isEqualTo: userId);
        }
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
            task.status == TaskStatus.approved;
      }).toList();

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
        if (task.completedAt != null) {
          _completedTasks.add(
            CompletedTaskModel(
              id: task.id,
              title: task.title,
              description: task.description,
              time:
                  'Completed at ${DateFormat('h:mm a').format(task.completedAt!)}',
              completedBy: usersMap[task.assignedTo] ?? 'Unknown',
              statusColor: Colors.green,
              frequency: task.frequency,
            ),
          );
        }
      }

      // Sort by completion time (newest first)
      _completedTasks.sort((a, b) => b.time.compareTo(a.time));
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
