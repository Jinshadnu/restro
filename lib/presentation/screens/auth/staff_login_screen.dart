import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/services/selfie_verification_settings_service.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  String _pin = "";

  final SelfieVerificationSettingsService _selfieSettingsService =
      SelfieVerificationSettingsService();

  @override
  void initState() {
    super.initState();
    _ensureAnonymousAuth();
  }

  Future<void> _ensureAnonymousAuth() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {
      // Ignore: loginWithPin will surface an actionable error if Firestore/AppCheck blocks.
    }
  }

  void _onKeyPress(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == 4) {
        _login();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _login() async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    final error = await authProvider.loginWithPin(_pin);

    if (error != null) {
      if (mounted) {
        final msg = error.toLowerCase().contains('permission-denied') ||
                error.toLowerCase().contains('permission denied')
            ? 'Permission denied. Ensure PIN login Cloud Function is deployed and Firestore rules allow: users/{uid} read for request.auth.uid == uid.'
            : error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        setState(() {
          _pin = "";
        });
      }
    } else {
      if (!mounted) return;
      // Success
      final user = authProvider.currentUser;
      if (user != null) {
        await _handlePostPinLogin(authProvider);
      }
    }
  }

  Future<void> _handlePostPinLogin(AuthenticationProvider authProvider) async {
    if (!mounted) return;
    final user = authProvider.currentUser;
    if (user == null) return;

    bool selfieRequired = false;
    try {
      selfieRequired =
          await _selfieSettingsService.getEnabled(forceRefresh: true);
    } catch (_) {
      selfieRequired = false;
    }

    if (!mounted) return;

    if (selfieRequired) {
      Navigator.pushReplacementNamed(context, AppRoutes.attendanceSelfie);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.staffDashboard);
  }

  // ===========================================================
  //            Enhanced PIN Dot Widget
  // ===========================================================
  Widget _enhancedPinDot(bool filled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppTheme.primaryColor : Colors.transparent,
        border: Border.all(
          color: filled ? AppTheme.primaryColor : Colors.grey.shade400,
          width: 2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: filled
          ? Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
            )
          : null,
    );
  }

  // ===========================================================
  //            Enhanced Keypad Key Widget
  // ===========================================================
  Widget _enhancedKey(String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPress(value),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypadButton(String value) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypadBackspaceButton() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //            Enhanced Backspace Widget
  // ===========================================================
  Widget _enhancedBackspace() {
    return Expanded(
      child: GestureDetector(
        onTap: _onBackspace,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 32,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //            Legacy Widgets (keep for compatibility)
  // ===========================================================
  Widget _buildPinDot(bool filled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppTheme.primaryColor : Colors.grey.shade300,
        border: Border.all(
          color: filled ? AppTheme.primaryColor : Colors.grey.shade400,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPress(value),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspace() {
    return Expanded(
      child: GestureDetector(
        onTap: _onBackspace,
        child: Container(
          margin: const EdgeInsets.all(8),
          color: Colors.transparent,
          child: const Center(
            child: Icon(Icons.backspace_outlined, size: 28, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section (Primary Color)
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Staff Access',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter your PIN code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section (White Sheet)
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), // Slate 100
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    // PIN Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < _pin.length
                                ? AppTheme.primaryColor
                                : Colors.grey.withOpacity(0.2),
                          ),
                        );
                      }),
                    ),
                    
                    const Spacer(),

                    // Keypad
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: authProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : GridView.count(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _simpleKey('1'),
                                _simpleKey('2'),
                                _simpleKey('3'),
                                _simpleKey('4'),
                                _simpleKey('5'),
                                _simpleKey('6'),
                                _simpleKey('7'),
                                _simpleKey('8'),
                                _simpleKey('9'),
                                const SizedBox(), // Empty slot
                                _simpleKey('0'),
                                _simpleBackspace(),
                              ],
                            ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleKey(String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _onKeyPress(value),
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.black.withOpacity(0.04),
          highlightColor: Colors.black.withOpacity(0.02),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _simpleBackspace() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04), // Subtle red shadow
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _onBackspace,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.red.withOpacity(0.1),
          child: Center(
            child: Icon(
              Icons.backspace_rounded,
              size: 26,
              color: const Color(0xFFEF4444).withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}

