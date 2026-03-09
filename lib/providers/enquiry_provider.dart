import 'package:flutter/foundation.dart';
import '../models/enquiry_model.dart';
import '../services/api_service.dart';

class EnquiryProvider extends ChangeNotifier {
  List<Enquiry> _enquiries = [];
  Enquiry? _selectedEnquiry;
  bool _isLoading = false;
  String? _error;

  List<Enquiry> get enquiries => _enquiries;
  Enquiry? get selectedEnquiry => _selectedEnquiry;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEnquiries({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getEnquiries(status: status);
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _enquiries = list.map((e) => Enquiry.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load enquiries';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      debugPrint('Load enquiries error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEnquiryDetails(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getEnquiryDetails(id);
      if (response['success'] == true && response['data'] != null) {
        _selectedEnquiry = Enquiry.fromJson(response['data']);
      } else {
        _error = response['error'] ?? 'Failed to load enquiry details';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEnquiry(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createEnquiry(data);
      if (response['success'] == true) {
        await loadEnquiries();
        return true;
      }
      _error = response['error'] ?? 'Failed to create enquiry';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEnquiry(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateEnquiry(id, data);
      if (response['success'] == true) {
        await loadEnquiries();
        return true;
      }
      _error = response['error'] ?? 'Failed to update enquiry';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEnquiry(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteEnquiry(id);
      if (response['success'] == true) {
        _enquiries.removeWhere((e) => e.id == id);
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to delete enquiry';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedEnquiry = null;
    notifyListeners();
  }
}
