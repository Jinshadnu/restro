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
      final staff = await _firestoreService.getUsersByRole('staff');
      if (mounted) {
        setState(() => _staffList = staff);
      }

      // Load SOPs from Provider
      final sopProvider = Provider.of<SopProvider>(context, listen: false);
      await sopProvider.loadSOPs();

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
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text("Assign Task", style: TextStyle(color: Colors.white)),
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
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Create New Task",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            Border.all(color: Colors.orange),
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
                                              .firstWhere((s) => s.title == v);

                                          setState(() {
                                            _selectedSopId = sop.id;
                                            _selectedSopTitle = v;

                                            _selectedFrequency = sop.frequency;
                                            _requireEvidence =
                                                sop.requiresPhoto;

                                            // Auto-fill title/description
                                            _titleCtrl.text = sop.title;
                                            _descCtrl.text = sop.description;
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
                              final staff =
                                  _staffList.firstWhere((s) => s['name'] == v);
                              setState(() {
                                _selectedStaffId = staff['id'];
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
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter title" : null,
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
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null
                                        ? "Select Due Date"
                                        : DateFormat('MMM d, y')
                                            .format(_selectedDate!),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 🔹 PHOTO REQUIRED SWITCH
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Photo Evidence Required",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
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
                              ? const Center(child: CircularProgressIndicator())
                              : GradientButton(
                                  text: "Assign Task",
                                  onPressed: _submitTask,
                                ),
                          const SizedBox(height: 10),
                        ],
                      ),
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

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pick a due date")));
      return;
    }

    if (_selectedSopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select an SOP")),
      );
      return;
    }

    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a staff member")),
      );
      return;
    }

    if (_selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select frequency")),
      );
      return;
    }

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

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
        dueDate: _selectedDate,
        createdAt: DateTime.now(),
        requiresPhoto: _requireEvidence,
      );

      await _firestoreService.createTask(task);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task assigned successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }
}
