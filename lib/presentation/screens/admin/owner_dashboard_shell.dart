import 'package:flutter/material.dart';
import 'package:restro/presentation/screens/admin/manage_sop.dart';
import 'package:restro/presentation/screens/admin/manage_staff_screen_admin.dart';
import 'package:restro/presentation/screens/admin/owner_dashboard_screen.dart';
import 'package:restro/presentation/screens/admin/owner_reports_screen.dart';
import 'package:restro/presentation/screens/admin/owner_settings_screen.dart';
import 'package:restro/utils/theme/theme.dart';

class OwnerDashboardShell extends StatefulWidget {
  final List<Widget>? screensOverride;

  const OwnerDashboardShell({
    super.key,
    this.screensOverride,
  });

  @override
  State<OwnerDashboardShell> createState() => _OwnerDashboardShellState();
}

class _OwnerDashboardShellState extends State<OwnerDashboardShell> {
  int _currentIndex = 0;

  final PageStorageBucket _bucket = PageStorageBucket();

  static const _navDestinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'SOPs',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics_rounded),
      label: 'Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Staff',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  late final List<Widget> _screens = widget.screensOverride ??
      [
        const OwnerDashboardScreen(),
        const ManageSopScreen(),
        OwnerReportsScreen(),
        const ManageStaffScreen(),
        const OwnerSettingsScreen(),
      ];

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
