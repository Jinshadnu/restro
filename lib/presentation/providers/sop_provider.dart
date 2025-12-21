import 'package:flutter/foundation.dart';
import 'package:restro/data/models/sop_model.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';

class SopProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  final List<SOPModel> _sops = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<SOPModel> get sops => _sops;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadSOPs() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _sops.clear();
      final sops = await _firestoreService.getSOPs();
      _sops.addAll(sops);

      // Debug: Print number of SOPs loaded
      if (kDebugMode) {
        print('SOPs loaded: ${_sops.length}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error loading SOPs: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSop(SOPModel sop) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _firestoreService.createSOP(sop);
      _sops.add(sop);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSop(String sopId, SOPModel sop) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _firestoreService.updateSOP(sopId, sop);
      final index = _sops.indexWhere((s) => s.id == sopId);
      if (index != -1) {
        _sops[index] = sop;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSop(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _firestoreService.deleteSOP(id);
      _sops.removeWhere((e) => e.id == id);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
