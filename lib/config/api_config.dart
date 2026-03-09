enum Environment { development, staging, production }

class ApiConfig {
  // Change this to switch environments
  static const Environment environment = Environment.development;

  // Base URLs for different environments
  static const Map<Environment, String> _baseUrls = {
    Environment.development: 'http://localhost:5000/api',
    Environment.staging: 'https://staging-api.example.com/api',
    Environment.production: 'https://api.example.com/api',
  };

  // Android Emulator development URL (uncomment to use)
  // static const String androidEmulatorUrl = 'http://10.0.2.2:5000/api';

  static String get baseUrl => _baseUrls[environment] ?? _baseUrls[Environment.development]!;

  static const int timeout = 30; // seconds

  /// Get the base URL for a specific environment
  static String getBaseUrl(Environment env) => _baseUrls[env] ?? _baseUrls[Environment.development]!;

  /// For Android Emulator, use this helper
  static String get androidEmulatorUrl => 'http://10.0.2.2:5000/api';

  /// Check if running in development mode
  static bool get isDevelopment => environment == Environment.development;

  /// Check if running in production mode
  static bool get isProduction => environment == Environment.production;
}
