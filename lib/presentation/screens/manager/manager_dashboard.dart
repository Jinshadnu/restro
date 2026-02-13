import 'package:flutter/material.dart';
import 'package:restro/presentation/screens/manager/manager_home_screen.dart';
import 'package:restro/presentation/screens/manager/verification_screen.dart';
import 'package:restro/presentation/screens/manager/assign_task_screen.dart';
import 'package:restro/presentation/screens/manager/add_sop_screen.dart';
import 'package:restro/presentation/screens/manager/manager_profile_screen.dart';
import 'package:restro/utils/theme/theme.dart';

class ManagerDashboard extends StatefulWidget {
  final List<Widget>? screensOverride;

  const ManagerDashboard({
    super.key,
    this.screensOverride,
  });

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;

  final PageStorageBucket _bucket = PageStorageBucket();

  static const _navDestinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment_rounded),
      label: 'Assign',
    ),
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description_rounded),
      label: 'SOP',
    ),
    NavigationDestination(
      icon: Icon(Icons.verified_outlined),
      selectedIcon: Icon(Icons.verified_rounded),
      label: 'Verify',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  late final List<Widget> _screens = widget.screensOverride ??
      [
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
