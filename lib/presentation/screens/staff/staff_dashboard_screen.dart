import 'package:flutter/material.dart';
import 'package:restro/presentation/screens/staff/staff_home_screen.dart';
import 'package:restro/presentation/screens/staff/staff_profile_screen.dart';
import 'package:restro/presentation/screens/staff/staff_settings_screen.dart';
import 'package:restro/presentation/screens/staff/staff_task_screen.dart';
import 'package:restro/presentation/screens/staff/task_completed_screen.dart';
import 'package:restro/utils/theme/theme.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const StaffHomeScreen(),
      const StaffTaskScreen(),
      const TaskCompletedScreen(),
      const StaffProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFD62128),
          // 🔴 Red (your logo color)
          currentIndex: _currentIndex,
          selectedItemColor: AppTheme.yellow,
          // Selected item white
          unselectedItemColor: AppTheme.primaryLight,
          // Slightly dimmed white for others
          type: BottomNavigationBarType.fixed,
          // Important to show background color
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
            BottomNavigationBarItem(icon: Icon(Icons.done), label: "Completed"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ));
  }
}
