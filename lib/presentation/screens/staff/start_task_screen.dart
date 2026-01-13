import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/utils/theme/theme.dart';

class StartTaskScreen extends StatefulWidget {
  final TaskModel task;

  const StartTaskScreen({super.key, required this.task});

  @override
  State<StartTaskScreen> createState() => _StartTaskScreenState();
}

class _StartTaskScreenState extends State<StartTaskScreen> {
  final ImagePicker picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();

  List<File?> images = [null, null, null]; // up to 3 images when required
  final TextEditingController notesController = TextEditingController();

  List<String> _sopSteps = [];
  List<bool> _stepChecklist = [];
  bool _isLoadingSOP = true;

  late String startDateTime;
  String? completionDateTime; // assigned on submit

  bool _requiresPhoto = false;

  @override
  void initState() {
    super.initState();
    startDateTime = DateFormat("dd MMM yyyy • hh:mm a").format(DateTime.now());
    _loadSOPAndRequirement();
  }

  Future<void> _loadSOPAndRequirement() async {
    setState(() => _isLoadingSOP = true);
    
    // 1. Initial photo requirement from task
    _requiresPhoto = widget.task.requiresPhoto;

    // 2. Fetch SOP for steps and potential override
    if (widget.task.sopid.isNotEmpty) {
      try {
        final sop = await _firestoreService.getSOPById(widget.task.sopid);
        if (mounted && sop != null) {
          setState(() {
            _sopSteps = sop.steps;
            _stepChecklist = List<bool>.filled(sop.steps.length, false);
            // If task doesn't explicitly have requiresPhoto, use SOP's
            if (!widget.task.requiresPhoto) {
              _requiresPhoto = sop.requiresPhoto;
            }
          });
        }
      } catch (e) {
        debugPrint("Error loading SOP: $e");
      }
    }
    
    if (mounted) {
      setState(() => _isLoadingSOP = false);
    }
  }

  Future<void> pickImage(int index) async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Camera permission is required to capture task photos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        setState(() {
          images[index] = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image error: $e")));
    }
  }

  bool get canSubmit {
    // Check if all checklist items are completed
    bool checklistDone = _stepChecklist.every((checked) => checked);
    if (!checklistDone) return false;

    // If photo is not required, allow submit always (notes are optional)
    if (!_requiresPhoto) return true;

    // If photo is required, allow submit once at least one image is captured
    return images.where((e) => e != null).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final doneImages = images.where((e) => e != null).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Start Task',
          style: TextStyle(color: AppTheme.yellow),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TASK TITLE
            Text(
              widget.task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _sopSteps.isNotEmpty
                  ? "Complete the checklist, capture required images, and provide finishing notes."
                  : (_requiresPhoto
                      ? "Capture required images and fill in all details before you submit."
                      : "Provide the task completion notes and submit."),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),

            const SizedBox(height: 20),

            /// ===========================
            /// ✅ CHECKLIST SECTION
            /// ===========================
            if (_isLoadingSOP)
              const Center(child: CircularProgressIndicator())
            else if (_sopSteps.isNotEmpty) ...[
              const Text(
                "Task Checklist",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sopSteps.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _stepChecklist[index]
                            ? Colors.green.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _stepChecklist[index],
                      onChanged: (val) {
                        setState(() {
                          _stepChecklist[index] = val ?? false;
                        });
                      },
                      title: Text(
                        _sopSteps[index],
                        style: TextStyle(
                          fontSize: 14,
                          decoration: _stepChecklist[index]
                              ? TextDecoration.lineThrough
                              : null,
                          color: _stepChecklist[index]
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                      activeColor: Colors.green,
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
            ],

            /// ===========================
            /// 📅 DATE & TIME SECTION
            /// ===========================
            const Text(
              "Task Timing Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            _timeCard("Task Start Time", startDateTime, Icons.play_circle_fill),
            const SizedBox(height: 10),
            _timeCard(
              "Task Completion Time",
              completionDateTime ?? "Not Completed Yet",
              Icons.check_circle,
            ),

            const SizedBox(height: 25),

            /// IMAGE SECTION (only when photo is required)
            if (_requiresPhoto) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Images Required",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "$doneImages/3",
                    style: TextStyle(
                      fontSize: 15,
                      color: doneImages == 3 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: doneImages / 3,
                backgroundColor: Colors.grey.shade300,
                color: doneImages == 3 ? Colors.green : Colors.blue,
              ),

              const SizedBox(height: 20),

              /// IMAGE BOXES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) => _imageBox(index)),
              ),

              const SizedBox(height: 25),
            ],

            /// NOTES FIELD
            const Text(
              "Task Notes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Describe the task completion details...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: 30),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: canSubmit
                ? () async {
                    /// Set COMPLETION TIME (local display)
                    setState(() {
                      completionDateTime = DateFormat("dd MMM yyyy • hh:mm a")
                          .format(DateTime.now());
                    });

                    final taskProvider =
                        Provider.of<TaskProvider>(context, listen: false);

                    // Use the first captured image when photos are required
                    File? photo;
                    if (_requiresPhoto) {
                      photo = images.firstWhere(
                        (file) => file != null,
                        orElse: () => null,
                      );
                    }

                    try {
                      await taskProvider.completeTask(
                        widget.task.id,
                        photo: photo,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task submitted successfully'),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit task: $e'),
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Submit Task",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  /// TIME CARD UI (Reusable)
  Widget _timeCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// IMAGE BOX UI
  Widget _imageBox(int index) {
    final image = images[index];

    return GestureDetector(
      onTap: () => pickImage(index),
      child: Container(
        height: 110,
        width: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 30, color: Colors.grey.shade600),
                  const SizedBox(height: 6),
                  Text(
                    "Capture",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  )
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(image, fit: BoxFit.cover),
              ),
      ),
    );
  }
}
