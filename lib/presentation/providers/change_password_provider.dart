import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> updatePassword({
    required String currentPwd,
    required String newPwd,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = "User not logged in";
        return false;
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        _errorMessage =
            'Email not available for this account. Please log out and log in again.';
        return false;
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPwd,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPwd);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          _errorMessage = "Current password is incorrect";
          break;
        case 'weak-password':
          _errorMessage = "New password is too weak";
          break;
        case 'requires-recent-login':
          _errorMessage = "Please log out and log in again to change password";
          break;
        default:
          _errorMessage = e.message ?? "Failed to update password";
      }
      return false;
    } catch (e) {
      _errorMessage = "An error occurred: ${e.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
