import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/presentation/widgets/shimmer.dart';
import 'package:restro/presentation/widgets/animated_task_card.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/data/models/task_model.dart';

class StaffTaskScreen extends StatefulWidget {
  const StaffTaskScreen({super.key});

  @override
  State<StaffTaskScreen> createState() => _StaffTaskScreenState();
}

class _StaffTaskScreenState extends State<StaffTaskScreen> {
  TaskFrequency? _selectedFrequency;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: const CustomAppbar(title: 'Pending Tasks'),
      body: StreamBuilder<List<TaskEntity>>(
        stream: auth.currentUser != null
            ? taskProvider.getTasksStream(
                auth.currentUser!.id,
                status: 'pending',
              )
            : Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const TaskShimmer();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final tasks = snapshot.data ?? [];

          final filtered = _selectedFrequency == null
              ? tasks
              : tasks.where((t) => t.frequency == _selectedFrequency).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  "No pending tasks for selected filter 🎉",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }

          return Padding(
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
                      _buildFilterChip(TaskFrequency.monthly, "Monthly"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      final taskModel = TaskModel.fromEntity(task);
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.taskDetails,
                            arguments: taskModel,
                          );
                        },
                        child: AnimatedTaskCard(
                          task: taskModel,
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
