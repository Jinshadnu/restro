import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/change_password_provider.dart';
import 'package:restro/utils/theme/theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChangePasswordProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Change Password",
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Update Your Password",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      "Enter your current password and the new password.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 25),

                    /// Current password
                    _passwordField(
                      controller: _currentCtrl,
                      label: "Current Password",
                      isVisible: _showCurrent,
                      onToggle: () =>
                          setState(() => _showCurrent = !_showCurrent),
                    ),
                    const SizedBox(height: 15),

                    /// New password
                    _passwordField(
                      controller: _newCtrl,
                      label: "New Password",
                      isVisible: _showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                    ),
                    const SizedBox(height: 15),

                    /// Confirm password
                    _passwordField(
                      controller: _confirmCtrl,
                      label: "Confirm Password",
                      isVisible: _showConfirm,
                      onToggle: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Confirm password";
                        if (v != _newCtrl.text) return "Passwords do not match";
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    /// Submit button
                    provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _handleSubmit(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Save Password",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Reusable password field
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator ??
            (v) {
              if (v == null || v.isEmpty) return "Enter $label";
              if (v.length < 6) return "Password must be at least 6 characters";
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  /// 🔹 Handle Submit with Provider
  Future<void> _handleSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider =
        Provider.of<ChangePasswordProvider>(context, listen: false);

    final success = await provider.updatePassword(
      currentPwd: _currentCtrl.text.trim(),
      newPwd: _newCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _showDialog(context, "Success", "Password updated successfully!", () {
        if (!mounted) return;
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        }
      });
    } else {
      final errorMsg =
          provider.errorMessage ?? "Current password is incorrect!";
      _showDialog(context, "Error", errorMsg);
    }
  }

  /// 🔹 Common dialog
  void _showDialog(BuildContext context, String title, String msg,
      [VoidCallback? onOk]) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOk?.call();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
