import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/navigation/app_routes.dart';

class OwnerSettingsScreen extends StatelessWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final currentUser = authProvider.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
          ),
          _tile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {},
          ),
          _tile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
          ),
          _tile(
            icon: Icons.info_outline,
            title: 'About App',
            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
          ),
          _tile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              onTap: () {
                _showLogoutDialog(context, authProvider);
              }
          ),
        ],
      ),
    );
  }

  Widget _tile({required IconData icon,
    required String title,
    required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// ----------- Logout Confirmation Dialog -------------
  void _showLogoutDialog(BuildContext context,
      AuthenticationProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await authProvider.logout();

                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                          (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
