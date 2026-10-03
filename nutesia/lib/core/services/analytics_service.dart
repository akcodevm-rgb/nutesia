import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Checks if analytics is supported on the current platform/environment.
  Future<bool> _canLog() async {
    try {
      return await _analytics.isSupported();
    } catch (_) {
      return false;
    }
  }

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs when the user completes their profile setup.
  Future<void> logOnboardingComplete({required String goal}) async {
    if (!await _canLog()) return;
    await _analytics.logEvent(
      name: 'onboarding_complete',
      parameters: {
        'goal': goal,
      },
    );
  }

  /// Logs when a user triggers AI food parsing.
  Future<void> logAIFoodParse({required int inputLength}) async {
    if (!await _canLog()) return;
    await _analytics.logEvent(
      name: 'ai_food_parse',
      parameters: {
        'input_length': inputLength,
      },
    );
  }

  /// Logs when a food item is successfully added to the log.
  Future<void> logFoodItemAdded({
    required String foodName,
    required double calories,
    required String mealType,
  }) async {
    if (!await _canLog()) return;
    await _analytics.logEvent(
      name: 'food_item_added',
      parameters: {
        'food_name': foodName,
        'calories': calories,
        'meal_type': mealType,
      },
    );
  }

  /// Logs a custom screen view.
  Future<void> logScreenView(String screenName) async {
    if (!await _canLog()) return;
    await _analytics.logScreenView(screenName: screenName);
  }

  /// Sets user properties.
  Future<void> setUserProperties({required String goal}) async {
    if (!await _canLog()) return;
    await _analytics.setUserProperty(name: 'user_goal', value: goal);
  }
}
