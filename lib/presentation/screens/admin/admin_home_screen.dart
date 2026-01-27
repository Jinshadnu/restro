import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/admin_dashboard_provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/screens/admin/owner_dashboard_shell.dart';
import 'package:restro/presentation/widgets/animated_task_admin.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/presentation/widgets/status_car_ui.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:intl/intl.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);

    // If user is admin/owner, show owner dashboard shell with tabs
    if (auth.currentUser?.role == 'admin') {
      return const OwnerDashboardShell();
    }

    final dashboardProvider =
        Provider.of<AdminDashboardProvider>(context, listen: false);

    // For manager role
    final userId = auth.currentUser?.id ?? '';

    // 🔥 FIX: Call provider AFTER the build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId.isNotEmpty) {
        dashboardProvider.loadManagerDashboard(userId);
      }
    });

    return Scaffold(
      appBar: const CustomAppbar(title: 'Admin Dashboard'),
      body: Stack(
        children: [
          Container(
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
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const SizedBox(height: 10),

                  // 🔹 User header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.person_3_rounded,
                              color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Text(
                    "Task Status",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 14),

                  // 🔥 Responsive Dashboard via Provider
                  Consumer<AdminDashboardProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = provider.managerDashboard;

                      return StatusOverviewCard(
                        total: data['totalTasks'] ?? 0,
                        pending: data['pendingTasks'] ?? 0,
                        completed: data['completedToday'] ?? 0,
                        cancelled: data['verificationPending'] ?? 0,
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "All Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Tasks list from Firestore
                  StreamBuilder(
                    stream: dashboardProvider.firestoreService.getAllTasks(),
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
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No tasks yet',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length > 5 ? 5 : tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          Color statusColor;
                          String status;

                          switch (task.status.toString().split('.').last) {
                            case 'pending':
                              statusColor = Colors.orange;
                              status = 'Pending';
                              break;
                            case 'verificationPending':
                              statusColor = Colors.blue;
                              status = 'Verification Pending';
                              break;
                            case 'approved':
                              statusColor = Colors.green;
                              status = 'Completed';
                              break;
                            default:
                              statusColor = Colors.grey;
                              status = 'Unknown';
                          }

                          return AnimatedTaskAdmin(
                            title: task.title,
                            time: task.dueDate != null
                                ? 'Due: ${task.dueDate!.toString().substring(0, 10)}'
                                : 'No deadline',
                            person: 'Staff',
                            statusColor: statusColor,
                            status: status,
                            index: index,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
