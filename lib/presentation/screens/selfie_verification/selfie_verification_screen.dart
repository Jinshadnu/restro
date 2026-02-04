import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SelfieVerificationScreen extends StatefulWidget {
  final Function(String) onVerificationComplete;

  const SelfieVerificationScreen({
    super.key,
    required this.onVerificationComplete,
  });

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  String? _imagePath;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleLifecycleChange(state);
  }

  Future<void> _handleLifecycleChange(AppLifecycleState state) async {
    if (_isDisposing) return;

    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await _disposeCameraController();
      return;
    }

    if (state == AppLifecycleState.resumed &&
        mounted &&
        !_isCameraInitialized) {
      await _initializeCamera();
    }
  }

  // ---------------- CAMERA INIT ----------------
  Future<void> _initializeCamera() async {
    try {
      final hasPermission =
          await SelfieVerificationHelper.checkCameraPermission();

      if (!hasPermission) {
        _showSnackBar('Camera permission denied');
        return;
      }

      await _disposeCameraController();

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
      _showSnackBar('Failed to initialize camera');
    }
  }

  Future<void> _disposeCameraController() async {
    final controller = _controller;
    if (controller == null) return;

    _controller = null;
    try {
      await controller.dispose();
    } catch (_) {
      // Ignore dispose errors
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  // ---------------- TAKE PICTURE ----------------
  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) return;
      if (controller.value.isTakingPicture) return;

      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/selfies';
      await Directory(dirPath).create(recursive: true);

      final filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile picture = await controller.takePicture();
      await File(picture.path).copy(filePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'last_verification_date', DateTime.now().toIso8601String());
      await prefs.setString('last_verification_path', filePath);

      if (!mounted) return;

      setState(() => _imagePath = filePath);

      widget.onVerificationComplete(filePath);
    } catch (e) {
      debugPrint('Take picture error: $e');
      _showSnackBar('Failed to take picture');
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  // ---------------- SNACKBAR SAFE ----------------
  void _showSnackBar(String message) {
    // scaffoldMessengerKey.currentState?.showSnackBar(
    //   SnackBar(content: Text(message)),
    // );
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Selfie Verification'),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    final controller = _controller;
    if (!_isCameraInitialized ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imagePath != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verification Complete!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(controller),
        ),
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black54,
            child: const Text(
              'Please take a selfie for daily verification',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildFab() {
    if (_imagePath != null) return null;

    return FloatingActionButton(
      onPressed: _isTakingPicture ? null : _takePicture,
      child: _isTakingPicture
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.camera_alt),
    );
  }
}

// ---------------- HELPER ----------------
class SelfieVerificationHelper {
  static Future<bool> isVerificationRequired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVerification = prefs.getString('last_verification_date');

    if (lastVerification == null) return true;

    final lastDate = DateTime.parse(lastVerification);
    final now = DateTime.now();

    return lastDate.year != now.year ||
        lastDate.month != now.month ||
        lastDate.day != now.day;
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isDenied || status.isRestricted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    return status.isGranted;
  }
}
