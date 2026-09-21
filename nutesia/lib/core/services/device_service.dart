import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static String? _cachedId;

  /// Returns the current Firebase User's UID if logged in.
  /// Falls back to a randomly generated UUID if not logged in 
  /// (though users should be forced to login first via AuthWrapper).
  static Future<String> getDeviceId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _cachedId = user.uid;
      return user.uid;
    }

    // Fallback if somehow called when not logged in
    if (_cachedId != null) return _cachedId!;
    _cachedId = const Uuid().v4();
    return _cachedId!;
  }

  /// Clears the cached ID (used in tests only).
  static void clearCache() => _cachedId = null;
}
