import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/food_entry_model.dart';
import '../../shared/models/nutrition_model.dart';

/// Database service using Firebase Firestore.
/// Optimized for cost-efficiency by consolidating daily entries into a single document.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService() {
    // Configure Firestore Settings for offline persistence
    // Offline persistence is enabled by default on mobile platforms.
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      log('FirestoreService: Offline persistence configured.');
    } catch (e) {
      log('FirestoreService: Settings already initialized or failed: $e');
    }
  }

  // ─── User Profile ─────────────────────────────────────────

  /// Saves or updates the user profile in Firestore.
  Future<void> saveUser(UserModel user) async {
    log('FirestoreService.saveUser: Saving profile for device ${user.deviceId}');
    try {
      await _firestore
          .collection('users')
          .doc(user.deviceId)
          .set(user.toJson(), SetOptions(merge: true));
      log('FirestoreService.saveUser: Profile saved successfully.');
    } catch (e) {
      log('FirestoreService.saveUser: Error saving profile: $e');
      rethrow;
    }
  }

  /// Retrieves the user profile from Firestore.
  Future<UserModel?> getUser(String deviceId) async {
    log('FirestoreService.getUser: Fetching profile for device $deviceId');
    try {
      final doc = await _firestore.collection('users').doc(deviceId).get();
      if (doc.exists && doc.data() != null) {
        log('FirestoreService.getUser: Profile found.');
        return UserModel.fromJson(doc.data()!);
      }
      log('FirestoreService.getUser: Profile not found.');
      return null;
    } catch (e) {
      log('FirestoreService.getUser: Error fetching profile: $e');
      rethrow;
    }
  }

  // ─── Daily Consolidated Logs ─────────────────────────────────

  /// Saves the complete list of food entries and daily total nutrition for a date.
  Future<void> saveDailyLog({
    required String deviceId,
    required String dateKey,
    required List<FoodEntry> entries,
    required NutritionData dailyTotal,
  }) async {
    log('FirestoreService.saveDailyLog: Saving ${entries.length} entries for $dateKey');
    try {
      final docRef = _firestore
          .collection('users')
          .doc(deviceId)
          .collection('days')
          .doc(dateKey);

      final data = {
        'date': dateKey,
        'totalNutrition': dailyTotal.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));
      log('FirestoreService.saveDailyLog: Daily log saved successfully.');
    } catch (e) {
      log('FirestoreService.saveDailyLog: Error saving daily log: $e');
      rethrow;
    }
  }

  /// Retrieves the daily consolidated log for a specific date.
  Future<Map<String, dynamic>?> getDailyLogRaw(String deviceId, String dateKey) async {
    log('FirestoreService.getDailyLogRaw: Fetching daily log for $dateKey');
    try {
      final doc = await _firestore
          .collection('users')
          .doc(deviceId)
          .collection('days')
          .doc(dateKey)
          .get();

      if (doc.exists && doc.data() != null) {
        log('FirestoreService.getDailyLogRaw: Daily log found.');
        return doc.data();
      }
      log('FirestoreService.getDailyLogRaw: Daily log not found.');
      return null;
    } catch (e) {
      log('FirestoreService.getDailyLogRaw: Error fetching daily log: $e');
      rethrow;
    }
  }

  /// Retrieves and parses food entries for a specific date.
  Future<List<FoodEntry>> getEntriesForDate(String deviceId, String dateKey) async {
    try {
      final raw = await getDailyLogRaw(deviceId, dateKey);
      if (raw == null || raw['entries'] == null) return [];

      final list = raw['entries'] as List<dynamic>;
      return list
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    } catch (e) {
      log('FirestoreService.getEntriesForDate: Error: $e');
      return [];
    }
  }

  /// Retrieves all consolidated day documents within a date range (inclusive).
  /// Start and End keys are formatted as 'YYYY-MM-DD'.
  Future<List<Map<String, dynamic>>> getDailyLogsForRange({
    required String deviceId,
    required String startDateKey,
    required String endDateKey,
  }) async {
    log('FirestoreService.getDailyLogsForRange: Fetching logs from $startDateKey to $endDateKey');
    try {
      final query = await _firestore
          .collection('users')
          .doc(deviceId)
          .collection('days')
          .where('date', isGreaterThanOrEqualTo: startDateKey)
          .where('date', isLessThanOrEqualTo: endDateKey)
          .get();

      final results = query.docs.map((doc) => doc.data()).toList();
      log('FirestoreService.getDailyLogsForRange: Retrieved ${results.length} day logs.');
      return results;
    } catch (e) {
      log('FirestoreService.getDailyLogsForRange: Error: $e');
      return [];
    }
  }
}
