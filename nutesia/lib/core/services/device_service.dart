import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static String? _cachedId;

  /// Returns the current Firebase User's UID if logged in.
  /// Prepends 'test_' for testing/demo/QA accounts so they automatically receive unlimited credits.
  /// Falls back to a randomly generated UUID if not logged in.
  static Future<String> getDeviceId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = (user.email ?? '').toLowerCase();
      if (email.contains('test') || email.contains('qa') || email.contains('demo') || email.contains('admin')) {
        _cachedId = 'test_${user.uid}';
      } else {
        _cachedId = user.uid;
      }
      return _cachedId!;
    }

    // Fallback if somehow called when not logged in
    if (_cachedId != null) return _cachedId!;
    _cachedId = const Uuid().v4();
    return _cachedId!;
  }

  /// Clears the cached ID (used on logout/login).
  static void clearCache() => _cachedId = null;
}

