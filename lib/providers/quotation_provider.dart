import 'package:flutter/foundation.dart';
import '../models/quotation_model.dart';
import '../services/api_service.dart';

class QuotationProvider extends ChangeNotifier {
  List<Quotation> _quotations = [];
  Quotation? _selectedQuotation;
  bool _isLoading = false;
  String? _error;

  List<Quotation> get quotations => _quotations;
  Quotation? get selectedQuotation => _selectedQuotation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadQuotations(String enquiryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getQuotations(enquiryId);
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _quotations = list.map((e) => Quotation.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load quotations';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuotationDetails(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getQuotation(id);
      if (response['success'] == true && response['data'] != null) {
        _selectedQuotation = Quotation.fromJson(response['data']);
      } else {
        _error = response['error'] ?? 'Failed to load quotation';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuotation(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createQuotation(data);
      if (response['success'] == true) {
        return true;
      }
      _error = response['error'] ?? 'Failed to create quotation';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateQuotation(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateQuotation(id, data);
      if (response['success'] == true) {
        return true;
      }
      _error = response['error'] ?? 'Failed to update quotation';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteQuotation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteQuotation(id);
      if (response['success'] == true) {
        _quotations.removeWhere((q) => q.id == id);
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to delete quotation';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendQuotation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.sendQuotation(id);
      if (response['success'] == true) {
        return true;
      }
      _error = response['error'] ?? 'Failed to send quotation';
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
