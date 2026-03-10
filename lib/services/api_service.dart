import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../config/api_config.dart';

class ApiService {
  static const String _tokenKey = 'jwt_token';
  static const Duration _timeout = Duration(seconds: 30);

  /// Adds Host header override when connecting via 10.0.2.2 on Android emulator.
  /// IIS is bound to 'localhost' and rejects requests with Host: 10.0.2.2.
  static Map<String, String> _applyHostOverride(Map<String, String> headers) {
    if (ApiConfig.needsHostOverride) {
      headers['Host'] = ApiConfig.hostOverride;
      debugPrint('[ApiService] Host header overridden to: ${ApiConfig.hostOverride}');
    }
    return headers;
  }

  /// Creates an HTTP client that accepts self-signed certificates in development.
  static http.Client _createClient() {
    if (ApiConfig.isDevelopment) {
      debugPrint('[ApiService] Creating IOClient with badCertificateCallback (dev mode)');
      final ioClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          debugPrint('[ApiService] SSL cert check -> host: $host, port: $port — ACCEPTING');
          return true;
        };
      return IOClient(ioClient);
    }
    debugPrint('[ApiService] Creating standard http.Client (production mode)');
    return http.Client();
  }

  // ========== AUTHENTICATION ==========

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = '${ApiConfig.baseUrl}/auth/login';
    debugPrint('======================================');
    debugPrint('[LOGIN] Starting login request...');
    debugPrint('[LOGIN] URL: $url');
    debugPrint('[LOGIN] Email: $email');
    debugPrint('[LOGIN] Timeout: ${_timeout.inSeconds}s');
    debugPrint('======================================');

    final client = _createClient();
    try {
      debugPrint('[LOGIN] Sending POST request...');
      final stopwatch = Stopwatch()..start();

      final response = await client.post(
        Uri.parse(url),
        headers: _applyHostOverride({'Content-Type': 'application/json'}),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);

      stopwatch.stop();
      debugPrint('[LOGIN] Response received in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('[LOGIN] Status code: ${response.statusCode}');
      debugPrint('[LOGIN] Content-Type: ${response.headers['content-type']}');
      debugPrint('[LOGIN] Response body (first 500 chars):');
      debugPrint('[LOGIN] ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

      // Check if response is HTML (server error page) instead of JSON
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html') || response.body.trimLeft().startsWith('<!') || response.body.trimLeft().startsWith('<html')) {
        debugPrint('[LOGIN] ERROR: Server returned HTML instead of JSON!');
        debugPrint('[LOGIN] This usually means the URL is wrong or the API is not running.');
        debugPrint('[LOGIN] Full URL was: ${ApiConfig.baseUrl}/auth/login');
        debugPrint('[LOGIN] FULL HTML RESPONSE:');
        debugPrint('[LOGIN] ${response.body}');
        debugPrint('[LOGIN] Response headers: ${response.headers}');
        return {
          'success': false,
          'error': 'Server returned HTML (status ${response.statusCode}). URL may be incorrect: ${ApiConfig.baseUrl}/auth/login',
        };
      }

      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final normalized = _normalizeKeysDeep(raw) as Map<String, dynamic>;

      if (response.statusCode == 200 && normalized['success'] == true) {
        debugPrint('[LOGIN] SUCCESS — Token received, saving...');
        final loginData = normalized['data'] as Map<String, dynamic>;
        final token = loginData['token'];
        await _saveToken(token);
        return normalized;
      }

      debugPrint('[LOGIN] FAILED — ${normalized['error'] ?? 'Unknown error'}');
      return {
        'success': false,
        'error': normalized['error'] ?? 'Login failed',
      };
    } on TimeoutException catch (e) {
      debugPrint('[LOGIN] TIMEOUT ERROR after ${_timeout.inSeconds}s: $e');
      return {
        'success': false,
        'error': 'Request timed out after ${_timeout.inSeconds}s. Check if the API server is reachable.',
      };
    } on SocketException catch (e) {
      debugPrint('[LOGIN] SOCKET ERROR: $e');
      debugPrint('[LOGIN] -> address: ${e.address}, port: ${e.port}, message: ${e.message}');
      return {
        'success': false,
        'error': 'Connection failed: ${e.message}',
      };
    } on HandshakeException catch (e) {
      debugPrint('[LOGIN] SSL HANDSHAKE ERROR: $e');
      return {
        'success': false,
        'error': 'SSL/TLS handshake failed: $e',
      };
    } catch (e, stackTrace) {
      debugPrint('[LOGIN] UNEXPECTED ERROR: $e');
      debugPrint('[LOGIN] Error type: ${e.runtimeType}');
      debugPrint('[LOGIN] Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    } finally {
      client.close();
      debugPrint('[LOGIN] Request completed, client closed.');
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    final result = await _post('/auth/logout', body: {});
    await _clearToken();
    return result;
  }

  // ========== ENQUIRIES (unified, role-based) ==========

  static Future<Map<String, dynamic>> getEnquiries({String? status}) async {
    String url = '/enquiry';
    if (status != null) url += '?status=$status';
    return _get(url);
  }

  static Future<Map<String, dynamic>> getEnquiryDetails(String enquiryId) async {
    return _get('/enquiry/$enquiryId');
  }

  static Future<Map<String, dynamic>> createEnquiry(Map<String, dynamic> data) async {
    return _post('/enquiry', body: data);
  }

  static Future<Map<String, dynamic>> updateEnquiry(String enquiryId, Map<String, dynamic> data) async {
    return _put('/enquiry/$enquiryId', body: data);
  }

  static Future<Map<String, dynamic>> deleteEnquiry(String enquiryId) async {
    return _delete('/enquiry/$enquiryId');
  }

  // ========== ENQUIRY PROGRESS ==========

  static Future<Map<String, dynamic>> getEnquiryProgress(String enquiryId) async {
    return _get('/enquiryprogress/enquiry/$enquiryId');
  }

  static Future<Map<String, dynamic>> addEnquiryProgress(String enquiryId, Map<String, dynamic> data) async {
    return _post('/enquiryprogress/enquiry/$enquiryId', body: data);
  }

  static Future<Map<String, dynamic>> updateEnquiryStatus(String enquiryId, String status, String? notes) async {
    return _post('/enquiryprogress/enquiry/$enquiryId/update-status', body: {
      'status': status,
      'notes': notes,
    });
  }

  // ========== ENQUIRY STATUS CONFIG ==========

  static Future<Map<String, dynamic>> getStatusConfigs() async {
    return _get('/enquirystatusconfig');
  }

  static Future<Map<String, dynamic>> getStatusConfig(String id) async {
    return _get('/enquirystatusconfig/$id');
  }

  static Future<Map<String, dynamic>> createStatusConfig(Map<String, dynamic> data) async {
    return _post('/enquirystatusconfig', body: data);
  }

  static Future<Map<String, dynamic>> updateStatusConfig(String id, Map<String, dynamic> data) async {
    return _put('/enquirystatusconfig/$id', body: data);
  }

  static Future<Map<String, dynamic>> deleteStatusConfig(String id) async {
    return _delete('/enquirystatusconfig/$id');
  }

  // ========== STAFF MANAGEMENT ==========

  static Future<Map<String, dynamic>> getStaffList() async {
    return _get('/staff');
  }

  static Future<Map<String, dynamic>> getStaffDetails(String id) async {
    return _get('/staff/$id');
  }

  static Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    return _post('/staff', body: data);
  }

  static Future<Map<String, dynamic>> updateStaff(String id, Map<String, dynamic> data) async {
    return _put('/staff/$id', body: data);
  }

  static Future<Map<String, dynamic>> deleteStaff(String id) async {
    return _delete('/staff/$id');
  }

  static Future<Map<String, dynamic>> changeStaffRole(String id, String role) async {
    return _put('/staff/$id/role', body: {'role': role});
  }

  static Future<Map<String, dynamic>> assignEnquiryToStaff(String enquiryId, String staffId) async {
    return _post('/staff/assign-enquiry', body: {'enquiryId': enquiryId, 'staffId': staffId});
  }

  // ========== MATERIAL MANAGEMENT ==========

  static Future<Map<String, dynamic>> getMaterials() async {
    return _get('/material');
  }

  static Future<Map<String, dynamic>> getMaterial(String id) async {
    return _get('/material/$id');
  }

  static Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> data) async {
    return _post('/material', body: data);
  }

  static Future<Map<String, dynamic>> updateMaterial(String id, Map<String, dynamic> data) async {
    return _put('/material/$id', body: data);
  }

  static Future<Map<String, dynamic>> deleteMaterial(String id) async {
    return _delete('/material/$id');
  }

  // ========== MEASUREMENT ==========

  static Future<Map<String, dynamic>> getMeasurements(String enquiryId) async {
    return _get('/measurement/enquiry/$enquiryId');
  }

  static Future<Map<String, dynamic>> getMeasurement(String id) async {
    return _get('/measurement/$id');
  }

  static Future<Map<String, dynamic>> createMeasurement(String enquiryId, Map<String, dynamic> data) async {
    return _post('/measurement/$enquiryId', body: data);
  }

  static Future<Map<String, dynamic>> updateMeasurement(String id, Map<String, dynamic> data) async {
    return _put('/measurement/$id', body: data);
  }

  static Future<Map<String, dynamic>> deleteMeasurement(String id) async {
    return _delete('/measurement/$id');
  }

  static Future<Map<String, dynamic>> convertMeasurement(String type, double length, double breadth) async {
    return _post('/measurement/convert', body: {'type': type, 'length': length, 'breadth': breadth});
  }

  static Future<Map<String, dynamic>> convertMeterToSqft(double length, double breadth) async {
    return _post('/measurement/convert/meter-to-sqft', body: {'length': length, 'breadth': breadth});
  }

  // ========== QUOTATION ==========

  static Future<Map<String, dynamic>> getQuotations(String enquiryId) async {
    return _get('/quotation/enquiry/$enquiryId');
  }

  static Future<Map<String, dynamic>> getQuotation(String id) async {
    return _get('/quotation/$id');
  }

  static Future<Map<String, dynamic>> createQuotation(Map<String, dynamic> data) async {
    return _post('/quotation', body: data);
  }

  static Future<Map<String, dynamic>> updateQuotation(String id, Map<String, dynamic> data) async {
    return _put('/quotation/$id', body: data);
  }

  static Future<Map<String, dynamic>> deleteQuotation(String id) async {
    return _delete('/quotation/$id');
  }

  static Future<Map<String, dynamic>> sendQuotation(String id) async {
    return _post('/quotation/$id/send', body: {});
  }

  static Future<http.Response> getQuotationPdf(String id) async {
    final url = '${ApiConfig.baseUrl}/quotation/$id/pdf';
    debugPrint('[API GET PDF] $url');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: _applyHostOverride({if (token != null) 'Authorization': 'Bearer $token'}),
      ).timeout(_timeout);
      stopwatch.stop();
      debugPrint('[API GET PDF] quotation/$id/pdf -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms, ${response.bodyBytes.length} bytes)');
      return response;
    } catch (e) {
      debugPrint('[API GET PDF] ERROR: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<http.Response> downloadQuotationPdf(String id) async {
    final url = '${ApiConfig.baseUrl}/quotation/$id/download-pdf';
    debugPrint('[API DOWNLOAD PDF] $url');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: _applyHostOverride({if (token != null) 'Authorization': 'Bearer $token'}),
      ).timeout(_timeout);
      stopwatch.stop();
      debugPrint('[API DOWNLOAD PDF] quotation/$id/download-pdf -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms, ${response.bodyBytes.length} bytes)');
      return response;
    } catch (e) {
      debugPrint('[API DOWNLOAD PDF] ERROR: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // ========== FILE UPLOAD ==========

  static Future<Map<String, dynamic>> uploadFile(String enquiryId, File file, {String category = 'SITE_PHOTO'}) async {
    final url = '${ApiConfig.baseUrl}/file/upload/$enquiryId?category=$category';
    debugPrint('[API UPLOAD] $url');
    debugPrint('[API UPLOAD] File: ${file.path}, category: $category');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (ApiConfig.needsHostOverride) request.headers['Host'] = ApiConfig.hostOverride;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      stopwatch.stop();
      debugPrint('[API UPLOAD] -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('[API UPLOAD] Response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('[API UPLOAD] ERROR: ${e.runtimeType}: $e');
      return {'success': false, 'error': 'Upload error: ${_getErrorMessage(e)}'};
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> getFiles(String enquiryId) async {
    return _get('/file/enquiry/$enquiryId');
  }

  static Future<Map<String, dynamic>> getFileMetadata(String id) async {
    return _get('/file/$id');
  }

  static Future<http.Response> downloadFile(String id) async {
    final url = '${ApiConfig.baseUrl}/file/download/$id';
    debugPrint('[API DOWNLOAD] $url');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final response = await client.get(
        Uri.parse(url),
        headers: _applyHostOverride({if (token != null) 'Authorization': 'Bearer $token'}),
      ).timeout(_timeout);
      stopwatch.stop();
      debugPrint('[API DOWNLOAD] file/$id -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms, ${response.bodyBytes.length} bytes)');
      return response;
    } catch (e) {
      debugPrint('[API DOWNLOAD] ERROR: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> deleteFile(String id) async {
    return _delete('/file/$id');
  }

  // ========== HELPER METHODS ==========

  static Future<Map<String, dynamic>> _get(String endpoint) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API GET] $url');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final headers = _applyHostOverride({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final response = await client.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(_timeout);

      stopwatch.stop();
      debugPrint('[API GET] $endpoint -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('[API GET] Response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      debugPrint('[API GET] TIMEOUT: $endpoint after ${_timeout.inSeconds}s');
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } on SocketException catch (e) {
      debugPrint('[API GET] SOCKET ERROR: $endpoint -> ${e.message}');
      return {
        'success': false,
        'error': 'Connection failed: ${e.message}',
      };
    } on HandshakeException catch (e) {
      debugPrint('[API GET] SSL ERROR: $endpoint -> $e');
      return {
        'success': false,
        'error': 'SSL handshake failed: $e',
      };
    } catch (e) {
      debugPrint('[API GET] ERROR: $endpoint -> ${e.runtimeType}: $e');
      return {
        'success': false,
        'error': 'Network error: ${_getErrorMessage(e)}',
      };
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _post(String endpoint, {required Map<String, dynamic> body}) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API POST] $url');
    debugPrint('[API POST] Body: ${jsonEncode(body)}');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final headers = _applyHostOverride({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final response = await client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      stopwatch.stop();
      debugPrint('[API POST] $endpoint -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('[API POST] Response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      debugPrint('[API POST] TIMEOUT: $endpoint after ${_timeout.inSeconds}s');
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } on SocketException catch (e) {
      debugPrint('[API POST] SOCKET ERROR: $endpoint -> ${e.message}');
      return {
        'success': false,
        'error': 'Connection failed: ${e.message}',
      };
    } on HandshakeException catch (e) {
      debugPrint('[API POST] SSL ERROR: $endpoint -> $e');
      return {
        'success': false,
        'error': 'SSL handshake failed: $e',
      };
    } catch (e) {
      debugPrint('[API POST] ERROR: $endpoint -> ${e.runtimeType}: $e');
      return {
        'success': false,
        'error': 'Network error: ${_getErrorMessage(e)}',
      };
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _put(String endpoint, {required Map<String, dynamic> body}) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API PUT] $url');
    debugPrint('[API PUT] Body: ${jsonEncode(body)}');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final headers = _applyHostOverride({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final response = await client.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      stopwatch.stop();
      debugPrint('[API PUT] $endpoint -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('[API PUT] Response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      debugPrint('[API PUT] TIMEOUT: $endpoint after ${_timeout.inSeconds}s');
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } on SocketException catch (e) {
      debugPrint('[API PUT] SOCKET ERROR: $endpoint -> ${e.message}');
      return {
        'success': false,
        'error': 'Connection failed: ${e.message}',
      };
    } on HandshakeException catch (e) {
      debugPrint('[API PUT] SSL ERROR: $endpoint -> $e');
      return {
        'success': false,
        'error': 'SSL handshake failed: $e',
      };
    } catch (e) {
      debugPrint('[API PUT] ERROR: $endpoint -> ${e.runtimeType}: $e');
      return {
        'success': false,
        'error': 'Network error: ${_getErrorMessage(e)}',
      };
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _delete(String endpoint) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API DELETE] $url');
    final client = _createClient();
    final stopwatch = Stopwatch()..start();
    try {
      final token = await _getToken();
      final headers = _applyHostOverride({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final response = await client.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(_timeout);

      stopwatch.stop();
      debugPrint('[API DELETE] $endpoint -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('[API DELETE] Response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      debugPrint('[API DELETE] TIMEOUT: $endpoint after ${_timeout.inSeconds}s');
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } on SocketException catch (e) {
      debugPrint('[API DELETE] SOCKET ERROR: $endpoint -> ${e.message}');
      return {
        'success': false,
        'error': 'Connection failed: ${e.message}',
      };
    } on HandshakeException catch (e) {
      debugPrint('[API DELETE] SSL ERROR: $endpoint -> $e');
      return {
        'success': false,
        'error': 'SSL handshake failed: $e',
      };
    } catch (e) {
      debugPrint('[API DELETE] ERROR: $endpoint -> ${e.runtimeType}: $e');
      return {
        'success': false,
        'error': 'Network error: ${_getErrorMessage(e)}',
      };
    } finally {
      client.close();
    }
  }

  /// Converts a PascalCase string to camelCase (e.g. "CustomerName" -> "customerName").
  static String _toCamelCase(String key) {
    if (key.isEmpty) return key;
    // Already camelCase or lowercase
    if (key[0] == key[0].toLowerCase()) return key;
    return key[0].toLowerCase() + key.substring(1);
  }

  /// Recursively converts all map keys from PascalCase to camelCase.
  static dynamic _normalizeKeysDeep(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(_toCamelCase(k), _normalizeKeysDeep(v)));
    } else if (value is List) {
      return value.map((e) => _normalizeKeysDeep(e)).toList();
    }
    return value;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    // Check if response is HTML instead of JSON
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html') || response.body.trimLeft().startsWith('<!') || response.body.trimLeft().startsWith('<html')) {
      debugPrint('[API] ERROR: Server returned HTML instead of JSON (status ${response.statusCode})');
      debugPrint('[API] HTML body (first 300 chars): ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
      return {
        'success': false,
        'error': 'Server returned HTML (status ${response.statusCode}). Check API URL.',
      };
    }

    try {
      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final data = _normalizeKeysDeep(raw) as Map<String, dynamic>;

      // Check HTTP status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      debugPrint('[API] Error response (${response.statusCode}): ${response.body}');
      return {
        'success': false,
        'error': data['error'] ?? 'Request failed with status ${response.statusCode}',
      };
    } on FormatException catch (e) {
      debugPrint('[API] JSON parse error: $e');
      debugPrint('[API] Raw body: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
      return {
        'success': false,
        'error': 'Invalid response format from server (status ${response.statusCode})',
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