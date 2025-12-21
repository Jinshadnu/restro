import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/admin_dashboard_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/domain/entities/task_entity.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AdminDashboardProvider>(context, listen: false);
      provider.loadOwnerDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppbar(title: 'Owner Dashboard'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: AppTheme.primaryColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hi, ${auth.currentUser?.name ?? 'Owner'} 👋",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              DateFormat('EEEE, MMMM d').format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Text(
                  "Performance Metrics",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Owner dashboard metrics
                Consumer<AdminDashboardProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final data = provider.ownerDashboard;

                    return Column(
                      children: [
                        // Compliance Percentage
                        _MetricCard(
                          title: 'Task Compliance',
                          value:
                              '${(data['compliance'] ?? 0.0).toStringAsFixed(1)}%',
                          icon: Icons.trending_up,
                          color: Colors.green,
                          subtitle: 'Overall task completion rate',
                        ),
                        const SizedBox(height: 12),

                        // Average Verification Time
                        _MetricCard(
                          title: 'Avg Verification Time',
                          value:
                              '${(data['avgVerificationTime'] ?? 0.0).toStringAsFixed(1)} hrs',
                          icon: Icons.access_time,
                          color: Colors.blue,
                          subtitle: 'Average time to verify tasks',
                        ),
                        const SizedBox(height: 12),

                        // Most Failed Task
                        _MetricCard(
                          title: 'Most Failed Task',
                          value: data['mostFailedTask'] ?? 'None',
                          icon: Icons.warning,
                          color: Colors.red,
                          subtitle: 'Task with most rejections',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.description,
                        label: 'Manage SOPs',
                        color: AppTheme.primaryColor,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.managesop);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.analytics,
                        label: 'View Reports',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.ownerReports);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.people,
                        label: 'Manage Staff',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.manageStaff);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        color: Colors.grey,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.ownerSettings);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  "Overall Task Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _OverallTaskGraph(firestoreService: _firestoreService),

                const SizedBox(height: 24),
                const Text(
                  "Staff Performance",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _StaffPerformanceGraph(firestoreService: _firestoreService),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverallTaskGraph extends StatelessWidget {
  final FirestoreService firestoreService;
  const _OverallTaskGraph({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestoreService.getAllTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final tasks = snapshot.data ?? [];
        final total = tasks.length == 0 ? 1 : tasks.length;

        int completed =
            tasks.where((t) => t.status == TaskStatus.approved).length;
        int pending = tasks
            .where((t) =>
                t.status == TaskStatus.pending ||
                t.status == TaskStatus.inProgress)
            .length;
        int verify = tasks
            .where((t) => t.status == TaskStatus.verificationPending)
            .length;
        int rejected =
            tasks.where((t) => t.status == TaskStatus.rejected).length;

        return _barCard([
          _BarData('Completed', completed / total, Colors.green, completed),
          _BarData('Pending', pending / total, Colors.orange, pending),
          _BarData('Verify', verify / total, Colors.purple, verify),
          _BarData('Rejected', rejected / total, Colors.red, rejected),
        ]);
      },
    );
  }
}

class _StaffPerformanceGraph extends StatelessWidget {
  final FirestoreService firestoreService;
  const _StaffPerformanceGraph({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestoreService.getAllTasks(),
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
              padding: EdgeInsets.all(16.0),
              child: Text('No tasks yet'),
            ),
          );
        }
        final Map<String, int> staffCompleted = {};
        for (var t in tasks) {
          final key = t.assignedTo;
          if (t.status == TaskStatus.approved) {
            staffCompleted[key] = (staffCompleted[key] ?? 0) + 1;
          }
        }
        final maxVal = staffCompleted.values.isEmpty
            ? 1
            : staffCompleted.values.reduce((a, b) => a > b ? a : b);
        final items = staffCompleted.entries
            .map((e) => _BarData(
                e.key, e.value / maxVal, AppTheme.primaryColor, e.value))
            .toList();
        return _barCard(items, showLabel: true);
      },
    );
  }
}

class _BarData {
  final String label;
  final double value;
  final Color color;
  final int count;
  _BarData(this.label, this.value, this.color, this.count);
}

Widget _barCard(List<_BarData> items, {bool showLabel = false}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: item.value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.count}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
