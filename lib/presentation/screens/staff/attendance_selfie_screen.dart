import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/data/datasources/remote/firebase_storage_service.dart';
import 'package:restro/data/datasources/local/database_helper.dart';
import 'package:restro/data/models/attendance_model.dart';
import 'package:restro/domain/entities/attendance.dart';
import 'package:restro/utils/location_service.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/theme/theme.dart';
import 'package:intl/intl.dart';

class AttendanceSelfieScreen extends StatefulWidget {
  const AttendanceSelfieScreen({super.key});

  @override
  State<AttendanceSelfieScreen> createState() => _AttendanceSelfieScreenState();
}

class _AttendanceSelfieScreenState extends State<AttendanceSelfieScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  File? _capturedImage;
  bool _isUploading = false;
  String? _statusText;

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.staffDashboard);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      if (now.hour < 14) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Attendance selfie can be submitted only after 2:00 PM'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.staffDashboard);
        return;
      }
      _checkExistingAndSync();
    });
  }

  Future<void> _checkExistingAndSync() async {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(today);
    final attendanceId = '${userId}_$dateStr';

    try {
      final todayAttendance =
          await _firestoreService.getTodayAttendance(userId);

      if (!mounted) return;

      if (todayAttendance.docs.isNotEmpty) {
        final data = todayAttendance.docs.first.data() as Map<String, dynamic>;
        final status = (data['verification_status'] ?? data['status'] ?? '')
            .toString()
            .toLowerCase();

        if (status == 'approved' || status == 'verified') {
          Navigator.of(context).pushReplacementNamed(AppRoutes.staffDashboard);
          return;
        }

        if (status == 'pending') {
          setState(() {
            _statusText = 'Attendance already submitted. Waiting for approval.';
          });
          return;
        }
      }
    } catch (_) {
      final local = await _dbHelper.getAttendanceById(attendanceId);
      if (!mounted) return;

      if (local != null) {
        setState(() {
          _statusText = 'Selfie saved offline. Waiting to sync.';
        });
        await _trySyncOfflineAttendance(attendanceId);
        return;
      }
    }

    await _openFrontCamera();
  }

  Future<void> _trySyncOfflineAttendance(String attendanceId) async {
    final local = await _dbHelper.getAttendanceById(attendanceId);
    if (local == null) return;

    final localImagePath =
        (local['local_image_path'] ?? local['imagePath'])?.toString();
    String? imageUrl = (local['imageUrl'] ?? local['image_url'])?.toString();

    try {
      if ((imageUrl == null || imageUrl.isEmpty) &&
          localImagePath != null &&
          localImagePath.isNotEmpty) {
        final userId = (local['userId'] ?? local['staff_id'] ?? '').toString();
        final dateStr = (local['dateStr'] ?? '').toString();
        if (userId.isNotEmpty && dateStr.isNotEmpty) {
          imageUrl = await _storageService.uploadAttendanceSelfie(
            userId,
            dateStr,
            File(localImagePath),
          );
        }
      }

      final data = Map<String, dynamic>.from(local);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        data['imageUrl'] = imageUrl;
      }
      data['sync_status'] = 'synced';
      data['synced'] = true;

      await _firestoreService.syncAttendance(data);
      await _dbHelper.markAttendanceSynced(attendanceId, imageUrl: imageUrl);

      if (!mounted) return;
      setState(() {
        _statusText = 'Attendance submitted. Waiting for approval.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Selfie saved offline. Waiting to sync.';
      });
    }
  }

  Future<void> _openFrontCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to mark attendance'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImage = File(photo.path);
        });
      } else if (mounted) {
        // User cancelled - show message but allow them to retry
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please take a selfie to mark attendance'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your selfie first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthenticationProvider>(context, listen: false);
    if (auth.currentUser == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userId = auth.currentUser!.id;
      final now = DateTime.now();
      final bypass = await LocationService.isTestingGeofenceBypassEnabled();
      if (!bypass && now.hour < 14) {
        throw Exception(
            'Attendance selfie can be submitted only after 2:00 PM');
      }

      final today = DateTime(now.year, now.month, now.day);
      final dateStr = DateFormat('yyyy-MM-dd').format(today);

      // One attendance per day per staff
      final attendanceId = '${userId}_$dateStr';

      // Geofence enforcement (50m)
      final inside = await LocationService.isWithinShopPerimeter();
      if (!inside) {
        throw Exception(
            'You must be within 50 meters of the shop to submit attendance');
      }

      // Prevent resubmission if already pending/approved today
      final existing = await _firestoreService.getTodayAttendance(userId);
      if (existing.docs.isNotEmpty) {
        final data = existing.docs.first.data() as Map<String, dynamic>;
        final status = (data['verification_status'] ?? data['status'] ?? '')
            .toString()
            .toLowerCase();
        final isFinalOrPending =
            status == 'pending' || status == 'approved' || status == 'verified';
        if (isFinalOrPending) {
          throw Exception(
              'Attendance already submitted for today. Please wait for approval.');
        }
      }

      String? imageUrl;
      String syncStatus = 'synced';
      bool synced = true;

      // Upload image to Firebase Storage (if it fails, keep offline and sync later)
      try {
        imageUrl = await _storageService.uploadAttendanceSelfie(
          userId,
          dateStr,
          _capturedImage!,
        );
      } catch (_) {
        imageUrl = null;
        syncStatus = 'pending_upload';
        synced = false;
      }

      // Create attendance record
      final attendance = AttendanceModel(
        id: attendanceId,
        userId: userId,
        imageUrl: imageUrl,
        imagePath: _capturedImage!.path,
        date: today,
        timestamp: now,
        status: AttendanceStatus.pending,
        synced: synced,
      );

      final data = attendance.toJson();
      data['sync_status'] = syncStatus;
      data['verification_status'] = 'pending';
      data['dateStr'] = dateStr;
      data['capturedAt'] = now.toIso8601String();

      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        data['location'] = {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'accuracy': pos.accuracy,
        };
      }

      try {
        await _firestoreService.createAttendance(data);
      } catch (_) {
        data['sync_status'] = 'pending_firestore';
        data['synced'] = false;
        await _dbHelper.insertAttendance(data);
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _statusText = 'Selfie saved offline. Waiting to sync.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Saved offline. Will sync when internet is available.'),
            backgroundColor: Colors.green,
          ),
        );

        // Update local state in AuthProvider
        auth.setAttendanceMarked(true);

        // Navigate to dashboard after submission (even if saved offline)
        _goToDashboard();
        return;
      }

      await _dbHelper.insertAttendance(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imageUrl == null
                ? 'Selfie saved offline. Will sync when internet is available.'
                : 'Attendance submitted. Waiting for manager approval.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Update local state in AuthProvider
      auth.setAttendanceMarked(true);

      // Navigate to dashboard after submission
      setState(() {
        _isUploading = false;
        _statusText = 'Attendance submitted. Waiting for approval.';
      });
      _goToDashboard();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = MediaQuery.of(context).size.height * 0.45;
    return WillPopScope(
        onWillPop: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Selfie is required before accessing the dashboard.'),
            ),
          );
          return false;
        },
        child: Scaffold(
          backgroundColor: AppTheme.backGroundColor,
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text(
              'Attendance',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _isUploading ? null : _goToDashboard,
                tooltip: 'Close',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryColor.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daily Selfie Verification',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Capture a clear selfie to mark attendance',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.25),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Required',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_statusText != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _statusText!,
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Header
                        // Container(
                        //   width: double.infinity,
                        //   margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        //   padding: const EdgeInsets.all(20),
                        //   decoration: BoxDecoration(
                        //     gradient: LinearGradient(
                        //       colors: [
                        //         AppTheme.primaryColor,
                        //         AppTheme.primaryColor.withOpacity(0.85),
                        //       ],
                        //       begin: Alignment.topLeft,
                        //       end: Alignment.bottomRight,
                        //     ),
                        //     borderRadius: BorderRadius.circular(20),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: AppTheme.primaryColor.withOpacity(0.28),
                        //         blurRadius: 14,
                        //         offset: const Offset(0, 8),
                        //       ),
                        //     ],
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       Container(
                        //         padding: const EdgeInsets.all(12),
                        //         decoration: BoxDecoration(
                        //           color: Colors.white.withOpacity(0.18),
                        //           borderRadius: BorderRadius.circular(12),
                        //           border: Border.all(
                        //             color: Colors.white.withOpacity(0.18),
                        //           ),
                        //         ),
                        //         child: const Icon(
                        //           Icons.camera_alt,
                        //           color: Colors.white,
                        //           size: 26,
                        //         ),
                        //       ),
                        //       const SizedBox(width: 16),
                        //       const Expanded(
                        //         child: Column(
                        //           crossAxisAlignment: CrossAxisAlignment.start,
                        //           children: [
                        //             Text(
                        //               'Attendance Selfie',
                        //               style: TextStyle(
                        //                 color: Colors.white,
                        //                 fontSize: 20,
                        //                 fontWeight: FontWeight.w900,
                        //               ),
                        //             ),
                        //             SizedBox(height: 4),
                        //             Text(
                        //               'Submit your selfie for attendance verification',
                        //               style: TextStyle(
                        //                 color: Colors.white,
                        //                 fontSize: 14,
                        //                 fontWeight: FontWeight.w600,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //       IconButton(
                        //         onPressed: _isUploading ? null : _goToDashboard,
                        //         icon: const Icon(Icons.close,
                        //             color: Colors.white),
                        //         tooltip: 'Close',
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // Image Preview or Placeholder
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            width: double.infinity,
                            height: previewHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _capturedImage == null
                                  ? Container(
                                      color: Colors.grey.shade50,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.18),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.face,
                                              size: 46,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Ready when you are',
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Tap “Take Selfie” to capture your photo',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) {
                                            return Dialog(
                                              insetPadding:
                                                  const EdgeInsets.all(16),
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                    child: Container(
                                                      color: Colors.black,
                                                      child: InteractiveViewer(
                                                        child: Image.file(
                                                          _capturedImage!,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 10,
                                                    right: 10,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.5),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                        ),
                                                      ),
                                                      child: IconButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(
                                            _capturedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.25),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.45),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.25),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.zoom_out_map,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Tap to preview',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Action Buttons (pinned)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _openFrontCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _capturedImage == null
                                ? 'Take Selfie'
                                : 'Retake Selfie',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: (_isUploading || _capturedImage == null)
                              ? null
                              : _submitAttendance,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isUploading
                                ? 'Submitting...'
                                : 'Submit Attendance',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isUploading ? null : _checkExistingAndSync,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Status'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
