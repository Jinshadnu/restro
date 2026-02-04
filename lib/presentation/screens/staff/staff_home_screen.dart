import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/presentation/widgets/status_car_ui.dart';
import 'package:restro/presentation/widgets/task_item.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/presentation/providers/daily_score_provider.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/services/critical_compliance_service.dart';
import 'package:restro/presentation/widgets/dashboard_section_header.dart';
import 'package:intl/intl.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  TaskFrequency? _selectedFrequency;
  bool _showTodayTasks = false;
  final CriticalComplianceService _complianceService =
      CriticalComplianceService();
  List<TaskEntity> _incompleteCriticalTasks = [];
  bool _isLoadingCritical = false;

  static const int _pageSize = 10;
  int _visibleTaskCount = _pageSize;

  void _resetPagination() {
    _visibleTaskCount = _pageSize;
  }

  void _loadMore() {
    setState(() {
      _visibleTaskCount += _pageSize;
    });
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

  bool _isBlockedByCritical(TaskEntity selectedTask) {
    // Allow opening critical tasks even when critical compliance is pending.
    if (selectedTask.grade == TaskGrade.critical) return false;

    // If there is any incomplete critical task, block selecting non-critical tasks.
    return _incompleteCriticalTasks.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthenticationProvider>(context, listen: false);
      if (auth.currentUser != null) {
        // Check critical tasks
        await _checkCriticalTasks(auth.currentUser!.id);

        if (!mounted) return;
        await Provider.of<DailyScoreProvider>(context, listen: false)
            .loadToday(auth.currentUser!.id);
      }
    });
  }

  String _scoreStatusLabel(int score) {
    if (score >= 95) return 'Excellent';
    if (score >= 85) return 'Good';
    if (score >= 75) return 'Satisfactory';
    if (score >= 60) return 'Needs Improvement';
    return 'Poor';
  }

  Future<void> _showDailyScoreDetails(DailyScoreProvider provider) async {
    final score = provider.today;
    const baseScore = 100;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Today\'s Score Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                score == null
                    ? 'Base Score: $baseScore/100'
                    : 'Score: ${score.finalScore}/100 (${score.status})',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (score == null) ...[
                const Text('Final score is not calculated yet.'),
              ] else if (score.deductions.isEmpty) ...[
                Text('Base Score: ${score.baseScore}/100'),
                const SizedBox(height: 6),
                const Text('No deductions for today.'),
              ] else ...[
                Text('Base Score: ${score.baseScore}/100'),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: score.deductions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final d = score.deductions[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              d.description,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${d.points}',
                            style: TextStyle(
                              color: d.points < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int _getTaskCount(List<TaskEntity> tasks, String status) {
    return tasks.where((t) => _getHumanReadableStatus(t) == status).length;
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

  Future<void> _checkCriticalTasks(String userId) async {
    if (_isLoadingCritical) return;

    setState(() => _isLoadingCritical = true);
    try {
      final incompleteCritical =
          await _complianceService.getIncompleteCriticalTasks(userId);
      if (mounted) {
        setState(() => _incompleteCriticalTasks = incompleteCritical);
      }
    } catch (e) {
      print('Error checking critical tasks: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCritical = false);
      }
    }
  }

  String _getHumanReadableStatus(TaskEntity task) {
    // Return human-readable status based on task status first
    // Check if task is completed but late (completed after 15+ minutes past due time)
    switch (task.status) {
      case TaskStatus.completed:
      case TaskStatus.approved:
        return 'Completed';
      case TaskStatus.verificationPending:
        // Verification pending tasks should show as "Verification Pending" regardless of timing
        return 'Verification Pending';
      case TaskStatus.pending:
        // Check if pending task is late (past due date)
        final DateTime? lateCutoff = task.plannedEndAt ?? task.dueDate;
        final bool isLateComputed =
            lateCutoff != null && DateTime.now().isAfter(lateCutoff);
        final bool showLate = task.isLate || isLateComputed;

        if (showLate) {
          return 'Late';
        }
        return 'Pending';
      case TaskStatus.inProgress:
        // Check if in-progress task is late (past due date)
        final DateTime? lateCutoff = task.plannedEndAt ?? task.dueDate;
        final bool isLateComputed =
            lateCutoff != null && DateTime.now().isAfter(lateCutoff);
        final bool showLate = task.isLate || isLateComputed;

        if (showLate) {
          return 'Late';
        }
        return 'In Progress';
      case TaskStatus.rejected:
        return 'Rejected';
      default:
        // For any other status, check if it's late
        final DateTime? lateCutoff = task.plannedEndAt ?? task.dueDate;
        final bool isLateComputed =
            lateCutoff != null && DateTime.now().isAfter(lateCutoff);
        final bool showLate = task.isLate || isLateComputed;

        if (showLate) {
          return 'Late';
        }
        return task.status.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _refreshData();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
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

            final dailyScoreProvider =
                Provider.of<DailyScoreProvider>(context, listen: true);

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
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE').format(DateTime.now()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMMM d, yyyy')
                                        .format(DateTime.now()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              child: Text(
                                DateFormat('d').format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 86,
                                  height: 64,
                                  color: Colors.white.withOpacity(0.16),
                                  child: Image.asset(
                                    'assets/images/banner_illustration.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome!',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "Let's schedule your tasks\nand manage daily workflow.",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Container(
                        //   width: double.infinity,
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 14,
                        //     vertical: 12,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(0.12),
                        //     borderRadius: BorderRadius.circular(14),
                        //     border: Border.all(
                        //       color: Colors.white.withOpacity(0.14),
                        //     ),
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       Container(
                        //         padding: const EdgeInsets.all(8),
                        //         decoration: BoxDecoration(
                        //           color: Colors.white.withOpacity(0.14),
                        //           borderRadius: BorderRadius.circular(10),
                        //         ),
                        //         child: const Icon(
                        //           Icons.monetization_on_rounded,
                        //           color: Colors.white,
                        //           size: 20,
                        //         ),
                        //       ),
                        //       const SizedBox(width: 12),
                        //       Expanded(
                        //         child: Text(
                        //           'Potential Earnings',
                        //           maxLines: 1,
                        //           overflow: TextOverflow.ellipsis,
                        //           style: TextStyle(
                        //             color: Colors.white.withOpacity(0.9),
                        //             fontSize: 13,
                        //             fontWeight: FontWeight.w700,
                        //           ),
                        //         ),
                        //       ),
                        //       Text(
                        //         '₹${potentialEarnings.toStringAsFixed(0)}',
                        //         style: const TextStyle(
                        //           color: Colors.white,
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w900,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () =>
                              _showDailyScoreDetails(dailyScoreProvider),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Today\'s Score',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (dailyScoreProvider.isLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        dailyScoreProvider.today == null
                                            ? '100/100'
                                            : '${dailyScoreProvider.today!.finalScore}/100',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dailyScoreProvider.today == null
                                            ? 'Base Score'
                                            : _scoreStatusLabel(
                                                dailyScoreProvider
                                                    .today!.finalScore,
                                              ),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Critical Compliance Warning Banner
                  if (_incompleteCriticalTasks.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Critical Compliance Pending',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_incompleteCriticalTasks.length} critical task${_incompleteCriticalTasks.length > 1 ? 's' : ''} must be completed before accessing other features.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._incompleteCriticalTasks
                              .take(3)
                              .map(
                                (task) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.priority_high,
                                        size: 16,
                                        color: Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Task Status Section
                  _buildSectionHeader('Task Status', Icons.analytics_outlined),
                  const SizedBox(height: 12),
                  StatusOverviewCard(
                    total: totalCount,
                    pending: pendingCount,
                    completed: completedCount,
                    cancelled: cancelledCount,
                  ),

                  const SizedBox(height: 24),

                  // Tasks Section
                  _buildSectionHeader('All Tasks', Icons.task_alt),
                  const SizedBox(height: 12),

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

                  // Task list
                  if (filteredTasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.06)),
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
                            'No tasks found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try changing the filter or check back later',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final int cappedCount =
                            _visibleTaskCount > filteredTasks.length
                                ? filteredTasks.length
                                : _visibleTaskCount;

                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cappedCount,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                final taskModel = TaskModel.fromEntity(task);
                                final isFuture = _isFutureTask(task);

                                Color statusColor;
                                if (isFuture) {
                                  statusColor = Colors.grey;
                                } else {
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
                                }

                                final String statusLabel = isFuture
                                    ? 'Future'
                                    : _getHumanReadableStatus(task);

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
                                      : _getHumanReadableStatus(task),
                                  description: task.description,
                                  frequencyLabel:
                                      task.frequency.toString().split('.').last,
                                  onTap: () {
                                    if (_isBlockedByCritical(task)) {
                                      _showCriticalPendingMessage();
                                      return;
                                    }
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.taskDetails,
                                      arguments: taskModel,
                                    );
                                  },
                                );
                              },
                            ),
                            if (cappedCount < filteredTasks.length) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _loadMore,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.35),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Load more (${filteredTasks.length - cappedCount})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return DashboardSectionHeader(title: title, icon: icon);
  }

  Widget _buildFilterChip(TaskFrequency? value, String label) {
    final isSelected = !_showTodayTasks && _selectedFrequency == value;
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
          _showTodayTasks = false;
          _selectedFrequency = value;
          _resetPagination();
        });
      },
    );
  }

  Widget _buildTodayFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _showTodayTasks,
      showCheckmark: false,
      selectedColor: Colors.blue.withOpacity(0.14),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: _showTodayTasks
            ? Colors.blue.withOpacity(0.5)
            : Colors.black.withOpacity(0.10),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: _showTodayTasks ? FontWeight.w800 : FontWeight.w700,
        color: _showTodayTasks ? Colors.blue : AppTheme.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onSelected: (_) {
        setState(() {
          _showTodayTasks = !_showTodayTasks;
          if (_showTodayTasks) {
            _selectedFrequency = null;
          }
          _resetPagination();
        });
      },
    );
  }

  void _refreshData() {
    setState(() {
      _resetPagination();
    });
  }
}
