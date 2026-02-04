import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restro/data/datasources/remote/firebase_storage_service.dart';
import 'package:restro/data/repositories/auth_repository.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart'; // Assuming provider is used for AuthenticationProvider? Or is it Get.find?
// If the app uses Provider for AuthenticationProvider, we can't easily Get.find it unless it's also registered in Get.
// However, we can use FirebaseAuth directly for the UID which is reliable.

class SelfieVerificationController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  final Rx<File?> selfieImage = Rx<File?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final ImagePicker _picker = ImagePicker();

  Future<void> captureSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (image != null) {
        selfieImage.value = File(image.path);
        errorMessage.value = '';
      }
    } catch (e) {
      errorMessage.value = 'Failed to capture image: ${e.toString()}';
    }
  }

  Future<bool> verifySelfie() async {
    if (selfieImage.value == null) {
      errorMessage.value = 'Please take a selfie first';
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final dateStr = DateTime.now().toIso8601String().split('T')[0];

      // 1. Upload Image
      final imageUrl = await _storageService.uploadAttendanceSelfie(
        user.uid,
        dateStr, // Using date as filename prefix or part of path
        selfieImage.value!,
      );

      // 2. Update User Verification in Firestore
      await _authRepository.updateUserVerification(user.uid);

      // 3. Update Local Session
      try {
        if (Get.isRegistered<AuthenticationProvider>()) {
          Get.find<AuthenticationProvider>().updateVerificationStatus(true);
        } else if (Get.context != null) {
           Provider.of<AuthenticationProvider>(Get.context!, listen: false).updateVerificationStatus(true);
        }
      } catch (e) {
         // Fallback or log error
         print("Error updating local session: $e");
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Verification failed: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
