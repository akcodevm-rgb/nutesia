import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_data_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/utils/date_utils.dart';

class HomeProvider extends ChangeNotifier {
  final StorageService _storage;
  final ApiDataService _api;

  int _tabIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String _activeMemberId = '';
  List<FoodEntry> _entries = [];
  Map<String, NutritionData> _memberSummaries = {};
  List<String> _trackedMemberIds = [];
  bool _isLoading = false;
  String? _error;

  HomeProvider({
    StorageService? storage,
    ApiDataService? api,
  })  : _storage = storage ?? StorageService(),
        _api = api ?? ApiDataService() {
    loadEntries();
  }

  int get tabIndex => _tabIndex;
  DateTime get selectedDate => _selectedDate;
  String get activeMemberId => _activeMemberId;
  List<FoodEntry> get entries => _entries;
  Map<String, NutritionData> get memberSummaries => _memberSummaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get dateKey => AppDateUtils.toKey(_selectedDate);
  String get scopedDateKey => _activeMemberId.isNotEmpty ? "${_activeMemberId}_$dateKey" : dateKey;

  NutritionData get dailySummary {
    NutritionData total = const NutritionData();
    for (final entry in _entries) {
      total = total + entry.totalNutrition;
    }
    return total;
  }

  NutritionData getMemberDailySummary(String memberId) {
    if (memberId == _activeMemberId || memberId.isEmpty) {
      return dailySummary;
    }
    return _memberSummaries[memberId] ?? const NutritionData();
  }

  void setTabIndex(int index) {
    if (_tabIndex != index) {
      _tabIndex = index;
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime date) {
    if (_selectedDate != date) {
      _selectedDate = date;
      notifyListeners();
      loadEntries();
      if (_trackedMemberIds.isNotEmpty) {
        loadMemberSummaries(_trackedMemberIds);
      }
    }
  }

  void updateActiveMember(String memberId) {
    if (_activeMemberId != memberId) {
      _activeMemberId = memberId;
      notifyListeners();
      loadEntries();
      if (_trackedMemberIds.isNotEmpty) {
        loadMemberSummaries(_trackedMemberIds);
      }
    }
  }

  Future<void> loadMemberSummaries(List<String> memberIds) async {
    _trackedMemberIds = memberIds;
    final Map<String, NutritionData> updatedSummaries = Map.from(_memberSummaries);

    for (final mId in memberIds) {
      if (mId.isEmpty || mId == _activeMemberId) {
        continue;
      }
      final key = "${mId}_$dateKey";
      // 1. Read local cache
      final localEntries = await _storage.getEntriesForDate(key);
      if (localEntries.isNotEmpty) {
        updatedSummaries[mId] = _calculateTotal(localEntries);
      } else {
        updatedSummaries[mId] = const NutritionData();
      }
    }
    _memberSummaries = updatedSummaries;
    notifyListeners();

    // 2. Fetch from API in background
    try {
      final deviceId = await DeviceService.getDeviceId();
      for (final mId in memberIds) {
        if (mId.isEmpty || mId == _activeMemberId) continue;
        try {
          final cloudEntries = await _api.getEntriesForDate(
            deviceId,
            dateKey,
            memberId: mId,
          );
          if (cloudEntries.isNotEmpty) {
            final key = "${mId}_$dateKey";
            await _storage.overwriteEntriesForDate(key, cloudEntries);
            updatedSummaries[mId] = _calculateTotal(cloudEntries);
          }
        } catch (_) {}
      }
      _memberSummaries = Map.from(updatedSummaries);
      notifyListeners();
    } catch (_) {}
  }

  NutritionData _calculateTotal(List<FoodEntry> entriesList) {
    NutritionData total = const NutritionData();
    for (final entry in entriesList) {
      total = total + entry.totalNutrition;
    }
    return total;
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Load from local cache first
      final localEntries = await _storage.getEntriesForDate(scopedDateKey);
      if (localEntries.isNotEmpty) {
        _entries = localEntries;
        _isLoading = false;
        notifyListeners();
      }

      // 2. Fetch from API with memberId scoping
      final deviceId = await DeviceService.getDeviceId();
      final cloudEntries = await _api.getEntriesForDate(
        deviceId,
        dateKey,
        memberId: _activeMemberId,
      );

      if (cloudEntries.isNotEmpty) {
        await _storage.overwriteEntriesForDate(scopedDateKey, cloudEntries);
        _entries = cloudEntries;
      } else if (localEntries.isNotEmpty) {
        final dailyTotal = _calculateTotal(localEntries);
        final waterMl = await _storage.getWaterIntakeForDate(scopedDateKey);
        await _api.saveDailyLog(
          deviceId: deviceId,
          dateKey: dateKey,
          entries: localEntries,
          dailyTotal: dailyTotal,
          memberId: _activeMemberId,
          waterIntakeMl: waterMl,
        );
      } else {
        _entries = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('ℹ️ [HomeProvider.loadEntries] Using local state or offline: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry(FoodEntry entry) async {
    await _storage.saveFoodEntry(entry);

    final updated = [..._entries, entry]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    _entries = updated;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      final dailyTotal = _calculateTotal(updated);
      final waterMl = await _storage.getWaterIntakeForDate(scopedDateKey);
      await _api.saveDailyLog(
        deviceId: deviceId,
        dateKey: dateKey,
        entries: updated,
        dailyTotal: dailyTotal,
        memberId: _activeMemberId,
        waterIntakeMl: waterMl,
      );
    } catch (e) {
      log('HomeProvider.addEntry: API sync failed: $e');
    }
  }

  Future<void> updateEntry(FoodEntry entry) async {
    await _storage.updateFoodEntry(entry);

    final updated = _entries.map((e) => e.id == entry.id ? entry : e).toList();
    _entries = updated;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      final dailyTotal = _calculateTotal(updated);
      final waterMl = await _storage.getWaterIntakeForDate(scopedDateKey);
      await _api.saveDailyLog(
        deviceId: deviceId,
        dateKey: dateKey,
        entries: updated,
        dailyTotal: dailyTotal,
        memberId: _activeMemberId,
        waterIntakeMl: waterMl,
      );
    } catch (e) {
      log('HomeProvider.updateEntry: API sync failed: $e');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    await _storage.deleteFoodEntry(entryId);

    final updated = _entries.where((e) => e.id != entryId).toList();
    _entries = updated;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      final dailyTotal = _calculateTotal(updated);
      final waterMl = await _storage.getWaterIntakeForDate(scopedDateKey);
      await _api.saveDailyLog(
        deviceId: deviceId,
        dateKey: dateKey,
        entries: updated,
        dailyTotal: dailyTotal,
        memberId: _activeMemberId,
        waterIntakeMl: waterMl,
      );
    } catch (e) {
      log('HomeProvider.deleteEntry: API sync failed: $e');
    }
  }

  Future<void> refresh() => loadEntries();
}
