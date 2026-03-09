import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class ApiConfig {
  static const Environment environment = Environment.development;

  // Base URLs for different environments
  static const Map<Environment, String> _baseUrls = {
    Environment.development: 'https://localhost:44382/api',
    Environment.staging: 'https://staging-api.example.com/api',
    Environment.production: 'https://api.example.com/api',
  };

  // Android emulator: use localhost with adb reverse tcp:44382 tcp:44382
  static const String _androidEmulatorDevUrl = 'https://localhost:44382/api';

  static String get baseUrl {
    if (environment == Environment.development) {
      try {
        if (Platform.isAndroid) {
          debugPrint('[ApiConfig] Platform: Android -> using emulator URL: $_androidEmulatorDevUrl');
          return _androidEmulatorDevUrl;
        }
        debugPrint('[ApiConfig] Platform: ${Platform.operatingSystem}');
      } catch (e) {
        debugPrint('[ApiConfig] Platform detection failed (web?): $e');
      }
    }
    final url = _baseUrls[environment] ?? _baseUrls[Environment.development]!;
    debugPrint('[ApiConfig] Using base URL: $url');
    return url;
  }

  static const int timeout = 30;

  static bool get isDevelopment => environment == Environment.development;
  static bool get isProduction => environment == Environment.production;
}
