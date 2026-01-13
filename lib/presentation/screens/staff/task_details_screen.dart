import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  SOPModel? _sop;
  bool _isLoadingSOP = true;
  bool _isSubmitting = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, y').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  @override
  void initState() {
    super.initState();
    _loadSOP();
  }

  Future<void> _loadSOP() async {
    if (widget.task.sopid.isNotEmpty) {
      try {
        final sop = await _firestoreService.getSOPById(widget.task.sopid);
        if (mounted) {
          setState(() {
            _sop = sop;
            _isLoadingSOP = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingSOP = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingSOP = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompletedState = widget.task.status == TaskStatus.completed ||
        widget.task.status == TaskStatus.approved;

    final DateTime? lateCutoff =
        widget.task.plannedEndAt ?? widget.task.dueDate;

    final bool isLateComputed = !isCompletedState &&
        lateCutoff != null &&
        DateTime.now().isAfter(lateCutoff);

    final bool showLate = widget.task.isLate || isLateComputed;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              Text(
                widget.task.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              /// Meta chips
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _chip(
                    icon: Icons.flag,
                    label: widget.task.status.toString().split('.').last,
                    color:
                        _getStatusColor(widget.task.status).withOpacity(0.12),
                    textColor: _getStatusColor(widget.task.status),
                  ),
                  if (showLate)
                    _chip(
                      icon: Icons.access_time,
                      label: 'LATE',
                      color: Colors.red.shade50,
                      textColor: Colors.red.shade800,
                    ),
                  _chip(
                    icon: Icons.repeat,
                    label:
                        "Frequency: ${widget.task.frequency.toString().split('.').last}",
                    color: Colors.blue.shade50,
                    textColor: Colors.blue.shade900,
                  ),
                  _chip(
                    icon: Icons.photo_camera_back_outlined,
                    label:
                        "Photo required: ${_sop?.requiresPhoto == true ? 'Yes' : 'No'}",
                    color: Colors.orange.shade50,
                    textColor: Colors.orange.shade900,
                  ),
                  if (_sop != null)
                    _chip(
                      icon: Icons.rule,
                      label: "SOP: ${_sop!.title}",
                      color: Colors.purple.shade50,
                      textColor: Colors.purple.shade900,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              /// Timing card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoTile(
                      icon: Icons.schedule,
                      title: 'Planned Start',
                      value: _formatDateTime(widget.task.plannedStartAt),
                    ),
                    const SizedBox(height: 10),
                    _infoTile(
                      icon: Icons.flag_outlined,
                      title: 'Planned End',
                      value: _formatDateTime(widget.task.plannedEndAt),
                    ),
                    const SizedBox(height: 10),
                    _infoTile(
                      icon: Icons.calendar_today,
                      title: 'Due Date',
                      value: _formatDate(widget.task.dueDate),
                    ),
                    const SizedBox(height: 10),
                    _infoTile(
                      icon: Icons.date_range,
                      title: 'Created',
                      value: _formatDate(widget.task.createdAt),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              /// Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task.description.isNotEmpty
                          ? widget.task.description
                          : 'No description available.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              /// SOP Steps Section
              if (_isLoadingSOP)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_sop != null && _sop!.steps.isNotEmpty) ...[
                const SizedBox(height: 25),
                const Text(
                  "SOP Steps",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._sop!.steps.asMap().entries.map((entry) {
                  final step = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_box_outline_blank,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 40),

              /// --- ACTION BUTTONS ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.startTask,
                            arguments: widget.task);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Start Task",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Camera button for quick submission
                  if (widget.task.status == TaskStatus.pending ||
                      widget.task.status == TaskStatus.inProgress)
                    ElevatedButton(
                      onPressed:
                          _isSubmitting ? null : _handleQuickCameraSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                    ),
                ],
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
      {required IconData icon,
      required String label,
      required Color color,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// --- Reusable Info Tile ---
  Widget _infoTile(
      {required IconData icon,
      required String title,
      required String value,
      Color? color}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "$title\n$value",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        if (color != null) CircleAvatar(radius: 8, backgroundColor: color),
      ],
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().split('.').last.toLowerCase();
    switch (statusStr) {
      case 'pending':
        return Colors.orange;
      case 'inprogress':
        return Colors.blue;
      case 'verificationpending':
        return Colors.purple;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleQuickCameraSubmit() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to submit task'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Capture photo
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) {
        // User cancelled camera
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.completeTask(
        widget.task.id,
        photo: File(photo.path),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task submitted successfully with photo'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
