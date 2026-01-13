import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:restro/data/models/user_model.dart';
import 'package:restro/data/repositories/auth_repository.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationProvider extends ChangeNotifier {
  final AuthRepository repository;

  AuthenticationProvider(this.repository);

  AppUserModel? currentUser;
  bool isLoading = false;
  bool hasMarkedAttendanceToday = false;

  // ----------------------------------------------------------
  //  LOADING STATE
  // ----------------------------------------------------------
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // ----------------------------------------------------------
  //  SAVE SESSION
  // ----------------------------------------------------------
  Future<void> saveUserSession(AppUserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("user_session", jsonEncode(user.toMap()));
  }

  // ----------------------------------------------------------
  //  LOAD SESSION (SPLASH)
  // ----------------------------------------------------------
  Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("user_session");

    if (data == null) return false;

    currentUser = AppUserModel.fromMap(jsonDecode(data));
    notifyListeners();
    return true;
  }

  // ----------------------------------------------------------
  //  CLEAR SESSION
  // ----------------------------------------------------------
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user_session");
  }

  // ----------------------------------------------------------
  //  REGISTER USER
  // ----------------------------------------------------------
  // In lib/presentation/providers/auth_provider.dart

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    // Remove pin parameter
  }) async {
    try {
      setLoading(true);

      final userEntity = await repository.registerUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        // Remove pin parameter
      );

      currentUser = AppUserModel(
        id: userEntity.id,
        email: userEntity.email,
        role: userEntity.role,
        name: userEntity.name,
        phone: userEntity.phone,
        lastSynced: userEntity.lastSynced,
        isSelfieVerified: userEntity.isSelfieVerified,
        selfieVerifiedAt: userEntity.selfieVerifiedAt,
        // Remove pin field
      );

      await saveUserSession(currentUser!);

      setLoading(false);
      notifyListeners();
      return null;
    } catch (e) {
      setLoading(false);
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  //  LOGIN USER
  // ----------------------------------------------------------
  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    try {
      setLoading(true);

      final userEntity = await repository.login(
        identifier: identifier,
        password: password,
      );

      currentUser = AppUserModel(
        id: userEntity.id,
        email: userEntity.email,
        role: userEntity.role,
        name: userEntity.name,
        phone: userEntity.phone,
        lastSynced: userEntity.lastSynced,
        isSelfieVerified: userEntity.isSelfieVerified,
        selfieVerifiedAt: userEntity.selfieVerifiedAt,
      );

      await saveUserSession(currentUser!);

      setLoading(false);
      notifyListeners();
      return null;
    } catch (e) {
      setLoading(false);
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  //  LOGIN WITH PIN
  // ----------------------------------------------------------
  Future<String?> loginWithPin(String pin) async {
    try {
      setLoading(true);

      final userEntity = await repository.loginWithPin(pin);

      currentUser = AppUserModel(
          id: userEntity.id,
          email: userEntity.email,
          role: userEntity.role,
          name: userEntity.name,
          phone: userEntity.phone,
          lastSynced: userEntity.lastSynced,
          isSelfieVerified: userEntity.isSelfieVerified,
          selfieVerifiedAt: userEntity.selfieVerifiedAt);

      await saveUserSession(currentUser!);

      setLoading(false);
      notifyListeners();
      return null;
    } catch (e) {
      setLoading(false);
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  //  LOGOUT
  // ----------------------------------------------------------
  Future<void> logout() async {
    await repository.logout();
    currentUser = null;
    await clearSession();
    notifyListeners();
  }

  Future<void> updateVerificationStatus(bool verified) async {
    if (currentUser != null) {
      currentUser = AppUserModel(
        id: currentUser!.id,
        email: currentUser!.email,
        role: currentUser!.role,
        name: currentUser!.name,
        phone: currentUser!.phone,
        lastSynced: currentUser!.lastSynced,
        isSelfieVerified: verified,
        selfieVerifiedAt:
            verified ? DateTime.now().millisecondsSinceEpoch : null,
      );
      await saveUserSession(currentUser!);
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  //  ATTENDANCE CHECK
  // ----------------------------------------------------------
  Future<void> checkTodayAttendance() async {
    if (currentUser == null) return;

    try {
      final firestoreService = FirestoreService();
      final attendance =
          await firestoreService.getTodayAttendance(currentUser!.id);
      hasMarkedAttendanceToday = attendance.docs.isNotEmpty;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking attendance: $e');
    }
  }

  void setAttendanceMarked(bool value) {
    hasMarkedAttendanceToday = value;
    notifyListeners();
  }
}
