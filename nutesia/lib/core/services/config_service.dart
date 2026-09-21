import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads runtime configuration for native and web builds.
///
/// On native builds, this uses `.env` from the project root.
/// On Flutter web builds, this uses `assets/config.json`.
class AppConfig {
  static final Map<String, String> _values = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      try {
        final jsonString = await rootBundle.loadString('assets/config.json');
        final Map<String, dynamic> data = json.decode(jsonString);
        for (final entry in data.entries) {
          _values[entry.key] = entry.value?.toString() ?? '';
        }
      } catch (e) {
        debugPrint('Warning: web config not found or invalid: $e');
      }
    } else {
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('Warning: .env not found or could not be loaded: $e');
      }
    }

    _initialized = true;
  }

  static String get(String key, [String defaultValue = '']) {
    return _values[key] ?? dotenv.env[key] ?? defaultValue;
  }
}
