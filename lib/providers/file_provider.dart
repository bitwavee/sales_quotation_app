import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/file_upload_model.dart';
import '../services/api_service.dart';

class FileProvider extends ChangeNotifier {
  List<FileUpload> _files = [];
  bool _isLoading = false;
  String? _error;

  List<FileUpload> get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFiles(String enquiryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getFiles(enquiryId);
      if (response['success'] == true && response['data'] != null) {
        final list = response['data'] as List;
        _files = list.map((e) => FileUpload.fromJson(e)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load files';
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadFile(String enquiryId, File file, {String category = 'SITE_PHOTO'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.uploadFile(enquiryId, file, category: category);
      if (response['success'] == true) {
        await loadFiles(enquiryId);
        return true;
      }
      _error = response['error'] ?? 'Failed to upload file';
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFile(String id, String enquiryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteFile(id);
      if (response['success'] == true) {
        _files.removeWhere((f) => f.id == id);
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to delete file';
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
