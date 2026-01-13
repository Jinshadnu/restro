import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: const CustomAppbar(title: "Admin Profile"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔵 TOP ADMIN HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: AssetImage("assets/images/admin.png"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser?.name ?? "Admin",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    (currentUser != null && currentUser.role.isNotEmpty)
                        ? currentUser.role
                        : "admin",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ⚪ WHITE CARD (Admin Info)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                    "Admin Information",
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
                        : "admin",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ⚙ SETTINGS OPTIONS
            _settingsTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.editProfile);
              },
            ),

            _settingsTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.changePassword);
              },
            ),

            _settingsTile(
              icon: Icons.group_outlined,
              title: "Manage Staff",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.manageStaff);
              },
            ),

            _settingsTile(
              icon: Icons.menu_book_outlined,
              title: "Manage SOP",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.managesop);
              },
            ),

            _settingsTile(
              icon: Icons.settings_outlined,
              title: "About",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.about);
              },
            ),

            // ---------------- LOGOUT BUTTON ----------------
            _settingsTile(
              icon: Icons.logout,
              title: "Logout",
              onTap: () {
                _showLogoutDialog(context, authProvider);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// ---------- LOGOUT CONFIRMATION DIALOG ----------
  void _showLogoutDialog(
      BuildContext context, AuthenticationProvider authProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog

              await authProvider.logout();

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
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

  /// ---------- INFO ROW ----------
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// ---------- SETTINGS TILE ----------
  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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
