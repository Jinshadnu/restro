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
import 'package:restro/utils/theme/theme.dart';
import 'package:intl/intl.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  TaskFrequency? _selectedFrequency;
  bool _showTodayTasks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double _calculatePotentialEarnings(List<TaskEntity> tasks) {
    double total = 0;
    for (var task in tasks) {
      if (task.status == TaskStatus.pending ||
          task.status == TaskStatus.inProgress ||
          task.status == TaskStatus.verificationPending) {
        // Use task.reward if available, otherwise default to 50.0
        total += task.reward ?? 50.0;
      }
    }
    return total;
  }

  bool _isFutureTask(TaskEntity task) {
    if (task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate =
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    return taskDate.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: const CustomAppbar(
        title: 'Dashboard',
      ),
      backgroundColor: AppTheme.backGroundColor,
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

            // Calculate Potential Earnings
            final potentialEarnings = _calculatePotentialEarnings(tasks);

            // Apply filters for list
            List<TaskEntity> filteredTasks = tasks;

            // Apply "Today" filter if selected
            if (_showTodayTasks) {
              filteredTasks =
                  filteredTasks.where((t) => _isToday(t.dueDate)).toList();
            }

            // Apply frequency filter if selected (and not filtering by today)
            if (!_showTodayTasks && _selectedFrequency != null) {
              filteredTasks = filteredTasks
                  .where((t) => t.frequency == _selectedFrequency)
                  .toList();
            }

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
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 💰 Potential Earnings Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.78),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Potential Earnings",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${potentialEarnings.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ NEW BANNER HERE
                  const DashboardBanner(),

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

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(null, "All"),
                        const SizedBox(width: 8),
                        _buildTodayFilterChip("Today"),
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
                        final isFuture = _isFutureTask(task);

                        Color statusColor;
                        if (isFuture) {
                          statusColor = Colors.grey; // Future tasks are grey
                        } else {
                          switch (task.status) {
                            case TaskStatus.pending:
                              statusColor = Colors.orange; // Bright Orange
                              break;
                            case TaskStatus.inProgress:
                              statusColor = Colors.blue; // Bright Blue
                              break;
                            case TaskStatus.verificationPending:
                              statusColor = Colors.purple; // Bright Purple
                              break;
                            case TaskStatus.completed:
                            case TaskStatus.approved:
                              statusColor = Colors.green; // Green
                              break;
                            case TaskStatus.rejected:
                              statusColor = Colors.red; // Red
                              break;
                            default:
                              statusColor = Colors.grey;
                          }
                        }

                        // Determine if task interaction should be locked (optional, based on req)
                        // Requirement says "Grey/Locked for Future".
                        // We will visually indicate it, but maybe allow tap to see details?
                        // Let's keep tap enabled but showing it as grey.

                        final bool isCompletedState =
                            task.status == TaskStatus.completed ||
                                task.status == TaskStatus.approved;
                        final DateTime? lateCutoff =
                            task.plannedEndAt ?? task.dueDate;
                        final bool isLateComputed = !isCompletedState &&
                            !isFuture &&
                            lateCutoff != null &&
                            DateTime.now().isAfter(lateCutoff);
                        final bool showLate = task.isLate || isLateComputed;

                        final String statusLabel = isFuture
                            ? 'Future'
                            : (showLate
                                ? 'Late'
                                : task.status.toString().split('.').last);

                        return AnimatedTaskItem(
                          title: task.title,
                          time: (task.plannedStartAt != null &&
                                  task.plannedEndAt != null)
                              ? "${DateFormat('MMM d, h:mm a').format(task.plannedStartAt!)} - ${DateFormat('h:mm a').format(task.plannedEndAt!)}"
                              : (task.dueDate != null
                                  ? DateFormat('MMM d, h:mm a')
                                      .format(task.dueDate!)
                                  : 'No deadline'),
                          person: statusLabel,
                          statusColor: statusColor,
                          index: index,
                          status: isFuture
                              ? 'Future'
                              : task.status.toString().split('.').last,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.taskDetails,
                              arguments: taskModel,
                            );
                          },
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
    final isSelected = !_showTodayTasks && _selectedFrequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _showTodayTasks = false;
          _selectedFrequency = value;
        });
      },
    );
  }

  Widget _buildTodayFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _showTodayTasks,
      onSelected: (_) {
        setState(() {
          _showTodayTasks = !_showTodayTasks;
          if (_showTodayTasks) {
            _selectedFrequency =
                null; // Clear frequency filter when Today is selected
          }
        });
      },
    );
  }
}
