import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';
import 'package:restro/utils/services/selfie_verification_settings_service.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/navigation/app_routes.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  bool? _selfieEnabledOverride;
  bool _isSavingSelfieSetting = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final currentUser = authProvider.currentUser;
    final settingsService = SelfieVerificationSettingsService();
    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: const CustomAppbar(title: 'Owner Profile'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: AppTheme.primaryColor,
              child: Column(
                children: [
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
                  Text(
                    currentUser?.name ?? 'Owner',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    (currentUser != null && currentUser.role.isNotEmpty)
                        ? currentUser.role
                        : 'owner',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    'Owner Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Email', currentUser?.email ?? 'N/A'),
                  _infoRow('Phone', currentUser?.phone ?? 'N/A'),
                  _infoRow(
                    'Role',
                    (currentUser != null && currentUser.role.isNotEmpty)
                        ? currentUser.role
                        : 'owner',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  StreamBuilder<bool>(
                    stream: settingsService.streamEnabled(),
                    builder: (context, snapshot) {
                      final enabled =
                          _selfieEnabledOverride ?? (snapshot.data ?? false);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.05)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SwitchListTile(
                          value: enabled,
                          onChanged: (v) async {
                            if (_isSavingSelfieSetting) return;
                            final prev = enabled;
                            setState(() {
                              _selfieEnabledOverride = v;
                              _isSavingSelfieSetting = true;
                            });
                            try {
                              await settingsService.setEnabled(v);
                              if (!mounted) return;
                              setState(() {
                                _isSavingSelfieSetting = false;
                                _selfieEnabledOverride = null;
                              });
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                _isSavingSelfieSetting = false;
                                _selfieEnabledOverride = prev;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to update setting: ${e.toString()}'),
                                ),
                              );
                            }
                          },
                          title: const Text('Selfie Verification'),
                          subtitle:
                              const Text('Require selfie after PIN login'),
                          secondary: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.15),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          activeColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                  _tile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.changePassword),
                  ),
                  _tile(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _tile(
                    icon: Icons.event_available_outlined,
                    title: 'Attendance Overview',
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.attendanceOverview),
                  ),
                  _tile(
                    icon: Icons.calendar_view_month_outlined,
                    title: 'Monthly Attendance Summary',
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.monthlyAttendanceSummary),
                  ),
                  _tile(
                    icon: Icons.calendar_view_month_outlined,
                    title: 'Monthly Task Overview',
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.monthlyTaskOverview),
                  ),
                  _tile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.helpSupport),
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
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _tile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
}
