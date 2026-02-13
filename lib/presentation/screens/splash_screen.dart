import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/services/selfie_verification_settings_service.dart';
import 'package:restro/data/datasources/local/database_helper.dart';
import 'package:restro/utils/services/auto_assignment_service.dart';
import 'package:restro/utils/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restro/utils/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  static const String _termsAcceptedKey = 'terms_accepted_sop_001_v1';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // 🔥 NEW: Check session & navigate
    navigateUser();
  }

  Future<void> navigateUser() async {
    try {
      final auth = Provider.of<AuthenticationProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final termsAccepted = prefs.getBool(_termsAcceptedKey) ?? false;
      if (!termsAccepted) {
        navigator.pushReplacementNamed(AppRoutes.termsAndConditions);
        return;
      }

      bool loggedIn = await auth.loadSession();

      if (!loggedIn) {
        navigator.pushReplacementNamed(AppRoutes.login);
        return;
      }

      final now = DateTime.now();
      final todayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastAutoAssignDay = prefs.getString('last_auto_assign_day');

      if (lastAutoAssignDay == todayKey) {
        AppLogger.d(
          'SplashScreen',
          'auto-assignment already ran today ($todayKey), skipping',
        );
      }

      // 🔥 Navigate based on Role
      final role = auth.currentUser!.role.toString().toLowerCase();
      switch (role) {
        case "admin":
          if (lastAutoAssignDay != todayKey) {
            try {
              final db = DatabaseHelper.instance;
              final sync = SyncService(db, FirestoreService());
              await sync.syncFromFirestore();
              final autoAssign = AutoAssignmentService(db, FirestoreService());
              final created = await autoAssign.autoAssignTasks();
              AppLogger.d(
                'SplashScreen',
                'auto-assignment created=$created (admin)',
              );
              if (created > 0) {
                await prefs.setString('last_auto_assign_day', todayKey);
              }
            } catch (e, st) {
              AppLogger.e(
                'SplashScreen',
                e,
                st,
                message: 'auto-assignment failed (admin)',
              );
            }
          }
          if (!mounted) return;
          navigator.pushReplacementNamed(AppRoutes.adminDashboard);
          break;

        case "owner":
          if (lastAutoAssignDay != todayKey) {
            try {
              final db = DatabaseHelper.instance;
              final sync = SyncService(db, FirestoreService());
              await sync.syncFromFirestore();
              final autoAssign = AutoAssignmentService(db, FirestoreService());
              final created = await autoAssign.autoAssignTasks();
              AppLogger.d(
                'SplashScreen',
                'auto-assignment created=$created (owner)',
              );
              if (created > 0) {
                await prefs.setString('last_auto_assign_day', todayKey);
              }
            } catch (e, st) {
              AppLogger.e(
                'SplashScreen',
                e,
                st,
                message: 'auto-assignment failed (owner)',
              );
            }
          }
          if (!mounted) return;
          navigator.pushReplacementNamed(AppRoutes.ownerDashboard);
          break;

        case "manager":
          if (lastAutoAssignDay != todayKey) {
            try {
              final db = DatabaseHelper.instance;
              final sync = SyncService(db, FirestoreService());
              await sync.syncFromFirestore();
              final autoAssign = AutoAssignmentService(db, FirestoreService());
              final created = await autoAssign.autoAssignTasks();
              AppLogger.d(
                'SplashScreen',
                'auto-assignment created=$created (manager)',
              );
              if (created > 0) {
                await prefs.setString('last_auto_assign_day', todayKey);
              }
            } catch (e, st) {
              AppLogger.e(
                'SplashScreen',
                e,
                st,
                message: 'auto-assignment failed (manager)',
              );
            }
          }
          if (!mounted) return;
          navigator.pushReplacementNamed(AppRoutes.managerDashboard);
          break;

        case "staff":
          bool selfieRequired = true;
          try {
            selfieRequired = await SelfieVerificationSettingsService()
                .getEnabled(forceRefresh: true);
          } catch (_) {
            selfieRequired = true;
          }

          if (!selfieRequired) {
            if (!mounted) return;
            navigator.pushReplacementNamed(AppRoutes.staffDashboard);
            break;
          }

          // Check if attendance is already marked today
          final now = DateTime.now();
          if (now.hour < 14) {
            if (!mounted) return;
            navigator.pushReplacementNamed(AppRoutes.staffDashboard);
            break;
          }

          final firestoreService = FirestoreService();
          final todayAttendance = await firestoreService.getTodayAttendance(
            auth.currentUser!.id,
          );

          if (todayAttendance.docs.isEmpty) {
            if (!mounted) return;
            navigator.pushReplacementNamed(AppRoutes.attendanceSelfie);
            break;
          }

          final data =
              todayAttendance.docs.first.data() as Map<String, dynamic>;
          final status = (data['verification_status'] ?? data['status'] ?? '')
              .toString()
              .toLowerCase();
          final isApproved = status == 'approved' || status == 'verified';

          if (!mounted) return;
          navigator.pushReplacementNamed(
            isApproved ? AppRoutes.staffDashboard : AppRoutes.attendanceSelfie,
          );
          break;

        default:
          if (!mounted) return;
          navigator.pushReplacementNamed(AppRoutes.login);
      }
    } catch (e, st) {
      AppLogger.e('SplashScreen', e, st, message: 'navigateUser failed');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFD62128),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Restro Manager",
                style: TextStyle(
                  color: Color(0xFFFED51F),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              const SizedBox(
                width: 260,
                child: Text(
                  "Committed to Cleanliness\nand Excellence",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF7722F),
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 90),
              Column(
                children: [
                  Text(
                    "Powered by",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Restro Technologies",
                    style: TextStyle(
                      color: Color(0xFFFED51F),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
