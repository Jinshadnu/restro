import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/sop_provider.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/widgets/gradient_button.dart';
import 'package:restro/presentation/widgets/custome_text_field.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/app_logger.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ManagerAssignTaskScreen extends StatefulWidget {
  const ManagerAssignTaskScreen({super.key});

  @override
  State<ManagerAssignTaskScreen> createState() =>
      _ManagerAssignTaskScreenState();
}

class _ManagerAssignTaskScreenState extends State<ManagerAssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _plannedStartAt;
  DateTime? _plannedEndAt;
  String? _selectedStaffId;
  String? _selectedSopId;
  String? _selectedSopTitle;
  TaskFrequency? _selectedFrequency;
  TaskGrade? _selectedGrade;

  bool _autoSchedule = false;
  String? _selectedTargetStaffRole;
  List<String> _staffRoles = [];
  TimeOfDay? _autoStartTime;
  TimeOfDay? _autoEndTime;

  bool _requireEvidence = false;
  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Map<String, dynamic>> _staffList = [];

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();

    setState(() {
      _selectedDate = null;
      _plannedStartAt = null;
      _plannedEndAt = null;
      _selectedStaffId = null;
      _selectedSopId = null;
      _selectedSopTitle = null;
      _selectedFrequency = null;
      _selectedGrade = null;
      _selectedTargetStaffRole = null;
      _autoStartTime = null;
      _autoEndTime = null;
      _requireEvidence = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    try {
      // Load staff
      final auth = Provider.of<AuthenticationProvider>(context, listen: false);
      final managerId = auth.currentUser?.id;
      final staff = (managerId != null && managerId.isNotEmpty)
          ? await _firestoreService.getStaffForManager(managerId)
          : await _firestoreService.getUsersByRole('staff');
      if (mounted) {
        setState(() => _staffList = staff);
      }

      // Load staff roles for auto schedule targeting
      try {
        final roles = await _firestoreService.getStaffRoles();
        if (mounted) {
          setState(() {
            _staffRoles = roles;
            if (_selectedTargetStaffRole != null &&
                !_staffRoles.contains(_selectedTargetStaffRole)) {
              _selectedTargetStaffRole = null;
            }
          });
        }
      } catch (_) {
        // Optional data; ignore failures.
      }

      if (mounted && staff.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No staff found (or permission denied). Check Firestore rules and make sure staff users exist.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Load SOPs from Provider
      final sopProvider = Provider.of<SopProvider>(context, listen: false);
      await sopProvider.loadSOPs();

      if (mounted && sopProvider.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load SOPs: ${sopProvider.errorMessage}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Check if SOPs were loaded
      if (mounted && sopProvider.sops.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No SOPs found. Please create an SOP first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text("Create Task", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SopProvider>(
              builder: (context, sopProvider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 TASK DETAILS CARD
                        _buildSectionCard(
                          title: "Task Details",
                          icon: Icons.task_alt,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      contentPadding: EdgeInsets.zero,
                                      value: false,
                                      groupValue: _autoSchedule,
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setState(() => _autoSchedule = v);
                                      },
                                      title: const Text(
                                        'Manual Assign',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      contentPadding: EdgeInsets.zero,
                                      value: true,
                                      groupValue: _autoSchedule,
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setState(() {
                                          _autoSchedule = v;
                                          _selectedStaffId = null;
                                          _selectedDate = null;
                                          _plannedStartAt = null;
                                          _plannedEndAt = null;
                                          _autoStartTime = null;
                                          _autoEndTime = null;
                                        });
                                      },
                                      title: const Text(
                                        'Auto Schedule',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (_autoSchedule) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Auto Schedule creates a daily template. The system will assign this task to all staff automatically every day.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: (_selectedTargetStaffRole != null &&
                                          _staffRoles.contains(
                                              _selectedTargetStaffRole))
                                      ? _selectedTargetStaffRole
                                      : null,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Target Staff Role (optional)',
                                    labelStyle: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.black.withOpacity(0.12),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.black.withOpacity(0.12),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  hint: Text(
                                    'All Staff',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppTheme.textSecondary,
                                  ),
                                  items: _staffRoles
                                      .map(
                                        (r) => DropdownMenuItem<String>(
                                          value: r,
                                          child: Text(
                                            r,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTargetStaffRole = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTimePickerTile(
                                  label: "Start Time *",
                                  icon: Icons.play_circle_outline,
                                  value: _autoStartTime,
                                  onTap: () => _pickAutoTime(isStart: true),
                                ),
                                const SizedBox(height: 16),
                                _buildTimePickerTile(
                                  label: "End Time *",
                                  icon: Icons.flag_outlined,
                                  value: _autoEndTime,
                                  onTap: () => _pickAutoTime(isStart: false),
                                ),
                              ],

                              // 🔹 SOP DROPDOWN
                              sopProvider.isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : sopProvider.sops.isEmpty
                                      ? Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.orange.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.orange),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info_outline,
                                                  color: Colors.orange),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'No SOPs found. Please create an SOP first.',
                                                  style: TextStyle(
                                                    color: Colors.orange[900],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _buildDropdown(
                                          label: "Select SOP",
                                          items: sopProvider.sops
                                              .map((sop) => sop.title)
                                              .toList(),
                                          value: _selectedSopTitle,
                                          onChange: (v) {
                                            if (v != null) {
                                              final sop = sopProvider.sops
                                                  .firstWhere(
                                                      (s) => s.title == v);

                                              setState(() {
                                                _selectedSopId = sop.id;
                                                _selectedSopTitle = v;

                                                _selectedFrequency =
                                                    sop.frequency;
                                                _requireEvidence =
                                                    sop.requiresPhoto;

                                                // Auto-fill title/description
                                                _titleCtrl.text = sop.title;
                                                _descCtrl.text =
                                                    sop.description;
                                              });
                                            }
                                          },
                                        ),

                              const SizedBox(height: 16),

                              // 🔹 STAFF DROPDOWN
                              if (!_autoSchedule) ...[
                                _buildStaffDropdown(),
                                const SizedBox(height: 24),
                              ],

                              // 🔹 FREQUENCY (AUTO FROM SOP)
                              if (_selectedFrequency != null) ...[
                                _buildFrequencyDropdown(),
                                const SizedBox(height: 24),
                              ],

                              const SizedBox(height: 24),

                              // 🔹 TASK PRIORITY
                              _buildGradeDropdown(),

                              const SizedBox(height: 24),

                              // 🔹 TITLE
                              CustomeTextField(
                                label: "Task Title",
                                prefixICon: Icons.task_alt,
                                controller: _titleCtrl,
                                validator: (v) => v == null || v.isEmpty
                                    ? "Enter title"
                                    : null,
                              ),

                              const SizedBox(height: 24),

                              // 🔹 DESCRIPTION
                              CustomeTextField(
                                label: "Task Description",
                                prefixICon: Icons.description_outlined,
                                maxLine: 4,
                                controller: _descCtrl,
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 🔹 SCHEDULE CARD
                        if (!_autoSchedule)
                          _buildSectionCard(
                            title: "Schedule",
                            icon: Icons.schedule,
                            child: Column(
                              children: [
                                // 🔹 DUE DATE PICKER
                                _buildDatePickerTile(
                                  label: "Due Date *",
                                  icon: Icons.calendar_month,
                                  value: _selectedDate,
                                  onTap: _pickDate,
                                ),

                                const SizedBox(height: 24),

                                // 🔹 PLANNED START TIME
                                _buildDatePickerTile(
                                  label: "Planned Start Time",
                                  icon: Icons.play_circle_outline,
                                  value: _plannedStartAt,
                                  onTap: () =>
                                      _pickPlannedDateTime(isStart: true),
                                ),

                                const SizedBox(height: 24),

                                // 🔹 PLANNED COMPLETION TIME
                                _buildDatePickerTile(
                                  label: "Planned Completion Time",
                                  icon: Icons.flag_outlined,
                                  value: _plannedEndAt,
                                  onTap: () =>
                                      _pickPlannedDateTime(isStart: false),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // 🔹 SETTINGS CARD
                        _buildSectionCard(
                          title: "Settings",
                          icon: Icons.settings,
                          child: Column(
                            children: [
                              // 🔹 PHOTO REQUIRED SWITCH
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Photo Evidence Required",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Switch(
                                    value: _requireEvidence,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (v) =>
                                        setState(() => _requireEvidence = v),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 🔹 SUBMIT BUTTON
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : GradientButton(
                                text: _autoSchedule
                                    ? "Save Auto Schedule"
                                    : "Assign Task",
                                onPressed: _submitTask,
                              ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required IconData icon,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    final text = value == null ? label : value.format(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DROPDOWN BUILDER
  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChange,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: AppTheme.textSecondary,
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChange,
      validator: (val) => val == null ? "Select $label" : null,
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<TaskFrequency>(
      value: _selectedFrequency,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Frequency",
        labelStyle: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: AppTheme.textSecondary,
      ),
      items: TaskFrequency.values
          .map((f) => DropdownMenuItem(
                value: f,
                child: Text(
                  f.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedFrequency = value);
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : label == "Due Date *"
                        ? DateFormat('MMM d, y').format(value)
                        : DateFormat('MMM d, y • h:mm a').format(value),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffDropdown() {
    final staffItems = _staffList
        .where((s) => (s['id'] ?? '').toString().trim().isNotEmpty)
        .toList();

    final safeSelectedStaffId = (_selectedStaffId != null &&
            staffItems.any(
              (s) => (s['id'] ?? '').toString() == _selectedStaffId,
            ))
        ? _selectedStaffId
        : null;

    String roleDisplayFor(Map<String, dynamic> staff) {
      final raw =
          (staff['staff_role'] ?? staff['staffRole'] ?? '').toString().trim();
      if (raw.isEmpty) return '';
      return raw
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map(
            (w) =>
                '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
          )
          .join(' ');
    }

    Widget staffRow(String name, String roleDisplay, {bool chip = false}) {
      return Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (roleDisplay.isNotEmpty) ...[
            const SizedBox(width: 12),
            if (chip)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  roleDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              Text(
                roleDisplay,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: safeSelectedStaffId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Assign To Staff",
        labelStyle: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: AppTheme.textSecondary,
      ),
      items: staffItems.map((staff) {
        final staffId = (staff['id'] ?? '').toString();
        final name = (staff['name'] ?? 'Unknown').toString();
        final roleDisplay = roleDisplayFor(staff);
        return DropdownMenuItem<String>(
          value: staffId,
          child: staffRow(name, roleDisplay, chip: true),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return staffItems.map((staff) {
          final name = (staff['name'] ?? 'Unknown').toString();
          final roleDisplay = roleDisplayFor(staff);
          return staffRow(name, roleDisplay);
        }).toList();
      },
      onChanged: (staffId) {
        if (staffId == null || staffId.isEmpty) return;
        setState(() {
          _selectedStaffId = staffId;
        });
      },
      validator: (val) =>
          (val == null || val.isEmpty) ? "Select Assign To Staff" : null,
    );
  }

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<TaskGrade>(
      value: _selectedGrade,
      isExpanded: true,
      selectedItemBuilder: (context) {
        return [
          Text(
            'Grade B',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Grade A',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ];
      },
      decoration: InputDecoration(
        labelText: "Task Priority",
        labelStyle: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: AppTheme.textSecondary,
      ),
      menuMaxHeight: 220, // Increased from 180 to 220
      items: [
        DropdownMenuItem<TaskGrade>(
          value: TaskGrade.normal,
          child: Container(
            constraints: BoxConstraints(maxHeight: 48),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.task_alt,
                    color: Colors.blue,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Grade B',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Standard',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DropdownMenuItem<TaskGrade>(
          value: TaskGrade.critical,
          child: Container(
            constraints: BoxConstraints(maxHeight: 48),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.priority_high,
                    color: Colors.red,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Grade A',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Critical',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedGrade = value);
      },
      validator: (value) {
        if (value == null) {
          return '';
        }
        return null;
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickPlannedDateTime({required bool isStart}) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (pickedTime == null || !mounted) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!mounted) return;
    setState(() {
      if (isStart) {
        _plannedStartAt = dt;
      } else {
        _plannedEndAt = dt;
      }
    });
  }

  Future<void> _pickAutoTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _autoStartTime : _autoEndTime) ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _autoStartTime = picked;
      } else {
        _autoEndTime = picked;
      }
    });
  }

  Future<void> _submitTask() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    if (_selectedSopId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select an SOP")),
      );
      return;
    }

    if (_selectedFrequency == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select frequency")),
      );
      return;
    }

    if (_selectedGrade == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select task grade")),
      );
      return;
    }

    if (!_autoSchedule) {
      if (_selectedDate == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Pick a due date")));
        return;
      }

      if (_selectedStaffId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select a staff member")),
        );
        return;
      }

      if (_plannedStartAt == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select planned start time")),
        );
        return;
      }

      if (_plannedEndAt == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select planned completion time")),
        );
        return;
      }

      if (_plannedEndAt!.isBefore(_plannedStartAt!)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Planned end time must be after start time"),
          ),
        );
        return;
      }
    } else {
      // For now, auto schedule supports daily templates only.
      if (_selectedFrequency != TaskFrequency.daily) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auto Schedule currently supports DAILY only"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_autoStartTime == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select auto schedule start time")),
        );
        return;
      }

      if (_autoEndTime == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select auto schedule end time")),
        );
        return;
      }

      final startMinutes = _autoStartTime!.hour * 60 + _autoStartTime!.minute;
      final endMinutes = _autoEndTime!.hour * 60 + _autoEndTime!.minute;
      if (endMinutes <= startMinutes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End time must be after start time")),
        );
        return;
      }
    }

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    if (auth.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_autoSchedule) {
        final templateId = _uuid.v4();
        final startMinutes = _autoStartTime!.hour * 60 + _autoStartTime!.minute;
        final endMinutes = _autoEndTime!.hour * 60 + _autoEndTime!.minute;
        final hasTargetRole = _selectedTargetStaffRole != null &&
            _selectedTargetStaffRole!.trim().isNotEmpty;
        final payload = <String, dynamic>{
          'id': templateId,
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'sopid': _selectedSopId!,
          'frequency': 'daily',
          'assignmentMode': hasTargetRole ? 'all' : 'round_robin',
          'windowStartMinutes': startMinutes,
          'windowEndMinutes': endMinutes,
          'grade': _selectedGrade!.toString().split('.').last,
          'requiresPhoto': _requireEvidence,
          'active': true,
          'assignedBy': auth.currentUser!.id,
          'createdAt': DateTime.now().toIso8601String(),
        };
        if (hasTargetRole) {
          payload['targetStaffRole'] = _selectedTargetStaffRole!.trim();
        }
        await _firestoreService.createTaskTemplateFromData(payload);
      } else {
        final task = TaskModel(
          id: _uuid.v4(),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          sopid: _selectedSopId!,
          assignedTo: _selectedStaffId!,
          assignedBy: auth.currentUser!.id,
          status: TaskStatus.pending,
          frequency: _selectedFrequency!,
          grade: _selectedGrade!,
          plannedStartAt: _plannedStartAt,
          plannedEndAt: _plannedEndAt,
          dueDate: _selectedDate,
          createdAt: DateTime.now(),
          requiresPhoto: _requireEvidence,
        );

        await _firestoreService.createTask(task);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _autoSchedule
                ? "Auto schedule saved successfully"
                : "Task assigned successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Clear loading before leaving the screen to avoid setState-after-dispose.
      setState(() => _isLoading = false);

      _resetForm();

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      AppLogger.e('AssignTaskScreen', e, st, message: '_submitTask failed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }
}
