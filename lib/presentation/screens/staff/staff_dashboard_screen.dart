import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/daily_score_provider.dart';
import 'package:restro/presentation/screens/staff/staff_home_screen.dart';
import 'package:restro/presentation/screens/staff/staff_profile_screen.dart';
import 'package:restro/presentation/screens/staff/staff_task_screen.dart';
import 'package:restro/presentation/screens/staff/task_completed_screen.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/services/navigation_guard.dart';
import 'package:restro/services/daily_scoring_engine.dart';
import 'package:restro/utils/services/selfie_verification_settings_service.dart';

class StaffDashboard extends StatefulWidget {
  final List<Widget>? screensOverride;
  final bool skipAttendanceCheck;

  const StaffDashboard({
    super.key,
    this.screensOverride,
    this.skipAttendanceCheck = false,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;
  final NavigationGuard _navigationGuard = NavigationGuard();
  SelfieVerificationSettingsService? _selfieSettingsService;
  bool _isCheckingNavigation = false;
  bool _skipAttendanceCheck = false;
  bool _didInitFromRoute = false;

  final List<Widget> _screens = [];
  final PageStorageBucket _bucket = PageStorageBucket();

  static const _navDestinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.task_outlined),
      selectedIcon: Icon(Icons.task_rounded),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.done_all_outlined),
      selectedIcon: Icon(Icons.done_all_rounded),
      label: 'Completed',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _screens.addAll(
      widget.screensOverride ??
          [
            const StaffHomeScreen(),
            const StaffTaskScreen(),
            const TaskCompletedScreen(),
            const StaffProfileScreen(),
          ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    if (widget.skipAttendanceCheck) {
      _skipAttendanceCheck = true;
    }

    // Safe place to read ModalRoute arguments (after initState).
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['skipAttendanceCheck'] == true) {
      _skipAttendanceCheck = true;
    }

    if (!_skipAttendanceCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkAttendance();
      });
    }
  }

  Future<void> _checkAttendance() async {
    _selfieSettingsService ??= SelfieVerificationSettingsService();
    bool selfieRequired = true;
    try {
      selfieRequired = await _selfieSettingsService!.getEnabled();
    } catch (_) {
      selfieRequired = true;
    }
    if (!selfieRequired) return;

    final now = DateTime.now();
    // Daily attendance check starts at 2 PM (14:00)
    if (now.hour < 14) return;

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    if (auth.currentUser == null) return;

    final firestoreService = FirestoreService();
    final todayAttendance =
        await firestoreService.getTodayAttendance(auth.currentUser!.id);

    if (!mounted) return;

    if (todayAttendance.docs.isEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.attendanceSelfie);
      return;
    }

    final data = todayAttendance.docs.first.data() as Map<String, dynamic>;
    final status = (data['verification_status'] ?? data['status'] ?? '')
        .toString()
        .toLowerCase();

    final isApproved = status == 'approved' || status == 'verified';
    if (!isApproved) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.attendanceSelfie);
      return;
    }

    auth.setAttendanceMarked(true);
  }

  Future<void> _refreshData() async {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    if (auth.currentUser != null) {
      try {
        // Check for missed tasks and apply deductions
        final scoringEngine = DailyScoringEngine();
        await scoringEngine.checkMissedTasksForUser(auth.currentUser!.id);

        // Refresh daily score
        await Provider.of<DailyScoreProvider>(context, listen: false)
            .refreshScore(auth.currentUser!.id);

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data refreshed successfully'),
              duration: Duration(seconds: 2),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error refreshing data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      // appBar: AppBar(
      //   backgroundColor: AppTheme.primaryColor,
      //   elevation: 0,
      //   // title: const Text(
      //   //   'Staff Dashboard',
      //   //   style: TextStyle(
      //   //     color: Colors.white,
      //   //     fontWeight: FontWeight.w700,
      //   //     fontSize: 20,
      //   //   ),
      //   // ),
      //   actions: [
      //     IconButton(
      //       onPressed: _refreshData,
      //       icon: const Icon(
      //         Icons.refresh,
      //         color: Colors.white,
      //       ),
      //       tooltip: 'Refresh',
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: PageStorage(
          bucket: _bucket,
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: Colors.white,
                  indicatorColor: AppTheme.primaryColor.withOpacity(0.12),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      );
                    },
                  ),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: 24,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      );
                    },
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  height: 70,
                  onDestinationSelected: (index) async {
                    // Allow navigation to Home / Completed / Profile even when critical tasks are pending.
                    // Only task-related navigation should be blocked.
                    if (index == 0 || index == 2 || index == 3) {
                      setState(() => _currentIndex = index);
                      return;
                    }

                    // Block navigation to other tabs if critical tasks are incomplete
                    if (_isCheckingNavigation) return;

                    setState(() => _isCheckingNavigation = true);

                    try {
                      final auth = Provider.of<AuthenticationProvider>(context,
                          listen: false);
                      if (auth.currentUser?.id != null) {
                        final canNavigate =
                            await _navigationGuard.checkNavigation(
                          context,
                          auth.currentUser!.id,
                        );

                        if (canNavigate && mounted) {
                          setState(() => _currentIndex = index);
                        }
                      }
                    } catch (e) {
                      print('Error checking navigation: $e');
                      // Allow navigation on error (fail-safe)
                      if (mounted) {
                        setState(() => _currentIndex = index);
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isCheckingNavigation = false);
                      }
                    }
                  },
                  destinations: _navDestinations,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
