import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/sop_provider.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/widgets/custome_text_field.dart';
import 'package:restro/presentation/widgets/gradient_button.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:uuid/uuid.dart';

class ManagerAddSopScreen extends StatefulWidget {
  const ManagerAddSopScreen({super.key});

  @override
  State<ManagerAddSopScreen> createState() => _ManagerAddSopScreenState();
}

class _ManagerAddSopScreenState extends State<ManagerAddSopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _stepsCtrl = TextEditingController();

  String? _frequency;
  bool _requireEvidence = false;
  bool _isCritical = false;
  bool _isLoading = false;

  final List<String> frequencies = ["Daily", "Weekly", "Monthly"];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title:
            const Text("Add Checklist", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Checklist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Define standard operating procedures for staff tasks',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.info_outline),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomeTextField(
                      label: "Checklist Title",
                      controller: _titleCtrl,
                      prefixICon: Icons.article_outlined,
                      validator: (v) =>
                          v!.isEmpty ? "Enter checklist title" : null,
                    ),
                    const SizedBox(height: 16),
                    CustomeTextField(
                      label: "Description",
                      controller: _descCtrl,
                      maxLine: 4,
                      prefixICon: Icons.description_outlined,
                      validator: (v) => v!.isEmpty ? "Enter description" : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Checklist Items Section
              _buildSectionHeader('Checklist Items', Icons.list_alt),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomeTextField(
                      label: "Checklist Items (one per line)",
                      controller: _stepsCtrl,
                      maxLine: 6,
                      prefixICon: Icons.list_alt,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enter each checklist item on a new line. These will be the steps staff need to complete.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Section
              _buildSectionHeader('Settings', Icons.settings),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDropdown(
                      label: "Frequency",
                      items: frequencies,
                      value: _frequency,
                      onChange: (v) => setState(() => _frequency = v),
                    ),
                    const SizedBox(height: 20),
                    _buildToggleRow(
                      title: "Photo Evidence Required",
                      subtitle: "Staff must upload photo to complete task",
                      icon: Icons.photo_camera_outlined,
                      value: _requireEvidence,
                      onChanged: (v) => setState(() => _requireEvidence = v),
                      activeColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    _buildToggleRow(
                      title: "Critical Checklist",
                      subtitle: "Requires immediate attention and completion",
                      icon: Icons.priority_high,
                      value: _isCritical,
                      onChanged: (v) => setState(() => _isCritical = v),
                      activeColor: AppTheme.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GradientButton(
                      text: "Save Checklist",
                      onPressed: _saveSOP,
                    ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: activeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Dropdown Builder
  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
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
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChange,
        validator: (v) => v == null ? "Select $label" : null,
      ),
    );
  }

  Future<void> _saveSOP() async {
    if (!_formKey.currentState!.validate() || _frequency == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<SopProvider>(context, listen: false);

      // Parse steps from steps field (split by newline)
      final steps = _stepsCtrl.text.trim().isEmpty
          ? [_descCtrl.text.trim()] // Use description if no steps provided
          : _stepsCtrl.text
              .trim()
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList();

      // Convert frequency string to enum
      TaskFrequency frequency;
      switch (_frequency!.toLowerCase()) {
        case 'daily':
          frequency = TaskFrequency.daily;
          break;
        case 'weekly':
          frequency = TaskFrequency.weekly;
          break;
        case 'monthly':
          frequency = TaskFrequency.monthly;
          break;
        default:
          frequency = TaskFrequency.daily;
      }

      final sop = SOPModel(
        id: _uuid.v4(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        steps: steps,
        frequency: frequency,
        requiresPhoto: _requireEvidence,
        isCritical: _isCritical,
        createdAt: DateTime.now(),
      );

      await provider.addSop(sop);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Checklist Added Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleCtrl.clear();
        _descCtrl.clear();
        _stepsCtrl.clear();
        setState(() {
          _frequency = null;
          _requireEvidence = false;
          _isCritical = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
