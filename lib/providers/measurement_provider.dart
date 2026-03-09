import 'package:flutter/foundation.dart';
import '../models/measurement_model.dart';
import '../services/api_service.dart';

class MeasurementProvider extends ChangeNotifier {
  List<Measurement> _measurements = [];
  bool _isLoading = false;
  String? _error;

  List<Measurement> get measurements => _measurements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMeasurements(String enquiryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getMeasurements(enquiryId);
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _measurements = list.map((e) => Measurement.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load measurements';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMeasurement(String enquiryId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createMeasurement(enquiryId, data);
      if (response['success'] == true) {
        await loadMeasurements(enquiryId);
        return true;
      }
      _error = response['error'] ?? 'Failed to create measurement';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMeasurement(String id, String enquiryId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateMeasurement(id, data);
      if (response['success'] == true) {
        await loadMeasurements(enquiryId);
        return true;
      }
      _error = response['error'] ?? 'Failed to update measurement';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMeasurement(String id, String enquiryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteMeasurement(id);
      if (response['success'] == true) {
        _measurements.removeWhere((m) => m.id == id);
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to delete measurement';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> convertMeterToSqft(double length, double breadth) async {
    try {
      final response = await ApiService.convertMeterToSqft(length, breadth);
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Conversion error: $e');
    }
    return null;
  }
}
