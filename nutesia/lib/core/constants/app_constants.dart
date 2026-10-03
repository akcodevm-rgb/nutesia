class AppConstants {
  // Storage Keys
  static const String deviceIdKey = 'nuto_device_id';
  static const String userProfileKey = 'nuto_user_profile';
  static const String foodEntriesKey = 'nuto_food_entries';
  static const String waterIntakePrefixKey = 'nuto_water_intake_';

  // Meal Types
  static const List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  // Goal Types
  static const Map<String, String> goals = {
    'lose': 'Lose Weight',
    'maintain': 'Maintain Weight',
    'gain': 'Gain Muscle',
  };

  // BMI Categories
  static const String bmiUnderweight = 'Underweight';
  static const String bmiNormal = 'Normal';
  static const String bmiOverweight = 'Overweight';
  static const String bmiObese = 'Obese';

  // Units
  static const List<String> foodUnits = [
    'grams',
    'kg',
    'ml',
    'liter',
    'pieces',
    'cups',
    'tbsp',
    'tsp',
    'bowl',
    'serving',
    'plate',
    'medium',
    'large',
    'small',
  ];

}
