import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../config/api_config.dart';

class ApiService {
  static const String _tokenKey = 'jwt_token';
  static const Duration _timeout = Duration(seconds: 30);

  // ========== AUTHENTICATION ==========
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        await _saveToken(token);
        return data;
      }
      
      return {
        'success': false,
        'error': data['error'] ?? 'Login failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<void> logout() async {
    await _clearToken();
  }

  // ========== ENQUIRIES ==========

  static Future<Map<String, dynamic>> getStaffEnquiries({int page = 1, int limit = 10}) async {
    return _get('/staff/enquiries?page=$page&limit=$limit');
  }

  static Future<Map<String, dynamic>> getAllEnquiries({int page = 1, int limit = 10, String? status}) async {
    String url = '/admin/enquiries?page=$page&limit=$limit';
    if (status != null) url += '&status=$status';
    return _get(url);
  }

  static Future<Map<String, dynamic>> getEnquiryDetails(String enquiryId) async {
    return _get('/staff/enquiries/$enquiryId');
  }

  static Future<Map<String, dynamic>> createEnquiry(Map<String, dynamic> data) async {
    return _post('/staff/enquiries', body: data);
  }

  static Future<Map<String, dynamic>> updateEnquiryStatus(
    String enquiryId,
    String newStatus,
    String? comment,
  ) async {
    return _put(
      '/staff/enquiries/$enquiryId/status',
      body: {
        'new_status': newStatus,
        'comment': comment,
      },
    );
  }

  // ========== HELPER METHODS ==========

  static Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
      ).timeout(_timeout);

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${_getErrorMessage(e)}',
      };
    }
  }

  static Future<Map<String, dynamic>> _post(String endpoint, {required Map<String, dynamic> body}) async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${_getErrorMessage(e)}',
      };
    }
  }

  static Future<Map<String, dynamic>> _put(String endpoint, {required Map<String, dynamic> body}) async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${_getErrorMessage(e)}',
      };
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      // Check HTTP status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      // Handle error responses with HTTP error codes
      return {
        'success': false,
        'error': data['error'] ?? 'Request failed with status ${response.statusCode}',
      };
    } on FormatException {
      return {
        'success': false,
        'error': 'Invalid response format from server',
      };
    }
  }

  static String _getErrorMessage(Object exception) {
    if (exception is SocketException) {
      return 'Connection failed. Check your internet.';
    } else if (exception is TimeoutException) {
      return 'Request took too long. Please try again.';
    }
    return exception.toString();
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }
}