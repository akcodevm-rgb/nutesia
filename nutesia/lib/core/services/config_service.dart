import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads runtime configuration for native builds.
///
/// On native builds, this uses `.env` from the project root.
class AppConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: .env not found or could not be loaded: $e');
    }

    _initialized = true;
  }

  static String get(String key, [String defaultValue = '']) {
    return dotenv.env[key] ?? defaultValue;
  }

  static String require(String key) {
    final value = get(key).trim();
    if (value.isEmpty) {
      throw StateError('Missing required runtime configuration: $key');
    }
    return value;
  }
}
