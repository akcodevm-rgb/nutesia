import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/food_entry_model.dart';
import '../constants/app_constants.dart';

/// Local storage service using SharedPreferences + JSON encoding.
///
/// The remote source of truth is the Go API. This service is only an offline
/// cache used by feature providers for immediate reads and write recovery.
class StorageService {
  // ─── User Profile ─────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.userProfileKey,
      jsonEncode(user.toJson()),
    );
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(AppConstants.userProfileKey);
    if (str == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AppConstants.userProfileKey);
  }

  // ─── Food Entries ──────────────────────────────────────────

  Future<void> saveFoodEntry(FoodEntry entry) async {
    final entries = await _getAllEntries();
    entries.add(entry);
    await _persistEntries(entries);
  }

  Future<void> updateFoodEntry(FoodEntry updated) async {
    final entries = await _getAllEntries();
    final idx = entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      entries[idx] = updated;
      await _persistEntries(entries);
    }
  }

  Future<void> deleteFoodEntry(String entryId) async {
    final entries = await _getAllEntries();
    entries.removeWhere((e) => e.id == entryId);
    await _persistEntries(entries);
  }

  Future<List<FoodEntry>> getEntriesForDate(String dateKey) async {
    final all = await _getAllEntries();
    return all.where((e) => e.date == dateKey).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<void> _persistEntries(List<FoodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.foodEntriesKey, json);
  }

  Future<List<FoodEntry>> _getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(AppConstants.foodEntriesKey);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> overwriteEntriesForDate(
    String dateKey,
    List<FoodEntry> newEntries,
  ) async {
    final all = await _getAllEntries();
    all.removeWhere((e) => e.date == dateKey);
    all.addAll(newEntries);
    await _persistEntries(all);
  }

  Future<void> saveWaterIntake(String dateKey, int waterIntakeMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.waterIntakePrefixKey + dateKey, waterIntakeMl);
  }

  Future<int> getWaterIntakeForDate(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.waterIntakePrefixKey + dateKey) ?? 0;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
