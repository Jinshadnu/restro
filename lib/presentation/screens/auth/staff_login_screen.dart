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
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Staff Login',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Premium header card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Access',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your 4-digit staff PIN to continue',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PIN entry section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // PIN dots container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.04)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Enter PIN',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Enhanced PIN dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return _enhancedPinDot(index < _pin.length);
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loading indicator or keypad
                    if (authProvider.isLoading)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.04)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      )
                    else
                      // Enhanced keypad
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.04)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    _enhancedKey("1"),
                                    const SizedBox(width: 12),
                                    _enhancedKey("2"),
                                    const SizedBox(width: 12),
                                    _enhancedKey("3"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    _enhancedKey("4"),
                                    const SizedBox(width: 12),
                                    _enhancedKey("5"),
                                    const SizedBox(width: 12),
                                    _enhancedKey("6"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    _enhancedKey("7"),
                                    const SizedBox(width: 12),
                                    _enhancedKey("8"),
                                    const SizedBox(width: 12),
                                    _enhancedKey("9"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Expanded(
                                        child:
                                            SizedBox()), // Empty for alignment
                                    const SizedBox(width: 12),
                                    _enhancedKey("0"),
                                    const SizedBox(width: 12),
                                    _enhancedBackspace(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
