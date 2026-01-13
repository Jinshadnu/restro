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
              Text(
                'Checklist Details',
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SOP TITLE
                    CustomeTextField(
                      label: "Checklist Title",
                      controller: _titleCtrl,
                      prefixICon: Icons.article_outlined,
                      validator: (v) =>
                          v!.isEmpty ? "Enter checklist title" : null,
                    ),
                    const SizedBox(height: 12),

                    // DESCRIPTION
                    CustomeTextField(
                      label: "Description",
                      controller: _descCtrl,
                      maxLine: 4,
                      prefixICon: Icons.description_outlined,
                      validator: (v) => v!.isEmpty ? "Enter description" : null,
                    ),
                    const SizedBox(height: 12),

                    // STEPS
                    CustomeTextField(
                      label: "Checklist Items (one per line)",
                      controller: _stepsCtrl,
                      maxLine: 6,
                      prefixICon: Icons.list_alt,
                    ),
                    const SizedBox(height: 16),

                    // FREQUENCY DROPDOWN
                    _buildDropdown(
                      label: "Frequency",
                      items: frequencies,
                      value: _frequency,
                      onChange: (v) => setState(() => _frequency = v),
                    ),
                    const SizedBox(height: 16),

                    // PHOTO EVIDENCE SWITCH
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Photo Evidence Required",
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: _requireEvidence,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (v) =>
                                setState(() => _requireEvidence = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CRITICAL SOP SWITCH
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Critical SOP",
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: _isCritical,
                            activeColor: AppTheme.error,
                            onChanged: (v) => setState(() => _isCritical = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUBMIT BUTTON
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : GradientButton(
                            text: "Save Checklist",
                            onPressed: _saveSOP,
                          ),
                    const SizedBox(height: 10), // Extra bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
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
