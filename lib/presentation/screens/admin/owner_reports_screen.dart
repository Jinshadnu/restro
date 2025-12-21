import 'package:flutter/material.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:intl/intl.dart';

class OwnerReportsScreen extends StatelessWidget {
  OwnerReportsScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder(
        stream: _firestoreService.getAllTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final tasks = snapshot.data ?? [];

          final total = tasks.length;
          final completed = tasks
              .where((t) => t.status.toString().contains('approved'))
              .length;
          final pending = tasks
              .where((t) => t.status.toString().contains('pending'))
              .length;
          final verification = tasks
              .where((t) => t.status.toString().contains('verification'))
              .length;
          final rejected = tasks
              .where((t) => t.status.toString().contains('rejected'))
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Overall Task Summary'),
                _statRow('Total Tasks', total, Colors.blue),
                _statRow('Completed', completed, Colors.green),
                _statRow('Pending / In-Progress', pending, Colors.orange),
                _statRow('Verification Pending', verification, Colors.purple),
                _statRow('Rejected', rejected, Colors.red),
                const SizedBox(height: 20),
                _sectionTitle('Recent Tasks'),
                const SizedBox(height: 10),
                if (tasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No tasks yet'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length > 10 ? 10 : tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy h:mm a')
                                .format(task.createdAt),
                          ),
                          trailing: Text(
                            task.status.toString().split('.').last,
                            style: TextStyle(
                              color: _statusColor(task.status.toString()),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }

  Widget _statRow(String title, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15)),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('approved')) return Colors.green;
    if (status.contains('verification')) return Colors.purple;
    if (status.contains('pending') || status.contains('inprogress')) {
      return Colors.orange;
    }
    if (status.contains('rejected')) return Colors.red;
    return Colors.grey;
  }
}
