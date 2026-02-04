import 'package:flutter/material.dart';
import 'package:restro/utils/location_service.dart';

class LocationProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isWithinShopPerimeter = false;
  String? _errorMessage;
  String _shopAddress = 'Loading shop location...';

  bool get isLoading => _isLoading;
  bool get isWithinShopPerimeter => _isWithinShopPerimeter;
  String? get errorMessage => _errorMessage;
  String get shopAddress => _shopAddress;

  LocationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await checkLocation();
    _shopAddress = await LocationService.getShopAddress();
    notifyListeners();
  }

  Future<void> checkLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isWithinShopPerimeter = await LocationService.isWithinShopPerimeter();
      if (!_isWithinShopPerimeter) {
        _errorMessage = 'You are not at the shop';
      }
    } catch (e) {
      _errorMessage = 'Error verifying location: ${e.toString()}';
      _isWithinShopPerimeter = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to verify location before performing actions
  Future<bool> verifyLocation() async {
    try {
      return await LocationService.isWithinShopPerimeter();
    } catch (e) {
      return false;
    }
  }
}
