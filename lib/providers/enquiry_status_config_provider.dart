import 'package:flutter/foundation.dart';
import '../models/enquiry_status_config_model.dart';
import '../services/api_service.dart';

class EnquiryStatusConfigProvider extends ChangeNotifier {
  List<EnquiryStatusConfig> _configs = [];
  bool _isLoading = false;
  String? _error;

  List<EnquiryStatusConfig> get configs => _configs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConfigs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getStatusConfigs();
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _configs = list.map((e) => EnquiryStatusConfig.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load status configs';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createConfig(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createStatusConfig(data);
      if (response['success'] == true) {
        await loadConfigs();
        return true;
      }
      _error = response['error'] ?? 'Failed to create config';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateConfig(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateStatusConfig(id, data);
      if (response['success'] == true) {
        await loadConfigs();
        return true;
      }
      _error = response['error'] ?? 'Failed to update config';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteConfig(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteStatusConfig(id);
      if (response['success'] == true) {
        _configs.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to delete config';
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
