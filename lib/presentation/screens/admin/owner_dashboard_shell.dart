import 'package:flutter/material.dart';
import 'package:restro/presentation/screens/admin/manage_sop.dart';
import 'package:restro/presentation/screens/admin/manage_staff_screen_admin.dart';
import 'package:restro/presentation/screens/admin/owner_dashboard_screen.dart';
import 'package:restro/presentation/screens/admin/owner_reports_screen.dart';
import 'package:restro/presentation/screens/admin/owner_settings_screen.dart';
import 'package:restro/utils/theme/theme.dart';

class OwnerDashboardShell extends StatefulWidget {
  const OwnerDashboardShell({super.key});

  @override
  State<OwnerDashboardShell> createState() => _OwnerDashboardShellState();
}

class _OwnerDashboardShellState extends State<OwnerDashboardShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const OwnerDashboardScreen(),
    const ManageSopScreen(),
    OwnerReportsScreen(),
    const ManageStaffScreen(),
    const OwnerSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.primaryColor,
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.yellow,
        unselectedItemColor: AppTheme.primaryLight,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'SOPs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
