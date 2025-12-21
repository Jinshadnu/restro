import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/widgets/custome_text_field.dart';
import 'package:restro/presentation/widgets/gradient_button.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/presentation/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  String? selectedUserType;

  // 💡 Match your Firebase roles exactly
  final List<String> userTypes = ["staff", "manager", "admin"];
  // If you want owner => change "admin" to "owner"

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

                // ===== FORM CARD =====
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // LOGO
                        Container(
                          height: 85,
                          width: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
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

                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Fill the form to register",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // NAME
                        CustomeTextField(
                          controller: nameCtrl,
                          label: "Full Name",
                          prefixICon: Icons.person_outline,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Enter your name" : null,
                        ),
                        const SizedBox(height: 8),

                        // EMAIL
                        CustomeTextField(
                          controller: emailCtrl,
                          label: "Email",
                          prefixICon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Enter email";
                            if (!v.contains('@')) return "Invalid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // PHONE
                        CustomeTextField(
                          controller: phoneCtrl,
                          label: "Phone Number",
                          prefixICon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Enter phone";
                            if (v.length < 10) return "Invalid number";
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // USER TYPE DROPDOWN (Improved)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedUserType,
                            decoration: const InputDecoration(
                              labelText: "User Type",
                              border: InputBorder.none,
                            ),
                            items: userTypes
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedUserType = value);
                            },
                            validator: (value) =>
                                value == null ? "Select user type" : null,
                          ),
                        ),

                        // PASSWORD
                        CustomeTextField(
                          controller: passwordCtrl,
                          label: "Password",
                          prefixICon: Icons.lock_outline,
                          isPassword: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Enter password";
                            if (v.length < 6) return "Minimum 6 characters";
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // CONFIRM PASSWORD
                        CustomeTextField(
                          controller: confirmPasswordCtrl,
                          label: "Confirm Password",
                          prefixICon: Icons.lock_outline,
                          isPassword: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Confirm your password";
                            }
                            if (v != passwordCtrl.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // REGISTER BUTTON
                        GradientButton(
                          text: authProvider.isLoading
                              ? "Please wait..."
                              : "Register",
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;

                                  final error = await authProvider.register(
                                    email: emailCtrl.text.trim(),
                                    password: passwordCtrl.text.trim(),
                                    name: nameCtrl.text.trim(),
                                    phone: phoneCtrl.text.trim(),
                                    role: selectedUserType!,
                                  );

                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                    return;
                                  }

                                  // ===== ROLE BASED NAVIGATION =====
                                  final role = selectedUserType;

                                  if (role == "staff") {
                                    Navigator.pushReplacementNamed(
                                        context, AppRoutes.staffDashboard);
                                  } else if (role == "manager") {
                                    Navigator.pushReplacementNamed(
                                        context, AppRoutes.managerDashboard);
                                  } else {
                                    Navigator.pushReplacementNamed(
                                        context, AppRoutes.adminDashboard);
                                  }
                                },
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? "),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Color(0xFFD62128),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
