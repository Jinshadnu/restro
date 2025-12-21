import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restro/data/datasources/local/database_helper.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/data/models/user_model.dart';

/// Service to sync data between local SQLite and Firestore
class SyncService {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;

  SyncService(this._dbHelper, this._firestoreService);

  /// Sync all data from Firestore to local database
  Future<void> syncFromFirestore() async {
    try {
      // Sync users
      final firestore = FirebaseFirestore.instance;
      final usersSnapshot = await firestore.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        userData['id'] = doc.id;
        final user = AppUserModel.fromMap(userData);
        await _dbHelper.insertUser(user);
      }

      // Sync SOPs
      final sops = await _firestoreService.getSOPs();
      for (var sop in sops) {
        await _dbHelper.insertSOP(sop);
      }

      // Sync tasks
      final tasksSnapshot = await firestore.collection('tasks').get();

      for (var doc in tasksSnapshot.docs) {
        final taskData = doc.data();
        taskData['id'] = doc.id;
        final task = TaskModel.fromJson(taskData);
        await _dbHelper.insertTask(task);
        await _dbHelper.markTaskSynced(task.id);
      }
    } catch (e) {
      print('Error syncing from Firestore: $e');
    }
  }

  /// Sync unsynced tasks from local database to Firestore
  Future<void> syncToFirestore() async {
    try {
      final unsyncedTasks = await _dbHelper.getUnsyncedTasks();

      for (var task in unsyncedTasks) {
        try {
          // Check if task exists in Firestore
          final firestore = FirebaseFirestore.instance;
          final taskDoc =
              await firestore.collection('tasks').doc(task.id).get();

          if (taskDoc.exists) {
            // Update existing task
            await _firestoreService.updateTaskStatus(
              task.id,
              task.status.toString().split('.').last,
              rejectionReason: task.rejectionReason,
              photoUrl: task.photoUrl,
              completedAt: task.completedAt,
              verifiedAt: task.verifiedAt,
            );
          } else {
            // Create new task
            await _firestoreService.createTask(task);
          }

          await _dbHelper.markTaskSynced(task.id);
        } catch (e) {
          print('Error syncing task ${task.id}: $e');
        }
      }
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
  }

  /// Full sync: sync from Firestore, then sync local changes back
  Future<void> fullSync() async {
    await syncFromFirestore();
    await syncToFirestore();
  }
}
