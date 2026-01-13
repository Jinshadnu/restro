import 'package:flutter/material.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/presentation/screens/about_screen.dart';
import 'package:restro/presentation/screens/admin/change_password.dart';
import 'package:restro/presentation/screens/admin/manage_sop.dart';
import 'package:restro/presentation/screens/admin/manage_staff_screen_admin.dart';
import 'package:restro/presentation/screens/admin/owner_dashboard_shell.dart';
import 'package:restro/presentation/screens/admin/owner_reports_screen.dart';
import 'package:restro/presentation/screens/admin/owner_settings_screen.dart';
import 'package:restro/presentation/screens/auth/login_screen.dart';
import 'package:restro/presentation/screens/auth/staff_login_screen.dart';
import 'package:restro/presentation/screens/auth/register_screen.dart';
import 'package:restro/presentation/screens/edit_profile_screen.dart';
import 'package:restro/presentation/screens/help_support_screen.dart';
import 'package:restro/presentation/screens/manager/manager_dashboard.dart';
import 'package:restro/presentation/screens/manager/assign_task_screen.dart';
import 'package:restro/presentation/screens/splash_screen.dart';
import 'package:restro/presentation/screens/staff/staff_dashboard_screen.dart';
import 'package:restro/presentation/screens/staff/start_task_screen.dart';
import 'package:restro/presentation/screens/staff/task_details_screen.dart';
import 'package:restro/presentation/screens/staff/attendance_selfie_screen.dart';
import 'package:restro/presentation/screens/manager/attendance_verification_screen.dart';
import 'package:restro/presentation/screens/manager/register_staff_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String staffLogin = '/staff_login';
  static const String register = '/register';

  static const String adminDashboard = '/admin-dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String staffDashboard = '/staff-dashboard';
  static const String taskDetails = '/taskDetails';
  static const String startTask = '/startTask';
  static const String changePassword = '/change_password';
  static const String editProfile = '/edit_profile';
  static const String manageStaff = '/manage_staff';
  static const String managesop = '/manage_sop';
  static const String about = '/about';
  static const String helpSupport = '/help_support';
  static const String ownerReports = '/owner_reports';
  static const String ownerSettings = '/owner_settings';
  static const String ownerDashboard = '/owner_dashboard';
  static const String assignTask = '/assign_task';
  static const String attendanceSelfie = '/attendance_selfie';
  static const String attendanceVerification = '/attendance_verification';
  static const String registerStaff = '/register_staff';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case staffLogin:
        // Use a deferred or dynamic import if possible, but here we'll just add the import later.
        // For now, I'll add the builder, assuming the file will exist.
        return MaterialPageRoute(builder: (_) => const StaffLoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case staffDashboard:
        return MaterialPageRoute(builder: (_) => const StaffDashboard());

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const OwnerDashboardShell());

      case ownerDashboard:
        return MaterialPageRoute(builder: (_) => const OwnerDashboardShell());

      case managerDashboard:
        return MaterialPageRoute(builder: (_) => const ManagerDashboard());

      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case manageStaff:
        return MaterialPageRoute(builder: (_) => const ManageStaffScreen());

      case about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      case helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());

      case ownerReports:
        return MaterialPageRoute(builder: (_) => OwnerReportsScreen());

      case ownerSettings:
        return MaterialPageRoute(builder: (_) => const OwnerSettingsScreen());

      case managesop:
        return MaterialPageRoute(builder: (_) => const ManageSopScreen());

      case assignTask:
        return MaterialPageRoute(
            builder: (_) => const ManagerAssignTaskScreen());

      case taskDetails:
        final task = settings.arguments;

        if (task is TaskModel) {
          return MaterialPageRoute(
            builder: (_) => TaskDetailsScreen(task: task),
          );
        }

        // Fallback UI if no task passed
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                "No task data found!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );

      case startTask:
        final task = settings.arguments;
        if (task is TaskModel) {
          return MaterialPageRoute(
            builder: (_) => StartTaskScreen(task: task),
          );
        }

        // Fallback UI if no task passed
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                "No task data found!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );

      case attendanceSelfie:
        return MaterialPageRoute(
          builder: (_) => const AttendanceSelfieScreen(),
        );

      case attendanceVerification:
        return MaterialPageRoute(
          builder: (_) => const AttendanceVerificationScreen(),
        );

      case registerStaff:
        return MaterialPageRoute(
          builder: (_) => const ManagerRegisterStaffScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text("No route defined for ${settings.name}"),
            ),
          ),
        );
    }
  }
}
