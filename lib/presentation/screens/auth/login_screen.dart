import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/presentation/widgets/custome_text_field.dart';
import 'package:restro/presentation/widgets/gradient_button.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/services/selfie_verification_settings_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identifierCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --------------------- LOGIN CARD -----------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ---------------- LOGO ----------------
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ---------------- TEXTS ----------------
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),

                        const SizedBox(height: 6),
                        Text(
                          "Login to continue",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ---------------- EMAIL ----------------
                        CustomeTextField(
                          controller: identifierCtrl,
                          label: 'Email or Phone',
                          prefixICon: Icons.email_outlined,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your email or phone number';
                            }
                            // Check if it's an email or phone number
                            final isEmail = value.contains('@');
                            final isPhone =
                                RegExp(r'^[0-9+]+$').hasMatch(value);

                            if (!isEmail && !isPhone) {
                              return 'Enter a valid email or phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ---------------- PASSWORD ----------------
                        CustomeTextField(
                          controller: passwordCtrl,
                          label: 'Password',
                          prefixICon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.forgotPassword,
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Color(0xFFD62128)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ---------------- LOGIN BUTTON ----------------
                        GradientButton(
                          text: authProvider.isLoading
                              ? "Please wait..."
                              : "Login",
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);

                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final error = await authProvider.login(
                                    identifier: identifierCtrl.text.trim(),
                                    password: passwordCtrl.text.trim(),
                                  );

                                  if (!mounted) return;

                                  if (error != null) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                    return;
                                  }

                                  final user = authProvider.currentUser;

                                  if (user == null) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text("User data not found"),
                                      ),
                                    );
                                    return;
                                  }

                                  final role = user.role.toLowerCase();

                                  // -------------------------
                                  // ROLE-BASED NAVIGATION
                                  // -------------------------
                                  if (role == "admin") {
                                    navigator.pushReplacementNamed(
                                        AppRoutes.adminDashboard);
                                  } else if (role == "owner") {
                                    navigator.pushReplacementNamed(
                                        AppRoutes.ownerDashboard);
                                  } else if (role == "manager") {
                                    navigator.pushReplacementNamed(
                                        AppRoutes.managerDashboard);
                                  } else if (role == "staff") {
                                    bool selfieRequired = true;
                                    try {
                                      selfieRequired =
                                          await SelfieVerificationSettingsService()
                                              .getEnabled(forceRefresh: true);
                                    } catch (_) {
                                      selfieRequired = true;
                                    }

                                    if (!mounted) return;

                                    if (!selfieRequired) {
                                      navigator.pushReplacementNamed(
                                          AppRoutes.staffDashboard);
                                      return;
                                    }

                                    final now = DateTime.now();
                                    if (now.hour < 14) {
                                      navigator.pushReplacementNamed(
                                          AppRoutes.staffDashboard);
                                      return;
                                    }

                                    final firestoreService = FirestoreService();
                                    final todayAttendance =
                                        await firestoreService
                                            .getTodayAttendance(user.id);

                                    if (!mounted) return;

                                    if (todayAttendance.docs.isEmpty) {
                                      navigator.pushReplacementNamed(
                                          AppRoutes.attendanceSelfie);
                                      return;
                                    }

                                    final data = todayAttendance.docs.first
                                        .data() as Map<String, dynamic>;
                                    final status =
                                        (data['verification_status'] ??
                                                data['status'] ??
                                                '')
                                            .toString()
                                            .toLowerCase();
                                    final isApproved = status == 'approved' ||
                                        status == 'verified';

                                    if (!mounted) return;
                                    navigator.pushReplacementNamed(
                                      isApproved
                                          ? AppRoutes.staffDashboard
                                          : AppRoutes.attendanceSelfie,
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text("Unknown role: $role"),
                                      ),
                                    );
                                  }
                                },
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.staffLogin,
                                    );
                                  },
                            icon: const Icon(Icons.pin_outlined),
                            label: const Text('Staff Login (PIN)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ---------------- FOOTER ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          color: Color(0xFFD62128),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
