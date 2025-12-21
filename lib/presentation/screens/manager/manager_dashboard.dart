import 'package:flutter/material.dart';
import 'package:restro/presentation/screens/manager/manager_home_screen.dart';
import 'package:restro/presentation/screens/manager/verification_screen.dart';
import 'package:restro/presentation/screens/manager/assign_task_screen.dart';
import 'package:restro/presentation/screens/manager/add_sop_screen.dart';
import 'package:restro/presentation/screens/manager/manager_profile_screen.dart';
import 'package:restro/utils/theme/theme.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ManagerHomeScreen(),
    const ManagerAssignTaskScreen(),
    const ManagerAddSopScreen(),
    const ManagerVerificationScreen(),
    const ManagerProfileScreen(),
  ];

  // Method to switch tabs programmatically
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Assign",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "SOP",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: "Verify",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
