import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  Map<String, dynamic> _managerDashboard = {};
  Map<String, dynamic> _ownerDashboard = {};

  bool get isLoading => _isLoading;
  Map<String, dynamic> get managerDashboard => _managerDashboard;
  Map<String, dynamic> get ownerDashboard => _ownerDashboard;
  FirestoreService get firestoreService => _firestoreService;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> loadManagerDashboard(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _firestoreService.getManagerDashboard(userId);
      _managerDashboard = data;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOwnerDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _firestoreService.getOwnerDashboard();
      _ownerDashboard = data;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
