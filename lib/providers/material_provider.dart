import 'package:flutter/foundation.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';

class MaterialProvider extends ChangeNotifier {
  List<MaterialItem> _materials = [];
  bool _isLoading = false;
  String? _error;

  List<MaterialItem> get materials => _materials;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMaterials() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getMaterials();
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _materials = list.map((e) => MaterialItem.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load materials';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMaterial(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createMaterial(data);
      if (response['success'] == true) {
        await loadMaterials();
        return true;
      }
      _error = response['error'] ?? 'Failed to create material';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMaterial(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateMaterial(id, data);
      if (response['success'] == true) {
        await loadMaterials();
        return true;
      }
      _error = response['error'] ?? 'Failed to update material';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMaterial(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteMaterial(id);
      if (response['success'] == true) {
        _materials.removeWhere((m) => m.id == id);
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to delete material';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
