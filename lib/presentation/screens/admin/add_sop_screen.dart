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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text("Add SOP", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
                  "Create New SOP",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(height: 16),

                // SOP TITLE
                CustomeTextField(
                  label: "SOP Title",
                  controller: _titleCtrl,
                  prefixICon: Icons.article_outlined,
                  validator: (v) => v!.isEmpty ? "Enter SOP title" : null,
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
                  label: "Description",
                  controller: _descCtrl,
                  maxLine: 4,
                  prefixICon: Icons.description_outlined,
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
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
                        onChanged: (v) => setState(() => _requireEvidence = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // SUBMIT BUTTON
                GradientButton(
                  text: "Save SOP",
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        _frequency != null) {
                      final provider =
                          Provider.of<SopProvider>(context, listen: false);

                      // Parse steps from description (split by newline)
                      final steps = _stepsCtrl.text.trim().isEmpty
                          ? [_descCtrl.text.trim()]
                          : _stepsCtrl.text
                              .trim()
                              .split('\n')
                              .where((s) => s.trim().isNotEmpty)
                              .toList();

                      final sop = SOPModel(
                        id: _uuid.v4(),
                        title: _titleCtrl.text.trim(),
                        description: _descCtrl.text.trim(),
                        steps: steps,
                        frequency: _frequency!.toLowerCase() == 'daily'
                            ? TaskFrequency.daily
                            : _frequency!.toLowerCase() == 'weekly'
                                ? TaskFrequency.weekly
                                : TaskFrequency.monthly,
                        requiresPhoto: _requireEvidence,
                        createdAt: DateTime.now(),
                      );

                      await provider.addSop(sop);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("SOP Added Successfully!")),
                        );

                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ],
            ),
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
