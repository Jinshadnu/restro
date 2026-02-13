import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/data/models/task_model.dart';
import 'package:restro/domain/entities/task_entity.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/presentation/widgets/image_markup_screen.dart';
import 'package:restro/presentation/widgets/voice_note_recorder.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:restro/utils/app_logger.dart';

class ManagerTaskVerificationDetailsScreen extends StatefulWidget {
  final String taskId;

  const ManagerTaskVerificationDetailsScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<ManagerTaskVerificationDetailsScreen> createState() =>
      _ManagerTaskVerificationDetailsScreenState();
}

class _ManagerTaskVerificationDetailsScreenState
    extends State<ManagerTaskVerificationDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSubmitting = false;

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Not set';
    return DateFormat('MMM d, y • h:mm a').format(dt.toLocal());
  }

  String _statusLabel(TaskStatus status) {
    return status.toString().split('.').last;
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.verificationPending:
        return Colors.orange;
      case TaskStatus.approved:
        return Colors.green;
      case TaskStatus.rejected:
        return Colors.red;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.blueGrey;
      case TaskStatus.pending:
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>> _load() async {
    final task = await _firestoreService.getTaskById(widget.taskId);
    if (task == null) {
      return {
        'task': null,
        'staffName': null,
      };
    }

    final staffId = task.assignedTo;
    String? staffName;
    if (staffId.isNotEmpty) {
      final staff = await _firestoreService.getUserById(staffId);
      staffName = (staff?['name'] ?? '').toString();
      if (staffName.trim().isEmpty) {
        staffName = null;
      }
    }

    return {
      'task': task,
      'staffName': staffName,
    };
  }

  List<String> _extractPhotoUrls(Map<String, dynamic> raw) {
    final urls = <String>[];

    final photoUrls = raw['photoUrls'];
    if (photoUrls is List) {
      for (final u in photoUrls) {
        final s = u?.toString().trim();
        if (s != null && s.isNotEmpty) urls.add(s);
      }
    }

    final single = raw['photoUrl']?.toString().trim();
    if (single != null && single.isNotEmpty) {
      if (!urls.contains(single)) urls.add(single);
    }

    return urls;
  }

  Future<void> _approve(TaskModel task) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<TaskProvider>(context, listen: false)
          .verifyTask(task.id, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task approved'),
          backgroundColor: AppTheme.success,
        ),
      );
      await Navigator.of(context).maybePop();
    } catch (e, st) {
      AppLogger.e(
        'ManagerTaskVerificationDetails',
        e,
        st,
        message: '_approve failed',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reject(TaskModel task) async {
    if (task.photoUrl == null || task.photoUrl!.isEmpty) {
      // Fallback to text-based rejection if no photo
      await _showTextRejectionDialog(task);
      return;
    }

    // Navigate to image markup screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageMarkupScreen(
          imageUrl: task.photoUrl!,
          onConfirm: (markedImageBytes, reason, voiceNote) async {
            await _processRejection(task, reason, markedImageBytes, voiceNote);
          },
        ),
      ),
    );
  }

  Future<void> _showTextRejectionDialog(TaskModel task) async {
    final reasonController = TextEditingController();
    File? voiceNote;
    bool isRecording = false;
    final res = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text('Reject Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                VoiceNoteRecorder(
                  onChanged: (file) {
                    setLocal(() {
                      voiceNote = file;
                    });
                  },
                  onRecordingChanged: (v) {
                    setLocal(() {
                      isRecording = v;
                    });
                  },
                ),
                if (isRecording) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Press Stop to finish recording before rejecting.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isRecording
                    ? null
                    : () {
                        final v = reasonController.text.trim();
                        if (v.isEmpty) return;
                        Navigator.pop(context, v);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      ),
    );

    final reason = (res ?? '').trim();
    if (reason.isNotEmpty) {
      await _processRejection(task, reason, null, voiceNote);
    }
  }

  Future<void> _processRejection(
    TaskModel task,
    String reason,
    Uint8List? markedImageBytes,
    File? voiceNote,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<TaskProvider>(context, listen: false).verifyTask(
        task.id,
        false,
        rejectionReason: reason,
        rejectionVoiceNote: voiceNote,
        rejectionMarkedImageBytes: markedImageBytes,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task rejected and returned to staff'),
          backgroundColor: AppTheme.warning,
        ),
      );
      await Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openImage(BuildContext context, String url) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
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

  // Enhanced section widget
  Widget _buildEnhancedSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
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
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Enhanced chip widget
  Widget _buildEnhancedChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced detail row
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading task details...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              body: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error Loading Task',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final task = data['task'] as TaskModel?;
          if (task == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              body: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Task Not Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The requested task could not be found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final staffName = (data['staffName'] as String?);

          final raw = task.toJson();
          final photoUrls = _extractPhotoUrls(raw);
          final showPhotos = task.requiresPhoto && photoUrls.isNotEmpty;

          return CustomScrollView(
            slivers: [
              // Premium header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.task_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(task.status).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary section
                    _buildEnhancedSection(
                      title: 'Task Summary',
                      icon: Icons.summarize_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.description,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildEnhancedChip(
                                icon: Icons.person_outline,
                                label: staffName != null
                                    ? staffName
                                    : task.assignedTo,
                                color: AppTheme.primaryColor,
                              ),
                              _buildEnhancedChip(
                                icon: Icons.flag_outlined,
                                label: _statusLabel(task.status),
                                color: _statusColor(task.status),
                              ),
                              if (task.completedAt != null)
                                _buildEnhancedChip(
                                  icon: Icons.access_time,
                                  label: DateFormat('MMM d')
                                      .format(task.completedAt!),
                                  color: AppTheme.tertiaryColor,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Details section
                    _buildEnhancedSection(
                      title: 'Task Details',
                      icon: Icons.info_outline,
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Due Date',
                            value: _formatDateTime(task.dueDate),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.schedule_outlined,
                            label: 'Planned Time',
                            value: (task.plannedStartAt != null &&
                                    task.plannedEndAt != null)
                                ? '${DateFormat('h:mm a').format(task.plannedStartAt!.toLocal())} - ${DateFormat('h:mm a').format(task.plannedEndAt!.toLocal())}'
                                : 'Not set',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.photo_camera_outlined,
                            label: 'Photo Required',
                            value: task.requiresPhoto ? 'Yes' : 'No',
                            valueColor: task.requiresPhoto
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                          if (task.rejectionReason != null &&
                              task.rejectionReason!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.feedback_outlined,
                              label: 'Rejection Reason',
                              value: task.rejectionReason!,
                              valueColor: AppTheme.error,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Photos section
                    if (showPhotos) ...[
                      const SizedBox(height: 20),
                      _buildEnhancedSection(
                        title: 'Submitted Photos',
                        icon: Icons.photo_library_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: photoUrls.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final url = photoUrls[index];
                                  return GestureDetector(
                                    onTap: () => _openImage(context, url),
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.zoom_in,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to view full size',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    if (task.status == TaskStatus.verificationPending) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.04)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.rule,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Verification Required',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    height: 50,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.error,
                                          AppTheme.error.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              AppTheme.error.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _reject(task),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isSubmitting
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Rejecting...',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.close, size: 16),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Reject',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    height: 50,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.success,
                                          AppTheme.success.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              AppTheme.success.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _approve(task),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isSubmitting
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Approving...',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check, size: 16),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Approve',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
