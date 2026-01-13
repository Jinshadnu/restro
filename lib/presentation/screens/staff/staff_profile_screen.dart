import 'package:flutter/material.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context);
    final currentUser = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: const CustomAppbar(title: "My Profile"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔴 TOP PROFILE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  // Avatar
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: AssetImage("assets/images/avatar.png"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Staff Name
                  Text(
                    currentUser?.name ?? "Staff",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Staff Role
                  Text(
                    (currentUser != null && currentUser.role.isNotEmpty)
                        ? currentUser.role
                        : "Staff",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ⚪ WHITE CARD (Profile Info)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow("Email", currentUser?.email ?? "N/A"),
                  _infoRow("Phone", currentUser?.phone ?? "N/A"),
                  _infoRow(
                    "Role",
                    (currentUser != null && currentUser.role.isNotEmpty)
                        ? currentUser.role
                        : "staff",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ⚙ SETTINGS OPTIONS
            _settingsTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.changePassword);
              },
            ),

            _settingsTile(
              icon: Icons.notifications_none,
              title: "Notifications",
              onTap: () {},
            ),

            _settingsTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.helpSupport);
              },
            ),

            _settingsTile(
              icon: Icons.info_outline,
              title: "About App",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.about);
              },
            ),

            _settingsTile(
              icon: Icons.logout,
              title: "Logout",
              onTap: () async {
                final auth =
                    Provider.of<AuthenticationProvider>(context, listen: false);

                // Show confirmation dialog
                final confirm = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        TextButton(
                          child: const Text("Logout"),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  await auth.logout();

                  // Navigate to Login Screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// ----------- Reusable Info Row -------------
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// ----------- Settings Tile -------------
  Widget _settingsTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          )
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
}
