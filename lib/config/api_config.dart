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

  // Android emulator: 10.0.2.2 routes to the Windows host's loopback.
  // We connect to 10.0.2.2 but send Host: localhost so IIS accepts it.
  static const String _androidEmulatorDevUrl = 'https://10.0.2.2:44382/api';

  /// Whether the current request needs a Host header override.
  static bool get needsHostOverride {
    if (environment != Environment.development) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// The Host header value to send when connecting via 10.0.2.2.
  static const String hostOverride = 'localhost:44382';

  static String get baseUrl {
    if (environment == Environment.development) {
      try {
        if (Platform.isAndroid) {
          debugPrint('[ApiConfig] Platform: Android -> using emulator URL: $_androidEmulatorDevUrl');
          debugPrint('[ApiConfig] Will override Host header to: $hostOverride');
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
