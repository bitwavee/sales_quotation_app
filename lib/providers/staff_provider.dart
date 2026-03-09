import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class StaffProvider extends ChangeNotifier {
  List<User> _staffList = [];
  bool _isLoading = false;
  String? _error;

  List<User> get staffList => _staffList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getStaffList();
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _staffList = list.map((e) => User.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load staff';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStaff(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createStaff(data);
      if (response['success'] == true) {
        await loadStaff();
        return true;
      }
      _error = response['error'] ?? 'Failed to create staff';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateStaff(id, data);
      if (response['success'] == true) {
        await loadStaff();
        return true;
      }
      _error = response['error'] ?? 'Failed to update staff';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStaff(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteStaff(id);
      if (response['success'] == true) {
        _staffList.removeWhere((s) => s.id == id);
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to delete staff';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignEnquiry(String enquiryId, String staffId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.assignEnquiryToStaff(enquiryId, staffId);
      if (response['success'] == true) {
        return true;
      }
      _error = response['error'] ?? 'Failed to assign enquiry';
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
