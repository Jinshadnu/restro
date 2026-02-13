import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SelfieVerificationSettingsService {
  final FirebaseFirestore _firestore;

  static bool? _cachedEnabled;
  static DateTime? _cachedAt;
  static const Duration _cacheTtl = Duration(seconds: 30);

  SelfieVerificationSettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  bool _parseEnabled(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    if (v is num) {
      if (v == 1) return true;
      if (v == 0) return false;
    }
    return true;
  }

  Future<bool> getEnabled({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedAt = _cachedAt;
      final cachedEnabled = _cachedEnabled;
      if (cachedAt != null && cachedEnabled != null) {
        final age = DateTime.now().difference(cachedAt);
        if (age <= _cacheTtl) return cachedEnabled;
      }
    }

    final doc = await _firestore.collection('settings').doc('app').get();
    final data = doc.data();
    final v = data == null ? null : data['selfieVerificationEnabled'];

    final enabled = _parseEnabled(v);
    debugPrint(
        'SelfieVerificationSettingsService.getEnabled: value=$v type=${v.runtimeType} -> enabled=$enabled');
    _cachedEnabled = enabled;
    _cachedAt = DateTime.now();
    return enabled;
  }

  Stream<bool> streamEnabled() {
    return _firestore.collection('settings').doc('app').snapshots().map((doc) {
      final data = doc.data();
      final v = data == null ? null : data['selfieVerificationEnabled'];
      final enabled = _parseEnabled(v);
      _cachedEnabled = enabled;
      _cachedAt = DateTime.now();
      return enabled;
    });
  }

  Future<void> setEnabled(bool enabled) async {
    await _firestore
        .collection('settings')
        .doc('app')
        .set({'selfieVerificationEnabled': enabled}, SetOptions(merge: true));

    _cachedEnabled = enabled;
    _cachedAt = DateTime.now();
  }
}
