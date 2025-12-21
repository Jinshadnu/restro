import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/screens/admin/verification_details_screen.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminVerificationListScreen extends StatelessWidget {
  const AdminVerificationListScreen({super.key});

  Future<String> _getUserName(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['name'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  Future<String> _getSOPName(String sopId) async {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('sops').doc(sopId).get();
    if (doc.exists) {
      return doc.data()?['title'] ?? 'Unknown SOP';
    }
    return 'Unknown SOP';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Verification List",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<TaskEntity>>(
        stream: () {
          final auth =
              Provider.of<AuthenticationProvider>(context, listen: false);
          final taskProvider =
              Provider.of<TaskProvider>(context, listen: false);
          if (auth.currentUser != null) {
            return taskProvider
                .getVerificationPendingTasks(auth.currentUser!.id);
          }
          return Stream.value(<TaskEntity>[]);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No tasks pending verification',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return FutureBuilder<Map<String, String>>(
                future: Future.wait([
                  _getUserName(task.assignedTo),
                  _getSOPName(task.sopid),
                ]).then((results) => {
                      'staff': results[0],
                      'sop': results[1],
                    }),
                builder: (context, userSnapshot) {
                  final staffName = userSnapshot.data?['staff'] ?? 'Unknown';
                  final sopName = userSnapshot.data?['sop'] ?? 'Unknown SOP';

                  return _verificationCard(
                    staff: staffName,
                    task: task.title,
                    sop: sopName,
                    date: task.completedAt != null
                        ? DateFormat('MMM d, y').format(task.completedAt!)
                        : 'N/A',
                    imageUrl: task.photoUrl ?? '',
                    isVerified: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerificationDetailsScreen(
                            staff: staffName,
                            task: task.title,
                            sop: sopName,
                            date: task.completedAt != null
                                ? DateFormat('MMM d, y')
                                    .format(task.completedAt!)
                                : 'N/A',
                            images:
                                task.photoUrl != null ? [task.photoUrl!] : [],
                            isVerified: false,
                            dueTime: task.dueDate ?? DateTime.now(),
                            completedTime: task.completedAt ?? DateTime.now(),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _verificationCard({
    required String staff,
    required String task,
    required String sop,
    required String date,
    required String imageUrl,
    required bool isVerified,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        isThreeLine: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 55,
            height: 55,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          task,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Staff: $staff",
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
              Text("SOP: $sop",
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              Text("Submitted On: $date",
                  style: const TextStyle(fontSize: 13, color: Colors.black45)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isVerified ? "Verified" : "Pending",
                  style: TextStyle(
                    color: isVerified ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
        onTap: onTap,
      ),
    );
  }
}
