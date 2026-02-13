import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/data/datasources/remote/firebase_storage_service.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/widgets/voice_note_recorder.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:intl/intl.dart';

class AttendanceVerificationScreen extends StatefulWidget {
  final String? attendanceId;

  const AttendanceVerificationScreen({
    super.key,
    this.attendanceId,
  });

  @override
  State<AttendanceVerificationScreen> createState() =>
      _AttendanceVerificationScreenState();
}

class _AttendanceVerificationScreenState
    extends State<AttendanceVerificationScreen> {
  bool _openedFromDeepLink = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context);
    final firestoreService = FirestoreService();

    final role = (auth.currentUser?.role ?? '').toString().toLowerCase();
    final isPrivileged =
        role == 'admin' || role == 'owner' || role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Attendance Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium header card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.fact_check,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Verifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Review and verify staff attendance submissions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: auth.currentUser != null && isPrivileged
                    ? firestoreService
                        .getPendingAttendances(auth.currentUser!.id)
                    : Stream.value([]),
                builder: (context, snapshot) {
                  if (!isPrivileged) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'You do not have permission to verify attendances.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final attendances = snapshot.data ?? [];

                  final targetId = (widget.attendanceId ?? '').trim();
                  if (!_openedFromDeepLink && targetId.isNotEmpty) {
                    final match = attendances
                        .where((a) => (a['id'] ?? '').toString() == targetId);
                    if (match.isNotEmpty) {
                      _openedFromDeepLink = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AttendanceDetailScreen(
                              attendance: match.first,
                            ),
                          ),
                        );
                      });
                    }
                  }

                  if (attendances.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.04)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pending attendances',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All attendance submissions have been verified',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: attendances.length,
                    itemBuilder: (context, index) {
                      final attendance = attendances[index];
                      return _EnhancedAttendanceCard(
                        attendance: attendance,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AttendanceDetailScreen(
                                attendance: attendance,
                              ),
                            ),
                          );
                        },
                        onApprove: () => _handleVerification(
                          context,
                          attendance['id'],
                          true,
                        ),
                        onReject: () => _showRejectDialog(
                          context,
                          attendance['id'],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerification(
    BuildContext context,
    String attendanceId,
    bool approved, {
    String? rejectionReason,
    File? rejectionVoiceNote,
  }) async {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final firestoreService = FirestoreService();
    final storageService = FirebaseStorageService();

    try {
      String? voiceUrl;
      if (!approved && rejectionVoiceNote != null) {
        voiceUrl = await storageService.uploadAttendanceRejectionVoiceNote(
          attendanceId,
          rejectionVoiceNote,
        );
      }
      await firestoreService.verifyAttendance(
        attendanceId,
        approved,
        verifiedBy: auth.currentUser?.id,
        rejectionReason: rejectionReason,
        rejectionVoiceNoteUrl: voiceUrl,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved
                  ? 'Attendance verified successfully'
                  : 'Attendance rejected',
            ),
            backgroundColor: approved ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, String attendanceId) {
    final reasonController = TextEditingController();
    File? voiceNote;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text('Reject Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for rejection:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Rejection reason...',
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
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reasonController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    _handleVerification(
                      context,
                      attendanceId,
                      false,
                      rejectionReason: reasonController.text.trim(),
                      rejectionVoiceNote: voiceNote,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _AttendanceStampType { approved, rejected }

class AttendanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> attendance;

  const AttendanceDetailScreen({
    super.key,
    required this.attendance,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _markMode = false;
  bool _drawMode = false;
  _AttendanceStampType _stampType = _AttendanceStampType.approved;
  Offset? _stampNormalized;
  final List<Offset?> _drawPointsNormalized = <Offset?>[];
  bool _isSubmitting = false;

  late final String _attendanceId;
  late final String _userId;
  late final String? _imageUrl;
  Future<String?>? _staffNameFuture;

  @override
  void initState() {
    super.initState();
    _attendanceId = (widget.attendance['id'] ?? '').toString();
    _userId =
        ((widget.attendance['userId'] ?? widget.attendance['staff_id']) ?? '')
            .toString();
    _imageUrl = ((widget.attendance['imageUrl'] ??
                widget.attendance['image_url'] ??
                widget.attendance['photoUrl'] ??
                widget.attendance['photo_url']) ??
            '')
        .toString();

    if (_userId.isNotEmpty) {
      _staffNameFuture = _firestoreService.getUserById(_userId).then((data) {
        final name = (data?['name'] ?? '').toString().trim();
        return name.isNotEmpty ? name : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final firestoreService = _firestoreService;

    final attendanceId = _attendanceId;
    final userId = _userId;
    final imageUrl = _imageUrl;

    return Scaffold(
      backgroundColor: AppTheme.backGroundColor,
      appBar: AppBar(
        title: const Text('Attendance Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  if (_staffNameFuture == null)
                    Text(
                      userId.isNotEmpty ? 'Staff: $userId' : 'Staff',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    )
                  else
                    FutureBuilder<String?>(
                      future: _staffNameFuture,
                      builder: (context, snapshot) {
                        final name = snapshot.data;
                        final label = (name != null && name.trim().isNotEmpty)
                            ? 'Staff: $name'
                            : (userId.isNotEmpty ? 'Staff: $userId' : 'Staff');
                        return Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  _buildImageArea(imageUrl),
                  const SizedBox(height: 12),
                  _buildMarkControls(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _showRejectDialog(
                              context,
                              firestoreService,
                              auth.currentUser?.id,
                              attendanceId,
                            ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _approve(
                              firestoreService,
                              auth.currentUser?.id,
                              attendanceId,
                            ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 360,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No selfie image',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    if (imageUrl.startsWith('gs://')) {
      return Container(
        height: 360,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Invalid image URL',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = 360.0;

        final image = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image),
                    const SizedBox(height: 8),
                    const Text(
                      'Failed to load selfie',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      imageUrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        Widget buildContent() {
          if (_markMode) {
            return GestureDetector(
              onTapDown: (details) {
                final dx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                final dy = (details.localPosition.dy / h).clamp(0.0, 1.0);
                setState(() {
                  _stampNormalized = Offset(dx, dy);
                });
              },
              child: image,
            );
          }

          if (_drawMode) {
            return GestureDetector(
              onPanStart: (details) {
                final dx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                final dy = (details.localPosition.dy / h).clamp(0.0, 1.0);
                setState(() {
                  _drawPointsNormalized.add(Offset(dx, dy));
                });
              },
              onPanUpdate: (details) {
                final dx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                final dy = (details.localPosition.dy / h).clamp(0.0, 1.0);
                setState(() {
                  _drawPointsNormalized.add(Offset(dx, dy));
                });
              },
              onPanEnd: (_) {
                setState(() {
                  _drawPointsNormalized.add(null);
                });
              },
              child: image,
            );
          }

          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: image,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildContent(),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _AttendanceDrawPainter(
                      pointsNormalized: _drawPointsNormalized,
                      width: w,
                      height: h,
                    ),
                  ),
                ),
                if (_stampNormalized != null)
                  Positioned(
                    left: (_stampNormalized!.dx * w) - 44,
                    top: (_stampNormalized!.dy * h) - 44,
                    child: _StampBadge(type: _stampType),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarkControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _markMode = !_markMode;
                    if (_markMode) _drawMode = false;
                  });
                },
                icon: Icon(_markMode ? Icons.close : Icons.edit),
                label: Text(_markMode ? 'Exit Mark' : 'Mark'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _drawMode = !_drawMode;
                    if (_drawMode) _markMode = false;
                  });
                },
                icon: Icon(_drawMode ? Icons.close : Icons.brush),
                label: Text(_drawMode ? 'Exit Draw' : 'Draw'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () => _showPreviewDialog(_imageUrl),
              icon: const Icon(Icons.fullscreen),
              color: AppTheme.textSecondary,
              tooltip: 'Preview',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ToggleButtons(
              isSelected: [
                _stampType == _AttendanceStampType.approved,
                _stampType == _AttendanceStampType.rejected,
              ],
              onPressed: (index) {
                setState(() {
                  _stampType = index == 0
                      ? _AttendanceStampType.approved
                      : _AttendanceStampType.rejected;
                });
              },
              borderRadius: BorderRadius.circular(12),
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              selectedBorderColor: AppTheme.primaryColor,
              borderColor: Colors.black.withOpacity(0.12),
              fillColor: AppTheme.primaryColor.withOpacity(0.08),
              selectedColor: AppTheme.primaryColor,
              color: AppTheme.textSecondary,
              children: const [
                Tooltip(message: 'Approved stamp', child: Icon(Icons.check)),
                Tooltip(message: 'Rejected stamp', child: Icon(Icons.close)),
              ],
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _stampNormalized == null
                  ? null
                  : () {
                      setState(() {
                        _stampNormalized = null;
                      });
                    },
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.textSecondary,
              tooltip: 'Clear mark',
            ),
            const Spacer(),
            IconButton(
              onPressed: _drawPointsNormalized.isEmpty
                  ? null
                  : () {
                      setState(() {
                        while (_drawPointsNormalized.isNotEmpty) {
                          final last = _drawPointsNormalized.removeLast();
                          if (last == null) {
                            break;
                          }
                        }
                      });
                    },
              icon: const Icon(Icons.undo),
              color: AppTheme.textSecondary,
              tooltip: 'Undo draw',
            ),
            IconButton(
              onPressed: _drawPointsNormalized.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _drawPointsNormalized.clear();
                      });
                    },
              icon: const Icon(Icons.layers_clear),
              color: AppTheme.textSecondary,
              tooltip: 'Clear draw',
            ),
          ],
        ),
      ],
    );
  }

  void _showPreviewDialog(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    InteractiveViewer(
                      minScale: 1,
                      maxScale: 6,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _AttendanceDrawPainter(
                                pointsNormalized: _drawPointsNormalized,
                                width: w,
                                height: h,
                              ),
                            ),
                          ),
                          if (_stampNormalized != null)
                            Positioned(
                              left: (_stampNormalized!.dx * w) - 44,
                              top: (_stampNormalized!.dy * h) - 44,
                              child: _StampBadge(type: _stampType),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _approve(
    FirestoreService firestoreService,
    String? verifiedBy,
    String attendanceId,
  ) async {
    if (attendanceId.isEmpty) return;
    setState(() {
      _stampType = _AttendanceStampType.approved;
    });
    setState(() => _isSubmitting = true);
    try {
      await firestoreService.verifyAttendance(
        attendanceId,
        true,
        verifiedBy: verifiedBy,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance approved'),
          backgroundColor: AppTheme.success,
        ),
      );
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

  void _showRejectDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String? verifiedBy,
    String attendanceId,
  ) {
    setState(() {
      _stampType = _AttendanceStampType.rejected;
    });
    final reasonController = TextEditingController();
    File? voiceNote;
    bool isRecording = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          final maxH = MediaQuery.of(context).size.height * 0.70;
          return AlertDialog(
            title: const Text('Reject Attendance'),
            content: Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom > 0 ? 8 : 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Please provide a reason for rejection:'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          hintText: 'Rejection reason...',
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
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: (_isSubmitting || isRecording)
                        ? null
                        : () async {
                            if (reasonController.text.trim().isEmpty) return;
                            Navigator.pop(context);
                            setState(() => _isSubmitting = true);
                            try {
                              final storageService = FirebaseStorageService();
                              String? voiceUrl;
                              if (voiceNote != null) {
                                voiceUrl = await storageService
                                    .uploadAttendanceRejectionVoiceNote(
                                  attendanceId,
                                  voiceNote!,
                                );
                              }
                              await firestoreService.verifyAttendance(
                                attendanceId,
                                false,
                                verifiedBy: verifiedBy,
                                rejectionReason: reasonController.text.trim(),
                                rejectionVoiceNoteUrl: voiceUrl,
                              );
                              if (!mounted) return;
                              Navigator.pop(this.context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attendance rejected'),
                                  backgroundColor: AppTheme.warning,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceDrawPainter extends CustomPainter {
  final List<Offset?> pointsNormalized;
  final double width;
  final double height;

  _AttendanceDrawPainter({
    required this.pointsNormalized,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < pointsNormalized.length - 1; i++) {
      final p1 = pointsNormalized[i];
      final p2 = pointsNormalized[i + 1];
      if (p1 == null || p2 == null) continue;
      canvas.drawLine(
        Offset(p1.dx * width, p1.dy * height),
        Offset(p2.dx * width, p2.dy * height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AttendanceDrawPainter oldDelegate) {
    return oldDelegate.pointsNormalized != pointsNormalized ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
  }
}

class _StampBadge extends StatelessWidget {
  final _AttendanceStampType type;

  const _StampBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isApproved = type == _AttendanceStampType.approved;
    final color = isApproved ? AppTheme.success : AppTheme.error;
    final label = isApproved ? 'APPROVED' : 'REJECTED';
    return Transform.rotate(
      angle: -0.25,
      child: Container(
        width: 88,
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 4),
          color: Colors.white.withOpacity(0.65),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AttendanceCard({
    required this.attendance,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final date = _parseDateTime(attendance['date']);
    final timestamp = _parseDateTime(attendance['timestamp']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ID: ${attendance['userId']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateFormat('MMM d, y').format(date)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        if (timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Time: ${DateFormat('h:mm a').format(timestamp)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (attendance['imageUrl'] != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    attendance['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //            Enhanced Attendance Card UI Widget
  // ===========================================================
  Widget _enhancedAttendanceCard({
    required Map<String, dynamic> attendance,
    required VoidCallback onTap,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    final date = _parseDateTime(attendance['date']);
    final timestamp = _parseDateTime(attendance['timestamp']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user info and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User ID: ${attendance['userId']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (date != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${DateFormat('MMM d, y').format(date)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (timestamp != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Time: ${DateFormat('h:mm a').format(timestamp)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Image preview
                if (attendance['imageUrl'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        attendance['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //            Legacy Attendance Card (keep for compatibility)
  // ===========================================================
  Widget _legacyAttendanceCard({
    required Map<String, dynamic> attendance,
    required VoidCallback onTap,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    final date = _parseDateTime(attendance['date']);
    final timestamp = _parseDateTime(attendance['timestamp']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ID: ${attendance['userId']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateFormat('MMM d, y').format(date)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        if (timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Time: ${DateFormat('h:mm a').format(timestamp)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (attendance['imageUrl'] != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    attendance['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final tsType = value.runtimeType.toString();
    if (tsType == 'Timestamp' || tsType.endsWith('Timestamp')) {
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class _EnhancedAttendanceCard extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _EnhancedAttendanceCard({
    required this.attendance,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final date = _parseDateTime(attendance['date']);
    final timestamp = _parseDateTime(attendance['timestamp']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User ID: ${attendance['userId']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (date != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${DateFormat('MMM d, y').format(date)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (timestamp != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Time: ${DateFormat('h:mm a').format(timestamp)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (attendance['imageUrl'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        attendance['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final tsType = value.runtimeType.toString();
    if (tsType == 'Timestamp' || tsType.endsWith('Timestamp')) {
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
