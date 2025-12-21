import 'package:flutter/material.dart';

class AdminProfileProvider extends ChangeNotifier {
  String name = "John Admin";
  String email = "admin@restro.com";
  String role = "Owner / Administrator";

  bool isLoading = false;

  Future<void> updateProfile(String newName, String newEmail) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    name = newName;
    email = newEmail;

    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    // Clear token or Firebase sign-out
  }
}