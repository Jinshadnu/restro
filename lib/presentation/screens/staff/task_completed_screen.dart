import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/completed_task_provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/animated_completed_task.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/utils/theme/theme.dart';

class TaskCompletedScreen extends StatefulWidget {
  const TaskCompletedScreen({super.key});

  @override
  State<TaskCompletedScreen> createState() => _TaskCompletedScreenState();
}

class _TaskCompletedScreenState extends State<TaskCompletedScreen> {
  TaskFrequency? _selectedFrequency;
  String? _loadedForUserId;
  DateTime? _lastReloadedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthenticationProvider>(context, listen: false);
      final completedProvider =
          Provider.of<CompletedTaskProvider>(context, listen: false);
      if (auth.currentUser != null) {
        _loadedForUserId = auth.currentUser!.id;
        completedProvider.loadCompletedTasks(userId: auth.currentUser!.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent != true) return;

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    final now = DateTime.now();
    final last = _lastReloadedAt;
    final shouldReload = _loadedForUserId != userId ||
        last == null ||
        now.difference(last).inSeconds >= 2;
    if (!shouldReload) return;

    _loadedForUserId = userId;
    _lastReloadedAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CompletedTaskProvider>(context, listen: false)
          .loadCompletedTasks(userId: userId);
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
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: completedProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final auth =
                    Provider.of<AuthenticationProvider>(context, listen: false);
                if (auth.currentUser != null) {
                  await completedProvider.loadCompletedTasks(
                    userId: auth.currentUser!.id,
                  );
                }
              },
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            Colors.green,
                            Colors.green.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed Tasks',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${filtered.length} task${filtered.length == 1 ? '' : 's'} completed',
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

                    if (filtered.isEmpty)
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
                              Icons.task_alt_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No completed tasks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete some tasks to see them here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Task list
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
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
                        ],
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
      showCheckmark: false,
      selectedColor: Colors.green.withOpacity(0.14),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? Colors.green.withOpacity(0.4)
            : Colors.black.withOpacity(0.10),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
        color: isSelected ? Colors.green : AppTheme.textSecondary,
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
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green, size: 20),
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
