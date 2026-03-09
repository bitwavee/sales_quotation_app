import 'package:flutter/foundation.dart';
import '../models/enquiry_progress_model.dart';
import '../models/enquiry_status_config_model.dart';
import '../services/api_service.dart';

class EnquiryProgressProvider extends ChangeNotifier {
  List<EnquiryProgress> _progressList = [];
  List<EnquiryStatusConfig> _statusConfigs = [];
  bool _isLoading = false;
  String? _error;

  List<EnquiryProgress> get progressList => _progressList;
  List<EnquiryStatusConfig> get statusConfigs => _statusConfigs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProgress(String enquiryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getEnquiryProgress(enquiryId);
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _progressList = list.map((e) => EnquiryProgress.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load progress';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStatusConfigs() async {
    try {
      final response = await ApiService.getStatusConfigs();
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _statusConfigs = list.map((e) => EnquiryStatusConfig.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load status configs error: $e');
    }
  }

  Future<bool> addProgress(String enquiryId, String status, String? notes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.addEnquiryProgress(enquiryId, {
        'status': status,
        'notes': notes,
      });
      if (response['success'] == true) {
        await loadProgress(enquiryId);
        return true;
      }
      _error = response['error'] ?? 'Failed to add progress';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String enquiryId, String status, String? notes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateEnquiryStatus(enquiryId, status, notes);
      if (response['success'] == true) {
        await loadProgress(enquiryId);
        return true;
      }
      _error = response['error'] ?? 'Failed to update status';
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
