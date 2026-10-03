import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_data_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/nutrition_model.dart';

class WaterProvider extends ChangeNotifier {
  final StorageService _storage;
  final ApiDataService _api;

  int _intakeMl = 0;
  final int _targetMl = 2500;
  String _dateKey;
  bool _isLoading = false;
  String? _error;

  WaterProvider({
    StorageService? storage,
    ApiDataService? api,
    String? initialDateKey,
  })  : _storage = storage ?? StorageService(),
        _api = api ?? ApiDataService(),
        _dateKey = initialDateKey ?? AppDateUtils.todayKey() {
    loadWater();
  }

  int get intakeMl => _intakeMl;
  int get targetMl => _targetMl;
  String get dateKey => _dateKey;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateDate(DateTime date) {
    final key = AppDateUtils.toKey(date);
    if (_dateKey != key) {
      _dateKey = key;
      loadWater();
    }
  }

  Future<void> loadWater() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Load from local cache first
      final localWater = await _storage.getWaterIntakeForDate(_dateKey);
      _intakeMl = localWater;
      _isLoading = false;
      notifyListeners();

      // 2. Sync with Go backend API
      final deviceId = await DeviceService.getDeviceId();
      final rawLog = await _api.getDailyLogRaw(deviceId, _dateKey);
      if (rawLog != null && rawLog.containsKey('waterIntakeMl')) {
        final cloudWater = (rawLog['waterIntakeMl'] as num?)?.toInt() ?? 0;
        await _storage.saveWaterIntake(_dateKey, cloudWater);
        _intakeMl = cloudWater;
        notifyListeners();
      }
    } catch (e) {
      log('WaterProvider.loadWater error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWater(int ml) async {
    final updated = _intakeMl + ml;
    await setWater(updated);
  }

  Future<void> subtractWater(int ml) async {
    final updated = (_intakeMl - ml).clamp(0, 100000);
    await setWater(updated);
  }

  Future<void> setWater(int ml) async {
    final cleanMl = ml.clamp(0, 100000);
    _intakeMl = cleanMl;
    notifyListeners();

    // Save locally
    await _storage.saveWaterIntake(_dateKey, cleanMl);

    // Sync to backend
    try {
      final deviceId = await DeviceService.getDeviceId();
      final entries = await _api.getEntriesForDate(deviceId, _dateKey);
      NutritionData dailyTotal = const NutritionData();
      for (final entry in entries) {
        dailyTotal = dailyTotal + entry.totalNutrition;
      }

      await _api.saveDailyLog(
        deviceId: deviceId,
        dateKey: _dateKey,
        entries: entries,
        dailyTotal: dailyTotal,
        waterIntakeMl: cleanMl,
      );
    } catch (e) {
      log('WaterProvider.setWater: API sync failed: $e');
    }
  }

  Future<void> refresh() => loadWater();
}
