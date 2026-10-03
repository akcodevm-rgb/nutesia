import 'package:flutter/foundation.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_data_service.dart';
import '../../../core/services/device_service.dart';

class UserProfileProvider extends ChangeNotifier {
  final StorageService _storage;
  final ApiDataService _api;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserProfileProvider({
    StorageService? storage,
    ApiDataService? api,
  })  : _storage = storage ?? StorageService(),
        _api = api ?? ApiDataService() {
    load();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _user != null && _user!.isProfileComplete;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Try local storage first
      UserModel? loadedUser = await _storage.getUser();
      final currentUid = await DeviceService.getDeviceId();
      debugPrint('🔍 [UserProfileProvider.load] currentUid: $currentUid, localUser: ${loadedUser?.name}');

      // If local user belongs to an old device/anonymous ID, ignore it
      if (loadedUser != null && loadedUser.deviceId != currentUid) {
        debugPrint('🔄 [UserProfileProvider.load] local user belongs to different ID, resetting');
        loadedUser = null;
      }

      // 2. If not found locally (or ignored), fetch from remote API
      if (loadedUser == null) {
        try {
          debugPrint('🌐 [UserProfileProvider.load] Fetching remote profile from API...');
          loadedUser = await _api.getUser(currentUid);
          if (loadedUser != null && loadedUser.isProfileComplete) {
            debugPrint('✅ [UserProfileProvider.load] Remote user found: ${loadedUser.name}');
            await _storage.saveUser(loadedUser);
          } else {
            debugPrint('ℹ️ [UserProfileProvider.load] No valid remote user profile found (new user)');
            loadedUser = null;
          }
        } catch (e) {
          debugPrint('⚠️ [UserProfileProvider.load] Remote fetch failed (offline fallback active): $e');
        }
      }

      // Ensure that incomplete/default mock profiles trigger onboarding
      if (loadedUser != null && !loadedUser.isProfileComplete) {
        debugPrint('⚠️ [UserProfileProvider.load] user profile is incomplete, resetting to null');
        loadedUser = null;
      }

      _user = loadedUser;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [UserProfileProvider.load] Error loading profile: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserModel user) async {
    debugPrint('💾 [UserProfileProvider.saveProfile] Saving locally for ${user.deviceId} (${user.name})...');
    // 1. Save locally first (offline-first)
    await _storage.saveUser(user);
    _user = user;
    notifyListeners();
    debugPrint('✅ [UserProfileProvider.saveProfile] Local profile saved.');

    // 2. Sync in background so UI transition is instantaneous
    _syncToRemoteApi(user);
  }

  Future<void> _syncToRemoteApi(UserModel user) async {
    try {
      debugPrint('🌐 [UserProfileProvider.saveProfile] Syncing profile to remote API...');
      final savedUser = await _api.saveUser(user);
      if (savedUser.deviceId.isNotEmpty && savedUser.name.isNotEmpty) {
        await _storage.saveUser(savedUser);
        _user = savedUser;
        notifyListeners();
        debugPrint('✅ [UserProfileProvider.saveProfile] Remote API sync succeeded!');
      }
    } catch (e) {
      debugPrint('⚠️ [UserProfileProvider.saveProfile] Remote API sync failed: $e');
    }
  }

  Future<void> clearProfile() async {
    await _storage.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<void> refresh() => load();
}
