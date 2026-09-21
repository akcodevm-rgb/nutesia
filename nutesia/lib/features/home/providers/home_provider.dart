import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../profile/providers/profile_provider.dart';

// ─── Selected Date ─────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ─── Food Entries Notifier ──────────────────────────────────────────────────

class FoodEntriesNotifier extends StateNotifier<AsyncValue<List<FoodEntry>>> {
  final StorageService _storage;
  final FirestoreService _firestore;
  String _dateKey;

  FoodEntriesNotifier(this._storage, this._firestore, this._dateKey)
      : super(const AsyncValue.loading()) {
    _load();
  }

  NutritionData _calculateTotal(List<FoodEntry> entries) {
    NutritionData total = const NutritionData();
    for (final entry in entries) {
      total = total + entry.totalNutrition;
    }
    return total;
  }

  Future<void> _load() async {
    try {
      // 1. Load from local cache first (instant response)
      final localEntries = await _storage.getEntriesForDate(_dateKey);
      if (localEntries.isNotEmpty) {
        state = AsyncValue.data(localEntries);
      }

      // 2. Fetch from Firestore to sync
      final deviceId = await DeviceService.getDeviceId();
      final cloudEntries = await _firestore.getEntriesForDate(deviceId, _dateKey);

      if (cloudEntries.isNotEmpty) {
        // Sync local cache with Firestore entries
        await _storage.overwriteEntriesForDate(_dateKey, cloudEntries);
        state = AsyncValue.data(cloudEntries);
      } else if (localEntries.isNotEmpty) {
        // Local has data but cloud is empty (e.g. user logged offline), sync to cloud
        final dailyTotal = _calculateTotal(localEntries);
        await _firestore.saveDailyLog(
          deviceId: deviceId,
          dateKey: _dateKey,
          entries: localEntries,
          dailyTotal: dailyTotal,
        );
      } else {
        // Both empty
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (state.hasValue) {
        log('FoodEntriesNotifier._load: Offline/Sync failed, using cached data: $e');
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addEntry(FoodEntry entry) async {
    // 1. Save locally
    await _storage.saveFoodEntry(entry);
    
    final current = state.valueOrNull ?? [];
    final updated = [...current, entry]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    state = AsyncValue.data(updated);

    // 2. Sync consolidated day to Firestore
    try {
      final deviceId = await DeviceService.getDeviceId();
      final dailyTotal = _calculateTotal(updated);
      await _firestore.saveDailyLog(
        deviceId: deviceId,
        dateKey: _dateKey,
        entries: updated,
        dailyTotal: dailyTotal,
      );
    } catch (e) {
      log('FoodEntriesNotifier.addEntry: Firestore sync failed: $e');
    }
  }

  Future<void> updateEntry(FoodEntry entry) async {
    // 1. Save locally
    await _storage.updateFoodEntry(entry);
    
    final current = state.valueOrNull ?? [];
    final updated = current.map((e) => e.id == entry.id ? entry : e).toList();
    state = AsyncValue.data(updated);

    // 2. Sync consolidated day to Firestore
    try {
      final deviceId = await DeviceService.getDeviceId();
      final dailyTotal = _calculateTotal(updated);
      await _firestore.saveDailyLog(
        deviceId: deviceId,
        dateKey: _dateKey,
        entries: updated,
        dailyTotal: dailyTotal,
      );
    } catch (e) {
      log('FoodEntriesNotifier.updateEntry: Firestore sync failed: $e');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    // 1. Save locally
    await _storage.deleteFoodEntry(entryId);
    
    final current = state.valueOrNull ?? [];
    final updated = current.where((e) => e.id != entryId).toList();
    state = AsyncValue.data(updated);

    // 2. Sync consolidated day to Firestore
    try {
      final deviceId = await DeviceService.getDeviceId();
      final dailyTotal = _calculateTotal(updated);
      await _firestore.saveDailyLog(
        deviceId: deviceId,
        dateKey: _dateKey,
        entries: updated,
        dailyTotal: dailyTotal,
      );
    } catch (e) {
      log('FoodEntriesNotifier.deleteEntry: Firestore sync failed: $e');
    }
  }

  void changeDate(String dateKey) {
    _dateKey = dateKey;
    _load();
  }

  Future<void> refresh() => _load();
}

final foodEntriesProvider = StateNotifierProvider.autoDispose<FoodEntriesNotifier, AsyncValue<List<FoodEntry>>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return FoodEntriesNotifier(
    ref.read(storageServiceProvider),
    ref.read(firestoreServiceProvider),
    AppDateUtils.toKey(date),
  );
});


// ─── Daily Nutrition Summary (derived) ─────────────────────────────────────

final dailySummaryProvider = Provider.autoDispose<NutritionData>((ref) {
  final entriesAsync = ref.watch(foodEntriesProvider);
  return entriesAsync.whenData((entries) {
    NutritionData total = const NutritionData();
    for (final entry in entries) {
      total = total + entry.totalNutrition;
    }
    return total;
  }).valueOrNull ?? const NutritionData();
});

// ─── Target Calories (from profile) ────────────────────────────────────────

final dailyTargetsProvider = Provider.autoDispose<NutritionData?>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.valueOrNull?.dailyTargets;
});
