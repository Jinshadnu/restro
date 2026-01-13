import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: const CustomAppbar(title: "My Profile"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔵 TOP PROFILE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Manager Name
                  Text(
                    currentUser?.name ?? "Manager",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Manager Role
                  Text(
                    "Manager",
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
                  _infoRow("Role", "Manager"),
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
              icon: Icons.notifications_none,
              title: "Notifications",
              onTap: () {
                _showNotificationSettings(context);
              },
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// ----------- Settings Tile -------------
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

  /// ----------- Logout Confirmation Dialog -------------
  void _showLogoutDialog(
      BuildContext context, AuthenticationProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  /// ----------- Notification Settings Dialog -------------
  void _showNotificationSettings(BuildContext context) {
    bool taskNotifications = true;
    bool verificationNotifications = true;
    bool systemNotifications = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Notification Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text("Task Notifications"),
                subtitle: const Text("Get notified about new tasks"),
                value: taskNotifications,
                onChanged: (value) {
                  setState(() => taskNotifications = value);
                },
              ),
              SwitchListTile(
                title: const Text("Verification Notifications"),
                subtitle:
                    const Text("Get notified about pending verifications"),
                value: verificationNotifications,
                onChanged: (value) {
                  setState(() => verificationNotifications = value);
                },
              ),
              SwitchListTile(
                title: const Text("System Notifications"),
                subtitle: const Text("Get system updates and alerts"),
                value: systemNotifications,
                onChanged: (value) {
                  setState(() => systemNotifications = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Save notification preferences
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Notification settings saved"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ----------- Help & Support Dialog -------------
  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Help & Support"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Need Help?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _helpItem(
                icon: Icons.email,
                title: "Email Support",
                subtitle: "support@restro.com",
              ),
              const SizedBox(height: 12),
              _helpItem(
                icon: Icons.phone,
                title: "Phone Support",
                subtitle: "+91 9876543210",
              ),
              const SizedBox(height: 12),
              _helpItem(
                icon: Icons.chat_bubble_outline,
                title: "Live Chat",
                subtitle: "Available 24/7",
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _faqItem("How do I assign a task?",
                  "Go to Assign tab and select SOP and staff member."),
              _faqItem("How do I verify tasks?",
                  "Go to Verify tab and approve or reject tasks."),
              _faqItem("How do I create an SOP?",
                  "Go to SOP tab and fill in the form."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _faqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
