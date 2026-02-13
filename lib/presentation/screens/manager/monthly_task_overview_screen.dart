import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/theme/theme.dart';

class MonthlyTaskOverviewScreen extends StatefulWidget {
  const MonthlyTaskOverviewScreen({super.key});

  @override
  State<MonthlyTaskOverviewScreen> createState() =>
      _MonthlyTaskOverviewScreenState();
}

class _MonthlyTaskOverviewScreenState extends State<MonthlyTaskOverviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  String _monthLabel(DateTime m) => DateFormat('MMMM yyyy').format(m);

  bool _isInSelectedMonth(DateTime dt) {
    final local = dt.toLocal();
    return local.year == _selectedMonth.year &&
        local.month == _selectedMonth.month;
  }

  DateTime _effectiveMonthDate(TaskModel t) {
    return (t.dueDate ?? t.plannedStartAt ?? t.createdAt).toLocal();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final role = (auth.currentUser?.role ?? '').toString().toLowerCase();
    final isOwner = role == 'owner';
    final isManager = role == 'manager';

    if (!isOwner && !isManager) {
      return Scaffold(
        backgroundColor: AppTheme.backGroundColor,
        appBar: AppBar(
          title: const Text('Monthly Task Overview'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Not authorized')),
      );
    }

    final staffStream = isOwner
        ? _firestoreService.streamAllStaffUsers()
        : _firestoreService.streamStaffForManager(auth.currentUser?.id ?? '');

    final managerId = (auth.currentUser?.id ?? '').toString();
    final taskStream = isOwner
        ? _firestoreService.streamTasksByFrequency('monthly')
        : _firestoreService.streamTasksAssignedBy(managerId);

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: const Text('Monthly Task Overview'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon:
                const Icon(Icons.calendar_month_outlined, color: Colors.white),
            label: Text(
              _monthLabel(_selectedMonth),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: staffStream,
          builder: (context, staffSnap) {
            if (staffSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (staffSnap.hasError) {
              return Center(child: Text('Error: ${staffSnap.error}'));
            }

            final staff = staffSnap.data ?? [];
            if (staff.isEmpty) {
              return const Center(child: Text('No staff found'));
            }

            return StreamBuilder<List<TaskModel>>(
              stream: taskStream,
              builder: (context, taskSnap) {
                if (taskSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (taskSnap.hasError) {
                  return Center(child: Text('Error: ${taskSnap.error}'));
                }

                final all = taskSnap.data ?? const <TaskModel>[];

                final filtered = all.where((t) {
                  if (t.frequency != TaskFrequency.monthly) return false;
                  // For manager stream, assignedBy is already filtered.
                  if (isOwner == false && isManager && managerId.isNotEmpty) {
                    if (t.assignedBy != managerId) return false;
                  }

                  // Monthly overview should be based on the task's scheduled/due month.
                  return _isInSelectedMonth(_effectiveMonthDate(t));
                }).toList();

                final byUser = <String, List<TaskModel>>{};
                for (final t in filtered) {
                  if (t.assignedTo.isEmpty) continue;
                  (byUser[t.assignedTo] ??= []).add(t);
                }

                staff.sort((a, b) {
                  final an = (a['name'] ?? '').toString().toLowerCase();
                  final bn = (b['name'] ?? '').toString().toLowerCase();
                  return an.compareTo(bn);
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = staff[index];
                    final uid = (s['id'] ?? '').toString();
                    final name = (s['name'] ?? 'Unknown').toString();
                    final roleDisplay =
                        (s['staff_role'] ?? s['staffRole'] ?? '')
                            .toString()
                            .trim();

                    final tasks = byUser[uid] ?? const <TaskModel>[];

                    int pending = 0;
                    int inProgress = 0;
                    int verificationPending = 0;
                    int approved = 0;
                    int rejected = 0;
                    int late = 0;
                    int critical = 0;

                    for (final t in tasks) {
                      switch (t.status) {
                        case TaskStatus.pending:
                          pending += 1;
                          break;
                        case TaskStatus.inProgress:
                          inProgress += 1;
                          break;
                        case TaskStatus.verificationPending:
                          verificationPending += 1;
                          break;
                        case TaskStatus.approved:
                          approved += 1;
                          break;
                        case TaskStatus.rejected:
                          rejected += 1;
                          break;
                        case TaskStatus.completed:
                          verificationPending += 1;
                          break;
                      }

                      if (t.isLate) late += 1;
                      if (t.grade == TaskGrade.critical) critical += 1;
                    }

                    final total = tasks.length;

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _MonthlyTaskUserDetailsScreen(
                              userName: name,
                              userId: uid,
                              monthLabel: _monthLabel(_selectedMonth),
                              tasks: tasks,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (roleDisplay.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            roleDisplay,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Total: $total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _chip('Pending', pending, Colors.orange),
                                _chip('In Progress', inProgress, Colors.blue),
                                _chip('Verify', verificationPending,
                                    Colors.purple),
                                _chip('Approved', approved, Colors.green),
                                _chip('Rejected', rejected, Colors.red),
                                _chip('Late', late, Colors.brown),
                                _chip('Critical', critical, Colors.black87),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MonthlyTaskUserDetailsScreen extends StatelessWidget {
  final String userName;
  final String userId;
  final String monthLabel;
  final List<TaskModel> tasks;

  const _MonthlyTaskUserDetailsScreen({
    required this.userName,
    required this.userId,
    required this.monthLabel,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...tasks];
    sorted.sort((a, b) {
      final ad = a.dueDate ?? a.plannedStartAt ?? a.createdAt;
      final bd = b.dueDate ?? b.plannedStartAt ?? b.createdAt;
      return bd.compareTo(ad);
    });

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: Text('$userName • $monthLabel'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: sorted.isEmpty
          ? const Center(child: Text('No tasks for this month'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final t = sorted[index];
                final when =
                    (t.dueDate ?? t.plannedStartAt ?? t.createdAt).toLocal();
                final whenLabel = DateFormat('MMM d, y • h:mm a').format(when);
                final status = t.status.toString().split('.').last;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status: $status',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When: $whenLabel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
