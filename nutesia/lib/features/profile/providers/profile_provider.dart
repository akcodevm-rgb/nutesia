import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/device_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// ─── User Profile Notifier ─────────────────────────────────────────────────

class UserProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final StorageService _storage;
  final FirestoreService _firestore;

  UserProfileNotifier(this._storage, this._firestore) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      // 1. Try local storage first
      UserModel? user = await _storage.getUser();
      final currentUid = await DeviceService.getDeviceId();
      
      // If local user belongs to an old device/anonymous ID, ignore it
      if (user != null && user.deviceId != currentUid) {
        user = null;
      }
      
      // 2. If not found locally (or ignored), fetch from Firestore
      if (user == null) {
        user = await _firestore.getUser(currentUid);
        if (user != null) {
          await _storage.saveUser(user);
        }
      }
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(UserModel user) async {
    try {
      // 1. Save locally
      await _storage.saveUser(user);
      // 2. Sync to Cloud Firestore
      await _firestore.saveUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearProfile() async {
    await _storage.clearAll();
    // Note: We don't delete Firestore profile immediately on log out/clear
    // to preserve cloud data, but reset the local state.
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() => _load();
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserModel?>>(
  (ref) => UserProfileNotifier(
    ref.read(storageServiceProvider),
    ref.read(firestoreServiceProvider),
  ),
);

