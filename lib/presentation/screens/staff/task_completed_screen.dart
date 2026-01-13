import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/completed_task_provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/animated_completed_task.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/domain/entities/task_entity.dart';

class TaskCompletedScreen extends StatefulWidget {
  const TaskCompletedScreen({super.key});

  @override
  State<TaskCompletedScreen> createState() => _TaskCompletedScreenState();
}

class _TaskCompletedScreenState extends State<TaskCompletedScreen> {
  TaskFrequency? _selectedFrequency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthenticationProvider>(context, listen: false);
      final completedProvider =
          Provider.of<CompletedTaskProvider>(context, listen: false);
      if (auth.currentUser != null) {
        completedProvider.loadCompletedTasks(userId: auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedProvider = Provider.of<CompletedTaskProvider>(context);
    final tasks = completedProvider.completedTask;

    final filtered = _selectedFrequency == null
        ? tasks
        : tasks.where((t) => t.frequency == _selectedFrequency).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppbar(title: 'Completed Tasks'),
      body: completedProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No completed tasks for selected filter',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final auth = Provider.of<AuthenticationProvider>(context,
                        listen: false);
                    if (auth.currentUser != null) {
                      await completedProvider.loadCompletedTasks(
                        userId: auth.currentUser!.id,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(null, "All"),
                              const SizedBox(width: 8),
                              _buildFilterChip(TaskFrequency.daily, "Daily"),
                              const SizedBox(width: 8),
                              _buildFilterChip(TaskFrequency.weekly, "Weekly"),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                  TaskFrequency.monthly, "Monthly"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final task = filtered[index];
                              return GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task already completed'),
                                    ),
                                  );
                                },
                                child: AnimatedCompletedTask(
                                  task: task,
                                  index: index,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterChip(TaskFrequency? value, String label) {
    final isSelected = _selectedFrequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFrequency = value;
        });
      },
    );
  }
}
