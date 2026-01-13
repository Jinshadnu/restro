import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/sop_provider.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/widgets/gradient_button.dart';
import 'package:restro/presentation/widgets/custome_text_field.dart';
import 'package:restro/utils/theme/theme.dart';
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
  String? _selectedStaffName;
  String? _selectedSopId;
  String? _selectedSopTitle;
  TaskFrequency? _selectedFrequency;

  bool _requireEvidence = false;
  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Map<String, dynamic>> _staffList = [];

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
                        Text(
                          'Task Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.05)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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

                              const SizedBox(height: 12),

                              // 🔹 STAFF DROPDOWN
                              _buildDropdown(
                                label: "Assign To Staff",
                                items: _staffList
                                    .map((staff) =>
                                        staff['name']?.toString() ?? "Unknown")
                                    .toList(),
                                value: _selectedStaffName,
                                onChange: (v) {
                                  if (v == null) return;
                                  final staffMatches =
                                      _staffList.where((s) => s['name'] == v);
                                  if (staffMatches.isEmpty) return;
                                  final staff = staffMatches.first;
                                  setState(() {
                                    _selectedStaffId = staff['id']?.toString();
                                    _selectedStaffName = v;
                                  });
                                },
                              ),

                              // 🔹 FREQUENCY (AUTO FROM SOP)
                              if (_selectedFrequency != null) ...[
                                const SizedBox(height: 12),
                                _buildFrequencyDropdown(),
                              ],

                              const SizedBox(height: 10),

                              // 🔹 TITLE
                              CustomeTextField(
                                label: "Task Title",
                                prefixICon: Icons.task_alt,
                                controller: _titleCtrl,
                                validator: (v) => v == null || v.isEmpty
                                    ? "Enter title"
                                    : null,
                              ),

                              const SizedBox(height: 10),

                              // 🔹 DESCRIPTION
                              CustomeTextField(
                                label: "Task Description",
                                prefixICon: Icons.description_outlined,
                                maxLine: 4,
                                controller: _descCtrl,
                              ),

                              const SizedBox(height: 12),

                              // 🔹 DUE DATE PICKER
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.black.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month,
                                          color: AppTheme.textSecondary),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedDate == null
                                            ? "Select Due Date"
                                            : DateFormat('MMM d, y')
                                                .format(_selectedDate!),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // 🔹 PLANNED START TIME
                              GestureDetector(
                                onTap: () =>
                                    _pickPlannedDateTime(isStart: true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.black.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _plannedStartAt == null
                                            ? "Planned Start Time"
                                            : DateFormat('MMM d, y • h:mm a')
                                                .format(_plannedStartAt!),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // 🔹 PLANNED COMPLETION TIME
                              GestureDetector(
                                onTap: () =>
                                    _pickPlannedDateTime(isStart: false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.black.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.flag_outlined,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _plannedEndAt == null
                                            ? "Planned Completion Time"
                                            : DateFormat('MMM d, y • h:mm a')
                                                .format(_plannedEndAt!),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

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

                              const SizedBox(height: 24),

                              // 🔹 SUBMIT BUTTON
                              _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : GradientButton(
                                      text: "Assign Task",
                                      onPressed: _submitTask,
                                    ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChange,
      validator: (val) => val == null ? "Select $label" : null,
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<TaskFrequency>(
      value: _selectedFrequency,
      decoration: const InputDecoration(
        labelText: "Frequency",
        border: OutlineInputBorder(),
      ),
      items: TaskFrequency.values
          .map((f) => DropdownMenuItem(
                value: f,
                child: Text(f.toString().split('.').last.toUpperCase()),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedFrequency = value);
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

  Future<void> _submitTask() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    if (_selectedDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pick a due date")));
      return;
    }

    if (_selectedSopId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select an SOP")),
      );
      return;
    }

    if (_selectedStaffId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a staff member")),
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

    if (_plannedStartAt != null && _plannedEndAt != null) {
      if (_plannedEndAt!.isBefore(_plannedStartAt!)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Planned end time must be after start time")),
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
      final task = TaskModel(
        id: _uuid.v4(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        sopid: _selectedSopId!,
        assignedTo: _selectedStaffId!,
        assignedBy: auth.currentUser!.id,
        status: TaskStatus.pending,
        frequency: _selectedFrequency!,
        plannedStartAt: _plannedStartAt,
        plannedEndAt: _plannedEndAt,
        dueDate: _selectedDate,
        createdAt: DateTime.now(),
        requiresPhoto: _requireEvidence,
      );

      await _firestoreService.createTask(task);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task assigned successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
