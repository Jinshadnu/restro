import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sop_provider.dart';
import '../../../data/models/sop_model.dart';
import '../../../domain/entities/task_entity.dart';
import '../../widgets/custome_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../../utils/theme/theme.dart';
import 'package:uuid/uuid.dart';

class AddSopScreen extends StatefulWidget {
  const AddSopScreen({super.key});

  @override
  State<AddSopScreen> createState() => _AddSopScreenState();
}

class _AddSopScreenState extends State<AddSopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _stepsCtrl = TextEditingController();

  String? _frequency;
  bool _requireEvidence = false;

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
                'Check List Details',
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
                    ),

                    const SizedBox(height: 16),

                    // STEPS
                    CustomeTextField(
                      label: "Checklist Items (one per line)",
                      controller: _stepsCtrl,
                      maxLine: 6,
                      prefixICon: Icons.format_list_bulleted_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter steps" : null,
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

                    const SizedBox(height: 25),

                    // SUBMIT BUTTON
                    Consumer<SopProvider>(
                      builder: (context, provider, _) {
                        return GradientButton(
                          text: "Save SOP",
                          isLoading: provider.isLoading,
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  if (_frequency == null) return;

                                  final steps = _stepsCtrl.text
                                      .trim()
                                      .split('\n')
                                      .where((s) => s.trim().isNotEmpty)
                                      .toList();

                                  final sop = SOPModel(
                                    id: _uuid.v4(),
                                    title: _titleCtrl.text.trim(),
                                    description: _descCtrl.text.trim(),
                                    steps: steps,
                                    frequency: _frequency!.toLowerCase() ==
                                            'daily'
                                        ? TaskFrequency.daily
                                        : _frequency!.toLowerCase() == 'weekly'
                                            ? TaskFrequency.weekly
                                            : TaskFrequency.monthly,
                                    requiresPhoto: _requireEvidence,
                                    createdAt: DateTime.now(),
                                  );

                                  await provider.addSop(sop);

                                  if (!context.mounted) return;

                                  if (provider.errorMessage.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(provider.errorMessage)),
                                    );
                                    return;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Checklist Added Successfully!")),
                                  );
                                  Navigator.pop(context);
                                },
                        );
                      },
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
        border: Border.all(color: Colors.grey.shade300),
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
}
