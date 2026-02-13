import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restro/utils/app_logger.dart';
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
    return DateFormat('MMM d, y').format(date.toLocal());
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, y • h:mm a').format(date.toLocal());
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
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Task Details",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
            ),
            onPressed: () {
              // Option to show more details or actions
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(showLate),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Task List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (_sop != null && _sop!.steps.isNotEmpty)
                           Text(
                             '${_sop!.steps.length} Steps',
                             style: const TextStyle(
                               color: AppTheme.textSecondary,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.task.rejectionReason != null &&
                              widget.task.rejectionReason!.trim().isNotEmpty) ...[
                            _buildRejectionCard(),
                            const SizedBox(height: 24),
                          ],
                          if (_isLoadingSOP)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ))
                          else if (_sop != null && _sop!.steps.isNotEmpty)
                            ..._sop!.steps.asMap().entries.map((entry) {
                              return _buildSOPItem(
                                  entry.key + 1, entry.value, isCompletedState);
                            }).toList()
                          else
                             const Center(
                               child: Padding(
                                 padding: EdgeInsets.all(20.0),
                                 child: Text(
                                   "No specific steps defined.",
                                   style: TextStyle(color: Colors.grey),
                                 ),
                               ),
                             ),
                           const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  Widget _buildHeader(bool showLate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildHeaderTag(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(widget.task.dueDate),
              ),
              const SizedBox(width: 10),
              _buildHeaderTag(
                icon: Icons.repeat_rounded,
                label: widget.task.frequency.toString().split('.').last,
              ),
              if (showLate) ...[
                const SizedBox(width: 10),
                _buildHeaderTag(
                  icon: Icons.warning_amber_rounded,
                  label: 'LATE',
                  textColor: AppTheme.error,
                  backgroundColor: Colors.white,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.task.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.task.description.isNotEmpty
                ? widget.task.description
                : 'No description provided.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTag({
    required IconData icon,
    required String label,
    Color? textColor,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor ?? Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOPItem(int index, String text, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2938).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                width: 2,
              ),
              color: isCompleted ? AppTheme.primaryColor : Colors.transparent,
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Center(
                    child: Text(
                      "$index",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Step $index",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Task Rejected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.task.rejectionReason!.trim(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F1D1D),
              height: 1.5,
            ),
          ),
          if (widget.task.rejectionMarkedImageUrl != null &&
              widget.task.rejectionMarkedImageUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openRejectionMarkedImage(
                widget.task.rejectionMarkedImageUrl!.trim(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                     SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Image.network(
                        widget.task.rejectionMarkedImageUrl!.trim(),
                        fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        child: const Center(
                          child: Icon(Icons.zoom_in,
                              color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.task.rejectionVoiceNoteUrl != null &&
              widget.task.rejectionVoiceNoteUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isRejectionVoiceLoading
                        ? null
                        : _toggleRejectionVoicePlayback,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: _isRejectionVoiceLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isRejectionVoicePlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Play Rejection Note',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F1D1D),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    Widget? mainButton;

    if (widget.task.status == TaskStatus.rejected) {
      mainButton = ElevatedButton(
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
          backgroundColor: const Color(0xFF1E2938), // Dark button
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Rework Task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      );
    } else if (widget.task.status == TaskStatus.pending ||
        widget.task.status == TaskStatus.inProgress) {
      mainButton = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryLight,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final allowed = await _guardCriticalTaskAction();
              if (!allowed || !mounted) return;

              Navigator.pushReplacementNamed(
                context,
                AppRoutes.startTask,
                arguments: widget.task,
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Start Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (widget.task.status == TaskStatus.completed ||
        widget.task.status == TaskStatus.verificationPending) {
       mainButton = Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.hourglass_empty_rounded,
                color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text(
              'Submitted',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else if (widget.task.status == TaskStatus.approved) {
       mainButton = Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 22),
            SizedBox(width: 10),
            Text(
              'Approved',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return mainButton ?? const SizedBox.shrink();
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
    if (_isSubmitting) return;

    final messenger = ScaffoldMessenger.of(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      final allowed = await _guardCriticalTaskAction();
      if (!allowed || !mounted) return;

      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        messenger.showSnackBar(
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

      await taskProvider.completeTask(
        widget.task.id,
        photo: File(photo.path),
      );

      if (!mounted) return;

      // Show success dialog and redirect to staff home
      await _showTaskSuccessDialog();
    } catch (e, st) {
      AppLogger.e(
        'TaskDetailsScreen',
        e,
        st,
        message: '_handleQuickCameraSubmit failed taskId=${widget.task.id}',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to submit task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
