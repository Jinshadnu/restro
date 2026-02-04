import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/custome_text_field.dart';
import 'package:restro/utils/services/staff_registration_service.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:intl/intl.dart';

class ManagerRegisterStaffScreen extends StatefulWidget {
  const ManagerRegisterStaffScreen({super.key});

  @override
  State<ManagerRegisterStaffScreen> createState() =>
      _ManagerRegisterStaffScreenState();
}

class _ManagerRegisterStaffScreenState
    extends State<ManagerRegisterStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedStaffRole;
  List<String> _staffRoles = [];
  bool _isLoadingRoles = true;
  bool _obscurePassword = true;
  bool _obscurePin = true;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadStaffRoles();
  }

  Future<void> _loadStaffRoles() async {
    try {
      final roles = await _firestoreService.getStaffRoles();
      if (mounted) {
        setState(() {
          _staffRoles = roles.isNotEmpty
              ? roles
              : [
                  'Cashier',
                  'Cleaner',
                  'Waiter',
                  'Shawarma Master',
                  'Shawarma Helper',
                  'BBQ/Alfaham Master',
                  'Juice and Tea Maker',
                  'Delivery Boy',
                ];
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _staffRoles = [
            'Cashier',
            'Cleaner',
            'Waiter',
            'Shawarma Master',
            'Shawarma Helper',
            'BBQ/Alfaham Master',
            'Juice and Tea Maker',
            'Delivery Boy',
          ];
          _isLoadingRoles = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading roles; using defaults: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final managerId = auth.currentUser?.id;
    if (managerId == null || managerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Manager session not found. Please login again.')),
      );
      return;
    }

    if (_selectedStaffRole == null || _selectedStaffRole!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff role.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = StaffRegistrationService();

      await service.registerStaff(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        staffRole: _selectedStaffRole!,
        pin: _pinCtrl.text.trim(),
        createdBy: managerId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff registered successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_add_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Register New Staff',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add a new team member to your staff',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Form section
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        'Staff Information', Icons.person_outline),
                    const SizedBox(height: 16),

                    // Enhanced form card
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
                          CustomeTextField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            prefixICon: Icons.person_outline,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter staff name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          CustomeTextField(
                            controller: _emailCtrl,
                            label: 'Email Address',
                            prefixICon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter email address';
                              }
                              if (!v.contains('@'))
                                return 'Invalid email format';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomeTextField(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            prefixICon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter phone number';
                              }
                              if (v.trim().length < 10)
                                return 'Phone number must be at least 10 digits';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Enhanced role dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isLoadingRoles
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 20),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppTheme.primaryColor),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Loading staff roles...',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    value: _selectedStaffRole,
                                    decoration: InputDecoration(
                                      labelText: 'Staff Role',
                                      labelStyle: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.work_outline,
                                        color: AppTheme.primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 20),
                                    ),
                                    items: _staffRoles
                                        .map(
                                          (r) => DropdownMenuItem<String>(
                                            value: r,
                                            child: Text(
                                              r,
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedStaffRole = value),
                                    validator: (value) => value == null
                                        ? 'Please select staff role'
                                        : null,
                                  ),
                          ),
                          const SizedBox(height: 16),

                          CustomeTextField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            prefixICon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Enter password';
                              if (v.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomeTextField(
                            controller: _pinCtrl,
                            label: 'Staff PIN (4 digits)',
                            prefixICon: Icons.lock_clock_outlined,
                            keyboardType: TextInputType.number,
                            isPassword: true,
                            obscureText: _obscurePin,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePin = !_obscurePin;
                              });
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter staff PIN';
                              }
                              final pin = v.trim();
                              if (pin.length != 4)
                                return 'PIN must be exactly 4 digits';
                              if (int.tryParse(pin) == null) {
                                return 'PIN must contain only numbers';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Enhanced submit button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Creating Staff Account...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Create Staff Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced section header widget
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
