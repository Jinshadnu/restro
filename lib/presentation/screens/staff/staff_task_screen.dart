import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/shimmer.dart';
import 'package:restro/presentation/widgets/animated_task_card.dart';
import 'package:restro/presentation/widgets/critical_compliance_blocker.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/services/critical_compliance_service.dart';
import 'package:restro/utils/theme/theme.dart';

class StaffTaskScreen extends StatefulWidget {
  const StaffTaskScreen({super.key});

  @override
  State<StaffTaskScreen> createState() => _StaffTaskScreenState();
}

class _StaffTaskScreenState extends State<StaffTaskScreen> {
  TaskFrequency? _selectedFrequency;
  final CriticalComplianceService _complianceService =
      CriticalComplianceService();
  List<TaskEntity> _incompleteCriticalTasks = [];
  bool _isLoadingCritical = false;
  Stream<List<TaskEntity>>? _pendingTasksStream;
  String? _streamUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthenticationProvider>(context, listen: false);
      final userId = auth.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        await _checkCriticalTasks(userId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthenticationProvider>(context);
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    if (_streamUserId == userId && _pendingTasksStream != null) return;

    _streamUserId = userId;
    print(
        'PENDING TASKS DEBUG: Setting up stream for userId: $userId, status: pending');
    _pendingTasksStream = Provider.of<TaskProvider>(context, listen: false)
        .getTasksStream(userId, status: 'pending');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _checkCriticalTasks(userId);
    });
  }

  Future<void> _checkCriticalTasks(String userId) async {
    if (_isLoadingCritical) return;
    setState(() => _isLoadingCritical = true);
    try {
      final incompleteCritical =
          await _complianceService.getIncompleteCriticalTasks(userId);
      if (mounted) {
        setState(() => _incompleteCriticalTasks = incompleteCritical);
      }
    } catch (_) {
      // Fail-safe: do nothing
    } finally {
      if (mounted) setState(() => _isLoadingCritical = false);
    }
  }

  bool _isBlockedByCritical(TaskEntity selectedTask) {
    // Allow opening critical tasks even when critical compliance is pending.
    if (selectedTask.grade == TaskGrade.critical) return false;
    return _incompleteCriticalTasks.isNotEmpty;
  }

  Future<void> _showCriticalPendingMessage() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action Blocked'),
        content: const Text(
          'CRITICAL TASK IS PENDING. PLEASE COMPLETE IT BEFORE PROCEEDING.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: const Text('Pending Tasks'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingCritical
          ? const TaskShimmer()
          : (_incompleteCriticalTasks.isNotEmpty
              ? CriticalComplianceBlocker(
                  incompleteTasks: _incompleteCriticalTasks,
                )
              : StreamBuilder<List<TaskEntity>>(
                  stream:
                      _pendingTasksStream ?? Stream.value(const <TaskEntity>[]),
                  builder: (context, snapshot) {
                    print(
                        'PENDING TASKS DEBUG: StreamBuilder snapshot: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
                    if (snapshot.hasData) {
                      final tasks = snapshot.data ?? [];
                      print(
                          'PENDING TASKS DEBUG: Received ${tasks.length} tasks');
                      for (final task in tasks) {
                        print(
                            'PENDING TASKS DEBUG: Task - ID: ${task.id}, Status: ${task.status}, Title: ${task.title}');
                      }
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const TaskShimmer();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading tasks',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final tasks = snapshot.data ?? [];

                    final filtered = _selectedFrequency == null
                        ? tasks
                        : tasks
                            .where((t) => t.frequency == _selectedFrequency)
                            .toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Tasks',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${filtered.length} task${filtered.length == 1 ? '' : 's'} pending',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.92),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Filter chips
                          _buildSectionHeader(
                              'Filter by Frequency', Icons.filter_list),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(null, "All"),
                                const SizedBox(width: 8),
                                _buildFilterChip(TaskFrequency.daily, "Daily"),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                    TaskFrequency.weekly, "Weekly"),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                    TaskFrequency.monthly, "Monthly"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (filtered.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.black.withOpacity(0.06)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pending tasks',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'All caught up! Great job!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final task = filtered[index];
                                final taskModel = TaskModel.fromEntity(task);
                                return GestureDetector(
                                  onTap: () async {
                                    if (_isBlockedByCritical(task)) {
                                      await _showCriticalPendingMessage();
                                      return;
                                    }
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.taskDetails,
                                      arguments: taskModel,
                                    );
                                  },
                                  child: AnimatedTaskCard(
                                    task: taskModel,
                                    index: index,
                                    onTap: () async {
                                      if (_isBlockedByCritical(task)) {
                                        await _showCriticalPendingMessage();
                                        return;
                                      }
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.taskDetails,
                                        arguments: taskModel,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                )),
    );
  }

  Widget _buildFilterChip(TaskFrequency? value, String label) {
    final isSelected = _selectedFrequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppTheme.primaryColor.withOpacity(0.14),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.4)
            : Colors.black.withOpacity(0.10),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onSelected: (_) {
        setState(() {
          _selectedFrequency = value;
        });
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
