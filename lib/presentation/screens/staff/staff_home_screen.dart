import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/presentation/widgets/dashboard_banner.dart';
import 'package:restro/presentation/widgets/status_car_ui.dart';
import 'package:restro/presentation/widgets/task_item.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/presentation/screens/staff/staff_task_screen.dart';
import 'package:restro/presentation/screens/staff/task_completed_screen.dart';
import 'package:intl/intl.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  TaskFrequency? _selectedFrequency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthenticationProvider>(context, listen: false);
      if (auth.currentUser != null) {
        // Tasks will be loaded via StreamBuilder
      }
    });
  }

  int _getTaskCount(List<TaskEntity> tasks, String status) {
    return tasks
        .where((t) => t.status.toString().split('.').last == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final staffName = auth.currentUser?.name ?? 'Staff';

    return Scaffold(
      appBar: const CustomAppbar(
        title: 'Dashboard',
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: StreamBuilder<List<TaskEntity>>(
          stream: auth.currentUser != null
              ? taskProvider.getTasksStream(auth.currentUser!.id)
              : Stream.value([]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final tasks = snapshot.data ?? [];

            // Apply frequency filter for list
            final filteredTasks = _selectedFrequency == null
                ? tasks
                : tasks
                    .where((t) => t.frequency == _selectedFrequency)
                    .toList();

            // Calculate counts based on specific statuses
            final pendingCount =
                tasks.where((t) => t.status == TaskStatus.pending).length;
            final completedCount = tasks
                .where((t) =>
                    t.status == TaskStatus.completed ||
                    t.status == TaskStatus.approved)
                .length;
            final cancelledCount =
                tasks.where((t) => t.status == TaskStatus.rejected).length;
            final totalCount = tasks.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👋 Greeting
                  Text(
                    "Hi, $staffName 👋",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Manage your daily tasks",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ NEW BANNER HERE
                  DashboardBanner(staffName: staffName),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "Task Status",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 14),

                  // ⭐ Status Grid - Counts fetched from Firestore
                  StatusOverviewCard(
                    total: totalCount,
                    pending: pendingCount,
                    completed: completedCount,
                    cancelled: cancelledCount,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "All Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 10),

                  // Frequency filter chips
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

                  // ⭐ Task list - All tasks from Firestore
                  if (filteredTasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No tasks found for selected filter',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        final taskModel = TaskModel.fromEntity(task);

                        Color statusColor;
                        switch (task.status) {
                          case TaskStatus.pending:
                            statusColor = Colors.orange;
                            break;
                          case TaskStatus.inProgress:
                            statusColor = Colors.blue;
                            break;
                          case TaskStatus.verificationPending:
                            statusColor = Colors.purple;
                            break;
                          case TaskStatus.completed:
                          case TaskStatus.approved:
                            statusColor = Colors.green;
                            break;
                          case TaskStatus.rejected:
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return GestureDetector(
                          onTap: () {
                            if (task.status == TaskStatus.pending ||
                                task.status == TaskStatus.inProgress) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StaffTaskScreen(),
                                ),
                              );
                            } else if (task.status == TaskStatus.completed ||
                                task.status == TaskStatus.approved) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TaskCompletedScreen(),
                                ),
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.taskDetails,
                                arguments: taskModel,
                              );
                            }
                          },
                          child: AnimatedTaskItem(
                            title: task.title,
                            time: task.dueDate != null
                                ? DateFormat('MMM d, h:mm a')
                                    .format(task.dueDate!)
                                : 'No deadline',
                            person: 'You',
                            statusColor: statusColor,
                            index: index,
                          ),
                        );
                      },
                    )
                ],
              ),
            );
          },
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
