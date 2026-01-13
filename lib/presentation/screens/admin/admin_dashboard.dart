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
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'SOP',
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
      backgroundColor: AppTheme.backGroundColor,
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
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
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
