import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/services/critical_compliance_service.dart';
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
  final CriticalComplianceService _criticalComplianceService =
      CriticalComplianceService();
  final AudioPlayer _rejectionVoicePlayer = AudioPlayer();
  SOPModel? _sop;
  bool _isLoadingSOP = true;
  bool _isSubmitting = false;
  bool _isRejectionVoicePlaying = false;
  bool _isRejectionVoiceLoading = false;

  Future<bool> _isBlockedByCriticalTask() async {
    if (widget.task.grade == TaskGrade.critical) return false;

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return false;

    final criticalTasks =
        await _criticalComplianceService.getIncompleteCriticalTasks(userId);
    final blocking =
        criticalTasks.where((t) => t.id != widget.task.id).toList();
    return blocking.isNotEmpty;
  }

  Future<void> _openRejectionMarkedImage(String url) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _guardCriticalTaskAction() async {
    try {
      final blocked = await _isBlockedByCriticalTask();
      if (!blocked || !mounted) return !blocked;

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

      return false;
    } catch (_) {
      return true;
    }
  }

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

    _rejectionVoicePlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isRejectionVoicePlaying = state == PlayerState.playing;
      });
    });

    _rejectionVoicePlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isRejectionVoicePlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _rejectionVoicePlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRejectionVoicePlayback() async {
    final url = widget.task.rejectionVoiceNoteUrl?.trim();
    if (url == null || url.isEmpty) return;

    if (url.startsWith('gs://')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Invalid voice note URL. Please re-upload the voice note.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (_isRejectionVoicePlaying) {
        await _rejectionVoicePlayer.pause();
        return;
      }

      setState(() {
        _isRejectionVoiceLoading = true;
      });

      await _rejectionVoicePlayer.play(UrlSource(url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to play voice note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRejectionVoiceLoading = false;
        });
      }
    }
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
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card

              // /// Meta chips
              // Wrap(
              //   spacing: 8,
              //   runSpacing: 8,
              //   children: [
              //     _buildStatusChip(
              //       icon: Icons.flag,
              //       label: widget.task.status.toString().split('.').last,
              //       color: _getStatusColor(widget.task.status),
              //     ),
              //     if (showLate)
              //       _buildStatusChip(
              //         icon: Icons.access_time,
              //         label: 'LATE',
              //         color: Colors.red,
              //       ),
              //     _buildStatusChip(
              //       icon: Icons.repeat,
              //       label: widget.task.frequency.toString().split('.').last,
              //       color: Colors.blue,
              //     ),
              //     _buildStatusChip(
              //       icon: Icons.photo_camera_back_outlined,
              //       label: _sop?.requiresPhoto == true
              //           ? 'Photo Required'
              //           : 'No Photo',
              //       color: _sop?.requiresPhoto == true
              //           ? Colors.orange
              //           : Colors.grey,
              //     ),
              //     if (_sop != null)
              //       _buildStatusChip(
              //         icon: Icons.rule,
              //         label: _sop!.title,
              //         color: Colors.purple,
              //       ),
              //   ],
              // ),

              const SizedBox(height: 20),

              // Task title and frequency card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                widget.task.frequency
                                    .toString()
                                    .split('.')
                                    .last,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera_back_outlined,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                _sop?.requiresPhoto == true
                                    ? 'Photo Required'
                                    : 'No Photo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                widget.task.status.toString().split('.').last,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showLate) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'LATE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Timing card
              _buildSectionCard(
                title: 'Timing Information',
                icon: Icons.schedule,
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.schedule,
                      title: 'Planned Start',
                      value: _formatDateTime(widget.task.plannedStartAt),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.flag_outlined,
                      title: 'Planned End',
                      value: _formatDateTime(widget.task.plannedEndAt),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      title: 'Due Date',
                      value: _formatDate(widget.task.dueDate),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.date_range,
                      title: 'Created',
                      value: _formatDate(widget.task.createdAt),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Description
              _buildSectionCard(
                title: 'Task Description',
                icon: Icons.description,
                child: Text(
                  widget.task.description.isNotEmpty
                      ? widget.task.description
                      : 'No description available.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              if (widget.task.rejectionReason != null &&
                  widget.task.rejectionReason!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Rejection Details',
                  icon: Icons.feedback_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.rejectionReason!.trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.task.rejectionMarkedImageUrl != null &&
                          widget.task.rejectionMarkedImageUrl!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => _openRejectionMarkedImage(
                            widget.task.rejectionMarkedImageUrl!.trim(),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 180,
                                  width: double.infinity,
                                  child: Image.network(
                                    widget.task.rejectionMarkedImageUrl!.trim(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.black.withOpacity(0.06),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.fullscreen,
                                            size: 16, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Preview',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (widget.task.rejectionVoiceNoteUrl != null &&
                          widget.task.rejectionVoiceNoteUrl!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              _isRejectionVoiceLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppTheme.error,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _isRejectionVoicePlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: AppTheme.error,
                                      size: 20,
                                    ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Voice note attached',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _isRejectionVoiceLoading
                                    ? null
                                    : _toggleRejectionVoicePlayback,
                                child: Text(
                                  _isRejectionVoicePlaying ? 'Pause' : 'Play',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              /// SOP Steps Section
              if (_isLoadingSOP)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_sop != null && _sop!.steps.isNotEmpty) ...[
                _buildSectionCard(
                  title: 'SOP Steps',
                  icon: Icons.rule,
                  child: Column(
                    children: _sop!.steps.asMap().entries.map((entry) {
                      final step = entry.value;
                      final stepNumber = entry.key + 1;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$stepNumber',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              /// --- ACTION BUTTONS ---
              _buildActionButtons(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      {required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.task.status == TaskStatus.rejected)
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final allowed = await _guardCriticalTaskAction();
                  if (!allowed || !mounted) return;

                  setState(() => _isSubmitting = true);
                  try {
                    await Provider.of<TaskProvider>(context, listen: false)
                        .reworkTask(widget.task.id);
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.startTask,
                      arguments: widget.task,
                    );
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Rework Task',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          // Only show Start Task button for pending/in-progress tasks
          if (widget.task.status == TaskStatus.pending ||
              widget.task.status == TaskStatus.inProgress)
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final allowed = await _guardCriticalTaskAction();
                  if (!allowed || !mounted) return;

                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.startTask,
                    arguments: widget.task,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Start Task",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          // Show submitted status for completed tasks
          if (widget.task.status == TaskStatus.completed ||
              widget.task.status == TaskStatus.verificationPending)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade100,
                      Colors.orange.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Submitted for verification",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // if (widget.task.status == TaskStatus.pending ||
          //     widget.task.status == TaskStatus.inProgress) ...[
          //   const SizedBox(width: 12),
          //   // Camera button for quick submission
          //   ElevatedButton(
          //     onPressed: _isSubmitting ? null : _handleQuickCameraSubmit,
          //     style: ElevatedButton.styleFrom(
          //       padding:
          //           const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          //       backgroundColor: Colors.green,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(16),
          //       ),
          //       elevation: 0,
          //       shadowColor: Colors.green.withOpacity(0.3),
          //     ),
          //     child: _isSubmitting
          //         ? const SizedBox(
          //             width: 20,
          //             height: 20,
          //             child: CircularProgressIndicator(
          //               strokeWidth: 2,
          //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          //             ),
          //           )
          //         : Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               Icon(Icons.camera_alt, color: Colors.white, size: 20),
          //               const SizedBox(width: 8),
          //               const Text(
          //                 "Submit",
          //                 style: TextStyle(
          //                     fontSize: 16,
          //                     color: Colors.white,
          //                     fontWeight: FontWeight.w700),
          //               ),
          //             ],
        ],
      ),
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
      final allowed = await _guardCriticalTaskAction();
      if (!allowed || !mounted) return;

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

      // Show success dialog and redirect to staff home
      await _showTaskSuccessDialog();
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
}
