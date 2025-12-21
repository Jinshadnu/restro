import 'package:flutter/material.dart';
import 'package:restro/presentation/screens/admin/add_sop_screen.dart';
import 'package:restro/presentation/screens/admin/admin_asign_task_screen.dart';
import 'package:restro/presentation/screens/admin/admin_home_screen.dart';
import 'package:restro/presentation/screens/admin/admin_profile_screen.dart';
import 'package:restro/presentation/screens/admin/admin_verification_screen.dart';
import 'package:restro/utils/theme/theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final List<Widget> _screens = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _screens.addAll([
      AdminHomeScreen(),
      const AssignTaskScreen(),
      const AddSopScreen(),
      const AdminVerificationListScreen(),
      const AdminProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppTheme.primaryColor,
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
            BottomNavigationBarItem(icon: Icon(Icons.task), label: "SOP"),
            BottomNavigationBarItem(icon: Icon(Icons.done), label: "Completed"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ]),
    );
  }
}
