import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/admin_dashboard_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/presentation/widgets/attendance_statistics_card.dart';
import 'package:restro/presentation/widgets/dashboard_section_header.dart';
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AdminDashboardProvider>(context, listen: false);
      provider.loadOwnerDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: const CustomAppbar(title: 'Owner Dashboard'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, Owner',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.analytics,
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
                                  'Business Overview',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Monitor performance metrics and analytics',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Consumer<AdminDashboardProvider>(
                builder: (context, provider, child) {
                  final data = provider.ownerDashboard;

                  final totalStaff = (data['totalStaff'] as num?)?.toInt() ?? 0;
                  final presentStaff =
                      (data['presentStaff'] as num?)?.toInt() ?? 0;
                  final lateStaff = (data['lateStaff'] as num?)?.toInt() ?? 0;
                  final absentStaff =
                      (data['absentStaff'] as num?)?.toInt() ?? 0;

                  final pendingTasks =
                      (data['pendingTasks'] as num?)?.toInt() ?? 0;
                  final verificationPending =
                      (data['verificationPending'] as num?)?.toInt() ?? 0;
                  final completedToday =
                      (data['completedToday'] as num?)?.toInt() ?? 0;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.dashboard_customize,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Overall Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.16)),
                              ),
                              child: Text(
                                DateFormat('MMM d').format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTodayTile(
                                icon: Icons.people,
                                title: 'Total Staff',
                                count: totalStaff,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTodayTile(
                                icon: Icons.check_circle,
                                title: 'Present',
                                count: presentStaff,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTodayTile(
                                icon: Icons.access_time,
                                title: 'Late',
                                count: lateStaff,
                                color: AppTheme.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTodayTile(
                                icon: Icons.cancel,
                                title: 'Absent',
                                count: absentStaff,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTodayTile(
                                icon: Icons.checklist,
                                title: 'Completed Today',
                                count: completedToday,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTodayTile(
                                icon: Icons.pending,
                                title: 'Pending Tasks',
                                count: pendingTasks,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTodayTile(
                          icon: Icons.verified_user,
                          title: 'To Verify',
                          count: verificationPending,
                          color: AppTheme.tertiaryColor,
                        ),
                      ],
                    ),
                  );
                },
              ),

              Consumer<AdminDashboardProvider>(
                builder: (context, provider, child) {
                  final data = provider.ownerDashboard;
                  final scoreValue =
                      (data['shopDailyScore'] as num?)?.toDouble();
                  final score = scoreValue == null ? null : scoreValue.round();

                  Color zoneColor;
                  IconData zoneIcon;
                  String zoneLabel;
                  if (score != null && score >= 90) {
                    zoneColor = const Color(0xFF4CAF50);
                    zoneIcon = Icons.check_circle;
                    zoneLabel = 'Shop is Healthy.';
                  } else if (score != null && score >= 80) {
                    zoneColor = const Color(0xFFFFC107);
                    zoneIcon = Icons.warning_amber_rounded;
                    zoneLabel = 'Needs Attention.';
                  } else {
                    zoneColor = const Color(0xFFF44336);
                    zoneIcon = Icons.cancel;
                    zoneLabel = 'Action Required!';
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          zoneColor,
                          zoneColor.withOpacity(0.86),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: zoneColor.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(
                            zoneIcon,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shop Performance',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                zoneLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            score == null ? '--/100' : '$score/100',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Enhanced section header
              _buildSectionHeader(
                  'Performance Metrics', Icons.analytics_outlined),
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
                      // Today's work status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.04)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.today,
                                    color: AppTheme.primaryColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Today's Work Status",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.16),
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat('MMM d').format(DateTime.now()),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTodayTile(
                                    icon: Icons.check_circle,
                                    title: 'Completed',
                                    count: (data['completedToday'] as num?)
                                            ?.toInt() ??
                                        0,
                                    color: AppTheme.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTodayTile(
                                    icon: Icons.pending,
                                    title: 'Pending',
                                    count: (data['pendingTasks'] as num?)
                                            ?.toInt() ??
                                        0,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTodayTile(
                                    icon: Icons.verified_user,
                                    title: 'To Verify',
                                    count: (data['verificationPending'] as num?)
                                            ?.toInt() ??
                                        0,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTodayTile(
                                    icon: Icons.fact_check,
                                    title: 'Attendance',
                                    count: (data['attendancePendingApprovals']
                                                as num?)
                                            ?.toInt() ??
                                        0,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      AttendanceStatisticsCard(isOwner: true),

                      // Enhanced metric cards
                      _EnhancedMetricCard(
                        title: 'Task Compliance',
                        value:
                            '${(data['compliance'] ?? 0.0).toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        color: Colors.green,
                        subtitle: 'Overall task completion rate',
                        trend: '+2.5%',
                        isPositive: true,
                      ),
                      const SizedBox(height: 16),

                      _EnhancedMetricCard(
                        title: 'Avg Verification Time',
                        value:
                            '${(data['avgVerificationTime'] ?? 0.0).toStringAsFixed(1)} hrs',
                        icon: Icons.access_time,
                        color: Colors.blue,
                        subtitle: 'Average time to verify tasks',
                        trend: '-0.8 hrs',
                        isPositive: true,
                      ),
                      const SizedBox(height: 16),

                      _EnhancedMetricCard(
                        title: 'Most Failed Task',
                        value: data['mostFailedTask'] ?? 'None',
                        icon: Icons.warning,
                        color: Colors.red,
                        subtitle: 'Task with most rejections',
                        trend:
                            '${(data['mostFailedTaskCount'] as num?)?.toInt() ?? 0} failures',
                        isPositive: false,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Enhanced section header
              _buildSectionHeader('Quick Actions', Icons.flash_on),
              const SizedBox(height: 16),

              // Enhanced quick actions grid
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 112,
                  ),
                  children: [
                    _EnhancedActionButton(
                      icon: Icons.description,
                      label: 'Manage SOPs',
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.managesop);
                      },
                    ),
                    _EnhancedActionButton(
                      icon: Icons.analytics,
                      label: 'View Reports',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.ownerReports);
                      },
                    ),
                    _EnhancedActionButton(
                      icon: Icons.people,
                      label: 'Manage Staff',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.manageStaff);
                      },
                    ),
                    _EnhancedActionButton(
                      icon: Icons.settings,
                      label: 'Settings',
                      color: Colors.grey,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.ownerSettings);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Enhanced section header
              _buildSectionHeader('Overall Task Details', Icons.bar_chart),
              const SizedBox(height: 12),
              _OverallTaskGraph(firestoreService: _firestoreService),

              const SizedBox(height: 28),

              // Enhanced section header
              _buildSectionHeader('Staff Performance', Icons.people),
              const SizedBox(height: 12),
              _StaffPerformanceGraph(firestoreService: _firestoreService),

              const SizedBox(height: 28),

              // Enhanced section header
              _buildSectionHeader(
                  'Task Trends (Last 7 Days)', Icons.trending_up),
              const SizedBox(height: 12),
              _TaskTrendsGraph(firestoreService: _firestoreService),

              const SizedBox(height: 28),

              // Enhanced section header
              _buildSectionHeader(
                  'Task Category Distribution', Icons.pie_chart),
              const SizedBox(height: 12),
              _TaskCategoryGraph(firestoreService: _firestoreService),

              const SizedBox(height: 28),

              // Enhanced section header
              _buildSectionHeader(
                  'Staff Role Performance', Icons.person_search),
              const SizedBox(height: 12),
              _StaffRolePerformanceGraph(firestoreService: _firestoreService),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced section header widget
  Widget _buildSectionHeader(String title, IconData icon) {
    return DashboardSectionHeader(title: title, icon: icon);
  }

  Widget _buildTodayTile({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced metric card widget
  Widget _EnhancedMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (isPositive ? Colors.green : Colors.red)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced action button widget
  Widget _EnhancedActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
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
        final total = tasks.isEmpty ? 1 : tasks.length;

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

        return FutureBuilder<Map<String, String>>(
          future: firestoreService.getUserIdNameMap(),
          builder: (context, userSnap) {
            final userMap = userSnap.data ?? const <String, String>{};
            final items = staffCompleted.entries.map((e) {
              final label = userMap[e.key] ?? e.key;
              return _BarData(
                label,
                e.value / maxVal,
                AppTheme.primaryColor,
                e.value,
              );
            }).toList();
            return _barCard(items, showLabel: true);
          },
        );
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

class _TaskTrendsGraph extends StatelessWidget {
  final FirestoreService firestoreService;
  const _TaskTrendsGraph({required this.firestoreService});

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
        final now = DateTime.now();
        final Map<String, Map<String, int>> dailyData = {};

        // Initialize last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateKey = DateFormat('MMM dd').format(date);
          dailyData[dateKey] = {
            'completed': 0,
            'pending': 0,
            'rejected': 0,
          };
        }

        // Categorize tasks by date
        for (var task in tasks) {
          if (task.completedAt != null) {
            final taskDate = task.completedAt!;
            final dateKey = DateFormat('MMM dd').format(taskDate);
            if (dailyData.containsKey(dateKey)) {
              if (task.status == TaskStatus.approved) {
                dailyData[dateKey]!['completed'] =
                    (dailyData[dateKey]!['completed'] ?? 0) + 1;
              } else if (task.status == TaskStatus.rejected) {
                dailyData[dateKey]!['rejected'] =
                    (dailyData[dateKey]!['rejected'] ?? 0) + 1;
              }
            }
          }
        }

        return _trendsCard(dailyData);
      },
    );
  }
}

class _TaskCategoryGraph extends StatelessWidget {
  final FirestoreService firestoreService;
  const _TaskCategoryGraph({required this.firestoreService});

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
        final Map<String, int> categoryCount = {};

        for (var task in tasks) {
          String category = 'General';
          final title = task.title.toLowerCase();

          if (title.contains('cleaning') || title.contains('clean')) {
            category = 'Cleaning';
          } else if (title.contains('shawarma')) {
            category = 'Shawarma';
          } else if (title.contains('bbq') || title.contains('alfaham')) {
            category = 'BBQ/Grill';
          } else if (title.contains('juice') || title.contains('tea')) {
            category = 'Beverages';
          } else if (title.contains('cashier')) {
            category = 'Cashier';
          } else if (title.contains('waiter')) {
            category = 'Service';
          }

          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }

        final total = tasks.isEmpty ? 1 : tasks.length;
        final items = categoryCount.entries.map((entry) {
          return _PieData(
            entry.key,
            entry.value / total,
            _getCategoryColor(entry.key),
            entry.value,
          );
        }).toList();

        return _pieCard(items);
      },
    );
  }
}

class _StaffRolePerformanceGraph extends StatelessWidget {
  final FirestoreService firestoreService;
  const _StaffRolePerformanceGraph({required this.firestoreService});

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
        final Map<String, Map<String, int>> roleData = {};
        final Map<String, int> staffApproved = {};

        for (var task in tasks) {
          // This would need to be enhanced to get actual staff roles
          // For now, we'll categorize by performance
          String role = 'Staff';
          if (task.status == TaskStatus.approved) {
            role = 'High Performer';
            staffApproved[task.assignedTo] =
                (staffApproved[task.assignedTo] ?? 0) + 1;
          } else if (task.status == TaskStatus.rejected) {
            role = 'Needs Attention';
          }

          if (!roleData.containsKey(role)) {
            roleData[role] = {'completed': 0, 'total': 0};
          }
          roleData[role]!['total'] = (roleData[role]!['total'] ?? 0) + 1;
          if (task.status == TaskStatus.approved) {
            roleData[role]!['completed'] =
                (roleData[role]!['completed'] ?? 0) + 1;
          }
        }

        final items = roleData.entries.map((entry) {
          final completionRate = entry.value['total']! > 0
              ? entry.value['completed']! / entry.value['total']!
              : 0.0;
          return _BarData(
            entry.key,
            completionRate,
            _getRoleColor(entry.key),
            entry.value['completed']!,
          );
        }).toList();

        if (staffApproved.isEmpty) {
          return _barCard(items, showLabel: true);
        }

        final topEntry =
            staffApproved.entries.reduce((a, b) => a.value >= b.value ? a : b);

        return FutureBuilder<Map<String, String>>(
          future: firestoreService.getUserIdNameMap(),
          builder: (context, userSnap) {
            final userMap = userSnap.data ?? const <String, String>{};
            final topName = userMap[topEntry.key] ?? topEntry.key;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.25)),
                        ),
                        child: const Text(
                          'High Performer',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          topName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${topEntry.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _barCard(items, showLabel: true),
              ],
            );
          },
        );
      },
    );
  }
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  final int count;
  _PieData(this.label, this.value, this.color, this.count);
}

Color _getCategoryColor(String category) {
  switch (category) {
    case 'Cleaning':
      return Colors.blue;
    case 'Shawarma':
      return Colors.orange;
    case 'BBQ/Grill':
      return Colors.red;
    case 'Beverages':
      return Colors.green;
    case 'Cashier':
      return Colors.purple;
    case 'Service':
      return Colors.teal;
    default:
      return Colors.grey;
  }
}

Color _getRoleColor(String role) {
  switch (role) {
    case 'High Performer':
      return Colors.green;
    case 'Needs Attention':
      return Colors.red;
    default:
      return AppTheme.primaryColor;
  }
}

Widget _trendsCard(Map<String, Map<String, int>> dailyData) {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendItem('Completed', Colors.green),
            const SizedBox(width: 16),
            _LegendItem('Pending', Colors.orange),
            const SizedBox(width: 16),
            _LegendItem('Rejected', Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dailyData.entries.map((entry) {
              final maxValue = dailyData.values
                  .map((e) =>
                      (e['completed'] ?? 0) +
                      (e['pending'] ?? 0) +
                      (e['rejected'] ?? 0))
                  .reduce((a, b) => a > b ? a : b)
                  .clamp(1, double.infinity);

              final completed = entry.value['completed'] ?? 0;
              final pending = entry.value['pending'] ?? 0;
              final rejected = entry.value['rejected'] ?? 0;
              final total = completed + pending + rejected;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: total > 0 ? (completed / maxValue) * 80 : 0,
                        color: Colors.green,
                      ),
                      Container(
                        height: total > 0 ? (pending / maxValue) * 80 : 0,
                        color: Colors.orange,
                      ),
                      Container(
                        height: total > 0 ? (rejected / maxValue) * 80 : 0,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$total',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

Widget _pieCard(List<_PieData> items) {
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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${(item.value * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.count}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
