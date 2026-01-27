import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/services/critical_compliance_service.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/navigation/app_routes.dart';

class StartTaskScreen extends StatefulWidget {
  final TaskModel task;

  const StartTaskScreen({super.key, required this.task});

  @override
  State<StartTaskScreen> createState() => _StartTaskScreenState();
}

class _StartTaskScreenState extends State<StartTaskScreen> {
  final ImagePicker picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final CriticalComplianceService _criticalComplianceService =
      CriticalComplianceService();

  // Always maintain exactly 3 image slots
  List<File?> images = List<File?>.filled(3, null);
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
    // Ensure images list always has exactly 3 slots
    images = List<File?>.filled(3, null);
    startDateTime = DateFormat("dd MMM yyyy • hh:mm a").format(DateTime.now());
    _loadSOPAndRequirement();

    // Safety net: block entering non-critical tasks if any other critical task is pending
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _guardCriticalTaskEntry();
    });
  }

  Future<void> _guardCriticalTaskEntry() async {
    if (!mounted) return;
    if (widget.task.grade == TaskGrade.critical) return;

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    final criticalTasks =
        await _criticalComplianceService.getIncompleteCriticalTasks(userId);
    final blocking =
        criticalTasks.where((t) => t.id != widget.task.id).toList();
    if (blocking.isEmpty || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action Blocked'),
        content: const Text(
          'CRITICAL TASK IS PENDING. PLEASE COMPLETE IT BEFORE PROCEEDING.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  Future<void> _loadSOPAndRequirement() async {
    setState(() => _isLoadingSOP = true);

    // 1. Initial photo requirement from task
    _requiresPhoto = widget.task.requiresPhoto;

    // 2. Fetch SOP for steps and potential override
    try {
      final sopId = widget.task.sopid.trim();
      debugPrint(
          "Loading SOP for task: ${widget.task.title}, SOP ID: '$sopId'");

      final sop =
          sopId.isNotEmpty ? await _firestoreService.getSOPById(sopId) : null;

      SOPModel? resolved = sop;
      debugPrint("SOP found by ID: ${resolved != null}");

      // Fallback: if task doesn't have a valid SOP id, try matching by SOP title.
      if (resolved == null) {
        debugPrint("Trying to find SOP by title match...");
        final allSops = await _firestoreService.getSOPs();
        debugPrint("Found ${allSops.length} SOPs in database");

        final taskTitle = widget.task.title.trim().toLowerCase();
        debugPrint("Looking for SOP with title: '$taskTitle'");

        for (final s in allSops) {
          final sopTitle = s.title.trim().toLowerCase();
          debugPrint("Checking SOP: '$sopTitle'");
          if (sopTitle == taskTitle) {
            resolved = s;
            debugPrint("Found matching SOP!");
            break;
          }
        }
      }

      if (mounted && resolved != null) {
        final resolvedSop = resolved;
        debugPrint("Setting SOP steps: ${resolvedSop.steps}");
        setState(() {
          _sopSteps = resolvedSop.steps;
          _stepChecklist = List<bool>.filled(_sopSteps.length, false);
          // If task doesn't explicitly have requiresPhoto, use SOP's
          if (!widget.task.requiresPhoto) {
            _requiresPhoto = resolvedSop.requiresPhoto;
          }
        });
      } else {
        debugPrint("No SOP found for task: ${widget.task.title}");
        // Use task description as checklist items
        final taskDescription = widget.task.description.trim();
        if (taskDescription.isNotEmpty) {
          debugPrint("Using task description as checklist: '$taskDescription'");
          // Split description by lines or bullet points to create checklist items
          final List<String> descriptionItems = [];

          // Try to split by common separators
          final lines = taskDescription.split(RegExp(r'[\n\r•\-\*]'));
          for (final line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.isNotEmpty) {
              // Remove bullet points or numbering if present
              final cleanLine =
                  trimmedLine.replaceFirst(RegExp(r'^[\d\.\)\-\•\*\s]+'), '');
              if (cleanLine.isNotEmpty) {
                descriptionItems.add(cleanLine);
              }
            }
          }

          // If no lines found, use the whole description as one item
          if (descriptionItems.isEmpty) {
            descriptionItems.add(taskDescription);
          }

          debugPrint(
              "Created ${descriptionItems.length} checklist items from description");
          setState(() {
            _sopSteps = descriptionItems;
            _stepChecklist = List<bool>.filled(_sopSteps.length, false);
          });
        } else {
          debugPrint("Task description is empty, no checklist items created");
        }
      }
    } catch (e) {
      debugPrint("Error loading SOP: $e");
    }

    if (mounted) {
      setState(() => _isLoadingSOP = false);
    }
  }

  Future<void> pickImage(int index) async {
    try {
      // Validate index bounds - we only support 3 images (0, 1, 2)
      if (index < 0 || index >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid image index'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Camera permission is required to capture task photos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null && mounted) {
        debugPrint('Image picked: ${picked.path}');
        debugPrint(
            'Image exists before setState: ${File(picked.path).existsSync()}');

        // Create a new list to avoid state mutation issues
        final newImages = List<File?>.from(images);
        newImages[index] = File(picked.path);

        debugPrint('Setting image at index $index');
        debugPrint('New images array: $newImages');

        setState(() {
          images = newImages;
        });

        debugPrint('Image set successfully');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Image error: $e")));
      }
    }
  }

  bool get canSubmit {
    // Check if all checklist items are completed
    bool checklistDone = _stepChecklist.every((checked) => checked);
    debugPrint('Checklist done: $checklistDone');
    debugPrint('Requires photo: $_requiresPhoto');
    debugPrint('Images array length: ${images.length}');
    debugPrint(
        'Non-null images count: ${images.where((e) => e != null).length}');

    if (!checklistDone) {
      debugPrint('Cannot submit: checklist not complete');
      return false;
    }

    // If photo is not required, allow submit always (notes are optional)
    if (!_requiresPhoto) {
      debugPrint('Can submit: photo not required');
      return true;
    }

    // If photo is required, allow submit once at least one image is captured
    bool canSubmitWithPhoto = images.where((e) => e != null).isNotEmpty;
    debugPrint('Can submit with photo: $canSubmitWithPhoto');
    return canSubmitWithPhoto;
  }

  /// Calculate checklist progress (0.0 to 1.0)
  double _getChecklistProgress() {
    if (_sopSteps.isEmpty) return 1.0; // No steps means 100% complete
    final completedSteps = _stepChecklist.where((checked) => checked).length;
    return completedSteps / _sopSteps.length;
  }

  /// Show feedback when a step is completed
  void _showStepCompletionFeedback(int stepIndex) {
    // Only show feedback if all steps are now complete
    if (_stepChecklist.every((checked) => checked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 All checklist steps completed! You can now submit the task.',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show validation feedback when submit button is disabled
  void _showValidationFeedback() {
    List<String> missingItems = [];

    // Check checklist completion
    if (!_stepChecklist.every((checked) => checked)) {
      final remainingSteps = _stepChecklist.where((checked) => !checked).length;
      missingItems.add(
          '$remainingSteps checklist step${remainingSteps > 1 ? 's' : ''} remaining');
    }

    // Check photo requirement
    if (_requiresPhoto && images.where((e) => e != null).isEmpty) {
      missingItems.add('Photo capture required');
    }

    String message = missingItems.isNotEmpty
        ? 'Please complete: ${missingItems.join(', ')}'
        : 'Please complete all required fields';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ $message',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            _buildChecklistSection(),

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
                      // Safely get the first non-null image
                      try {
                        debugPrint('Images array: $images');
                        debugPrint(
                            'Non-null images: ${images.where((e) => e != null).toList()}');

                        photo = images.firstWhere(
                          (file) => file != null,
                          orElse: () => null,
                        );

                        debugPrint('Selected photo: $photo');
                      } catch (e) {
                        debugPrint('Error getting photo: $e');
                        photo = null;
                      }
                    }

                    try {
                      debugPrint('Starting task completion...');
                      debugPrint('Task ID: ${widget.task.id}');
                      debugPrint('Requires photo: $_requiresPhoto');
                      debugPrint(
                          'Images count: ${images.where((e) => e != null).length}');

                      if (photo != null) {
                        debugPrint('Photo path: ${photo.path}');
                        debugPrint('Photo exists: ${photo.existsSync()}');
                        debugPrint('Photo size: ${photo.lengthSync()} bytes');
                      }

                      await taskProvider.completeTask(
                        widget.task.id,
                        photo: photo,
                      );

                      if (!mounted) return;

                      // Show success dialog and redirect to staff home
                      await _showTaskSuccessDialog();
                    } catch (e) {
                      debugPrint('Error completing task: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit task: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : () {
                    // Show validation feedback when button is disabled
                    _showValidationFeedback();
                  },
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
    // Ensure index is within bounds (always 0, 1, 2)
    if (index < 0 || index >= 3) {
      return Container(
        height: 110,
        width: 110,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.error, color: Colors.red),
      );
    }

    // Safely get image - ensure images list has the required index
    final File? image = (images.length > index) ? images[index] : null;

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
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  cacheHeight: 300,
                ),
              ),
      ),
    );
  }

  Future<void> _showTaskSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Task Completed!'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Your task has been submitted successfully.'),
                SizedBox(height: 8),
                Text('It is now pending verification from your manager.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                // Navigate to staff home screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.staffDashboard,
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildChecklistSection() {
    if (_isLoadingSOP) {
      return const Center(child: CircularProgressIndicator());
    } else if (_sopSteps.isNotEmpty) {
      return Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Task Checklist",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getChecklistProgress() == 1.0
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${(_getChecklistProgress() * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getChecklistProgress() == 1.0
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _getChecklistProgress(),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getChecklistProgress() == 1.0
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_stepChecklist.where((checked) => checked).length} of ${_sopSteps.length} steps completed",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Checklist items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sopSteps.length,
            itemBuilder: (context, index) {
              final isChecked = _stepChecklist[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isChecked
                      ? [
                          BoxShadow(
                            color: Colors.green.shade50,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: CheckboxListTile(
                  value: isChecked,
                  onChanged: (val) {
                    setState(() {
                      _stepChecklist[index] = val ?? false;
                    });
                    // Provide haptic feedback
                    if (val == true) {
                      // Add completion feedback
                      _showStepCompletionFeedback(index);
                    }
                  },
                  title: Text(
                    _sopSteps[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isChecked ? FontWeight.w500 : FontWeight.normal,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey.shade600 : Colors.black87,
                    ),
                  ),
                  subtitle: isChecked
                      ? Text(
                          "Step ${index + 1} completed",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                  activeColor: Colors.green,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
        ],
      );
    } else {
      // No checklist available
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Checklist Available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No SOP steps found for this task. Please ask your manager to add SOP steps, or tap retry.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: _loadSOPAndRequirement,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
