import 'package:flutter/material.dart';
import 'package:restro/data/models/task_assign_model.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custome_text_field.dart';
import '../../../utils/theme/theme.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedStaff;
  String? _priority;
  String? _sopTitle;
  String? _taskType;
  bool _requireEvidence = false;
  var task;

  final List<String> staffList = [
    "Ramesh",
    "Suresh",
    "Anjali",
    "Fatima",
    "Kiran"
  ];

  final List<String> priorityList = ["Low", "Medium", "High"];

  final List<String> sopTitles = [
    "Cleaning SOP",
    "Food Handling SOP",
    "Hygiene SOP",
    "Kitchen Safety SOP",
    "Customer Service SOP",
  ];

  final List<String> taskTypes = ["Daily Task", "Monthly Task"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text("Create Task", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
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
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                    // SOP TITLE
                    _buildDropdown(
                      label: "SOP Title",
                      items: sopTitles,
                      value: _sopTitle,
                      onChange: (v) => setState(() => _sopTitle = v),
                    ),

                    // TASK TYPE
                    _buildDropdown(
                      label: "Task Type",
                      items: taskTypes,
                      value: _taskType,
                      onChange: (v) => setState(() => _taskType = v),
                    ),

                    // STAFF
                    _buildDropdown(
                      label: "Assign To Staff",
                      items: staffList,
                      value: _selectedStaff,
                      onChange: (v) => setState(() => _selectedStaff = v),
                    ),

                    // PRIORITY
                    _buildDropdown(
                      label: "Priority",
                      items: priorityList,
                      value: _priority,
                      onChange: (v) => setState(() => _priority = v),
                    ),

                    const SizedBox(height: 10),

                    // Task Title
                    CustomeTextField(
                      label: "Task Title",
                      prefixICon: Icons.task_alt,
                      controller: _titleCtrl,
                      validator: (val) => val == null || val.isEmpty
                          ? "Enter task title"
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Description
                    CustomeTextField(
                      label: "Task Description",
                      prefixICon: Icons.description_outlined,
                      maxLine: 5,
                      controller: _descCtrl,
                    ),

                    const SizedBox(height: 16),

                    // DATE SELECTOR
                    GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month,
                                color: AppTheme.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate == null
                                  ? "Select Due Date"
                                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
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

                    const SizedBox(height: 20),

                    // PHOTO EVIDENCE REQUIRED
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          onChanged: (value) {
                            setState(() => _requireEvidence = value);
                          },
                        )
                      ],
                    ),

                    const SizedBox(height: 28),

                    // SUBMIT BUTTON
                    GradientButton(
                      text: "Assign Task",
                      onPressed: submitTask,
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

  // 🔽 DROPDOWN UI
  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChange,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          )
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChange,
        validator: (val) => val == null ? "Select $label" : null,
      ),
    );
  }

  // 🔽 DATE PICKER
  Future<void> pickDate() async {
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

  // 🔽 SUBMIT
  void submitTask() {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedStaff != null &&
        _priority != null &&
        _sopTitle != null &&
        _taskType != null) {
      task = TaskAssignModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        staffId: _selectedStaff!,
        staffName: _selectedStaff!,
        sopTitle: _sopTitle!,
        taskType: _taskType!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _selectedDate!,
        priority: _priority!,
        requireEvidence: _requireEvidence,
      );

      // Provider.of<TaskProvider>(context, listen: false).addTask(task);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task Assigned Successfully!")),
      );

      Navigator.pop(context);
    }
  }
}
