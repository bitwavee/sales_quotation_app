import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  // Check if user was already logged in
  Future<void> checkAuthStatus() async {
    final hasToken = await ApiService.hasToken();
    if (hasToken) {
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    debugPrint('[AuthProvider] login() called with email: $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      debugPrint('[AuthProvider] ApiService.login() returned: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        if (data['user'] != null) {
          _user = User.fromJson(data['user'] as Map<String, dynamic>);
          debugPrint('[AuthProvider] User parsed: ${_user?.email}, role: ${_user?.role}');
        }

        if (data['token'] != null) {
          _token = data['token'] as String;
          debugPrint('[AuthProvider] Token saved (length: ${_token!.length})');
        }

        _isLoggedIn = true;
        _error = null;
        debugPrint('[AuthProvider] Login SUCCESS — navigating...');
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Login failed. Please try again.';
        debugPrint('[AuthProvider] Login FAILED: $_error');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'An unexpected error occurred. Please try again.';
      debugPrint('[AuthProvider] Login EXCEPTION: $e');
      debugPrint('[AuthProvider] Stack trace: $stackTrace');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _token = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}