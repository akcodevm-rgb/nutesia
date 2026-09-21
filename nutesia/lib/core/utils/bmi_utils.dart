import '../../shared/models/nutrition_model.dart';

class BMIResult {
  final double bmi;
  final String category;

  const BMIResult(this.bmi, this.category);
}

class BMIUtils {
  /// Calculates BMI and returns the result with category.
  static BMIResult calculate({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0 || weightKg <= 0) return const BMIResult(0, 'Unknown');
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    final String category;
    if (bmi < 18.5) {
      category = 'Underweight';
    } else if (bmi < 25.0) {
      category = 'Normal';
    } else if (bmi < 30.0) {
      category = 'Overweight';
    } else {
      category = 'Obese';
    }

    return BMIResult(
      double.parse(bmi.toStringAsFixed(1)),
      category,
    );
  }

  /// Generates personalized daily nutrition targets based on user profile.
  /// Uses Harris-Benedict BMR × 1.4 sedentary factor + goal adjustment.
  static NutritionData generateTargets({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goal,
  }) {
    // Harris-Benedict BMR
    double bmr;
    if (gender == 'male') {
      bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * age);
    }

    // Sedentary TDEE
    double tdee = bmr * 1.4;

    // Goal-based calorie target
    double targetCalories;
    if (goal == 'lose') {
      targetCalories = tdee - 300;
    } else if (goal == 'gain') {
      targetCalories = tdee + 300;
    } else {
      targetCalories = tdee;
    }
    targetCalories = targetCalories.clamp(1200, 4000);

    // Macro targets
    double proteinGrams;
    if (goal == 'gain') {
      proteinGrams = weightKg * 1.8;
    } else if (goal == 'lose') {
      proteinGrams = weightKg * 1.4;
    } else {
      proteinGrams = weightKg * 1.0;
    }

    final fatCalories = targetCalories * 0.27;
    final fatGrams = fatCalories / 9;
    final proteinCalories = proteinGrams * 4;
    final carbsCalories = targetCalories - fatCalories - proteinCalories;
    final carbsGrams = (carbsCalories / 4).clamp(50, 500);

    // Standard micronutrient RDA (gender-blended for simplicity)
    return NutritionData(
      calories: targetCalories.roundToDouble(),
      protein: proteinGrams.roundToDouble(),
      carbs: carbsGrams.roundToDouble(),
      fat: fatGrams.roundToDouble(),
      vitamins: const Vitamins(
        vitaminA: 900,
        vitaminB1: 1.2,
        vitaminB2: 1.3,
        vitaminB6: 1.7,
        vitaminB12: 2.4,
        vitaminC: 90,
        vitaminD: 15,
        vitaminE: 15,
        vitaminK: 120,
        folate: 400,
      ),
      minerals: const Minerals(
        calcium: 1000,
        iron: 18,
        zinc: 11,
        magnesium: 420,
        potassium: 3400,
        sodium: 2300,
        phosphorus: 700,
      ),
    );
  }
}
