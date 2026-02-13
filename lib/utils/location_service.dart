import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // Shop coordinates (replace with your shop's actual coordinates)
  static const double shopLatitude = 12.9716; // Example: Bangalore coordinates
  static const double shopLongitude = 77.5946;
  static const double maxDistanceMeters = 50.0; // 50 meters radius

  static const String _shopLatKey = 'shop_latitude';
  static const String _shopLngKey = 'shop_longitude';
  static const String _testingGeofenceBypassKey = 'testing_geofence_bypass';

  static Future<({double lat, double lng})> getShopLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_shopLatKey) ?? shopLatitude;
    final lng = prefs.getDouble(_shopLngKey) ?? shopLongitude;
    return (lat: lat, lng: lng);
  }

  static Future<void> setShopLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_shopLatKey, lat);
    await prefs.setDouble(_shopLngKey, lng);
  }

  static Future<bool> setShopLocationToCurrentLocation() async {
    final pos = await getCurrentPosition();
    if (pos == null) return false;
    await setShopLocation(pos.latitude, pos.longitude);
    return true;
  }

  // Check and request location permissions
  static Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current position
  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Calculate distance between two points in meters
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if current location is within shop perimeter
  static Future<bool> isWithinShopPerimeter() async {
    final prefs = await SharedPreferences.getInstance();
    final bypass = prefs.getBool(_testingGeofenceBypassKey) ?? false;
    if (bypass) return true;

    try {
      final position = await getCurrentPosition();
      if (position == null) return false;

      final shop = await getShopLocation();

      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        shop.lat,
        shop.lng,
      );

      return distance <= maxDistanceMeters;
    } catch (e) {
      print('Error checking shop perimeter: $e');
      return false;
    }
  }

  static Future<void> enableTestingGeofenceBypass(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testingGeofenceBypassKey, enable);
  }

  static Future<bool> isTestingGeofenceBypassEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testingGeofenceBypassKey) ?? false;
  }

  // Get shop address for display
  static Future<String> getShopAddress() async {
    try {
      final shop = await getShopLocation();
      final placemarks = await placemarkFromCoordinates(
        shop.lat,
        shop.lng,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}';
      }
      return 'Location: ${shop.lat.toStringAsFixed(6)}, ${shop.lng.toStringAsFixed(6)}';
    } catch (e) {
      final shop = await getShopLocation();
      return 'Location: ${shop.lat.toStringAsFixed(6)}, ${shop.lng.toStringAsFixed(6)}';
    }
  }
}
