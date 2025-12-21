import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:restro/data/models/user_model.dart';
import 'package:restro/data/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationProvider extends ChangeNotifier {
  final AuthRepository repository;

  AuthenticationProvider(this.repository);

  AppUserModel? currentUser;
  bool isLoading = false;

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
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      setLoading(true);

      final userEntity = await repository.registerUser(
        email: email,
        name: name,
        password: password,
        role: role,
        phone: phone,
      );

      currentUser = AppUserModel(
        id: userEntity.id,
        email: userEntity.email,
        role: userEntity.role,
        name: userEntity.name,
        phone: userEntity.phone,
        lastSynced: userEntity.lastSynced,
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
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);

      final userEntity = await repository.login(
        email: email,
        password: password,
      );

      currentUser = AppUserModel(
        id: userEntity.id,
        email: userEntity.email,
        role: userEntity.role,
        name: userEntity.name,
        phone: userEntity.phone,
        lastSynced: userEntity.lastSynced,
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
  //  LOGOUT
  // ----------------------------------------------------------
  Future<void> logout() async {
    await repository.logout();
    currentUser = null;
    await clearSession();
    notifyListeners();
  }
}