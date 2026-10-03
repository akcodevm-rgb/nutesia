import 'dart:math' as math;
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

  /// Generates deterministic daily nutrition targets matching the Nutesia reference engine.
  /// Adults (age >= 18): Mifflin-St Jeor (1990) + PAL + Adult Safety Floors (1500M / 1200F).
  /// Pediatrics (age 2-17): Schofield (1985) + PAL + DRI Growth Allowance (No deficits).
  static NutritionData generateTargets({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goal,
    String? pregnancyStatus,
    String? breastfeedingStatus,
  }) {
    if (age < 2 ||
        (pregnancyStatus != null && pregnancyStatus.isNotEmpty && pregnancyStatus != 'none') ||
        (breastfeedingStatus != null && breastfeedingStatus.isNotEmpty && breastfeedingStatus != 'none')) {
      // Under 2, Pregnancy, or Lactation unsupported in local offline target generator
      return const NutritionData(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        vitamins: Vitamins(),
        minerals: Minerals(),
      );
    }

    final isMale = gender.toLowerCase() == 'male';
    double targetCalories;
    double proteinGrams;
    double fatGrams;
    double carbsGrams;

    if (age < 18) {
      // 1. Schofield Pediatric BMR (1985)
      double bmr;
      if (age < 3) {
        bmr = isMale ? (60.9 * weightKg - 54.0) : (61.0 * weightKg - 51.0);
      } else if (age < 10) {
        bmr = isMale ? (22.7 * weightKg + 495.0) : (22.5 * weightKg + 499.0);
      } else {
        bmr = isMale ? (17.5 * weightKg + 651.0) : (12.2 * weightKg + 746.0);
      }

      // Pediatric PAL (lightly active 1.40x default)
      const pal = 1.40;
      double growthAllowance = 30.0;
      if (age >= 10 && age < 14) {
        growthAllowance = 60.0;
      } else if (age >= 14) {
        growthAllowance = 100.0;
      }

      final tdee = (bmr * pal) + growthAllowance;

      // Pediatric deficit prohibition: if weight_loss, maintain growth baseline
      if (goal == 'gain' || goal == 'weight_gain') {
        targetCalories = tdee + 250.0;
      } else {
        targetCalories = tdee;
      }

      // Growth floor
      double minFloor = 1100.0;
      if (age >= 10 && age < 14) {
        minFloor = 1400.0;
      } else if (age >= 14) {
        minFloor = 1700.0;
      }
      if (targetCalories < minFloor) targetCalories = minFloor;

      // Macros
      final proteinPerKg = age <= 3 ? 1.1 : (age >= 14 ? 1.4 : 1.2);
      proteinGrams = math.max(20.0, (weightKg * proteinPerKg).roundToDouble());
      final fatRatio = age <= 3 ? 0.35 : 0.30;
      fatGrams = ((targetCalories * fatRatio) / 9.0).roundToDouble();
      final proteinCal = proteinGrams * 4.0;
      final fatCal = fatGrams * 9.0;
      carbsGrams = math.max(100.0, ((targetCalories - proteinCal - fatCal) / 4.0).roundToDouble());
    } else {
      // Adult Mifflin-St Jeor (1990)
      double bmr;
      if (isMale) {
        bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + 5.0;
      } else {
        bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) - 161.0;
      }

      const pal = 1.375; // lightly active
      final tdee = bmr * pal;

      if (goal == 'lose' || goal == 'weight_loss') {
        targetCalories = tdee - 500.0;
      } else if (goal == 'gain' || goal == 'weight_gain') {
        targetCalories = tdee + 400.0;
      } else if (goal == 'muscle_gain') {
        targetCalories = tdee + 300.0;
      } else {
        targetCalories = tdee;
      }

      // Nutesia Adult Application Safety Floors (1500M / 1200F)
      final minFloor = isMale ? 1500.0 : 1200.0;
      if (targetCalories < minFloor) targetCalories = minFloor;

      proteinGrams = math.max(50.0, (weightKg * 1.4).roundToDouble());
      fatGrams = ((targetCalories * 0.28) / 9.0).roundToDouble();
      final proteinCal = proteinGrams * 4.0;
      final fatCal = fatGrams * 9.0;
      carbsGrams = math.max(130.0, ((targetCalories - proteinCal - fatCal) / 4.0).roundToDouble());
    }

    return NutritionData(
      calories: targetCalories.roundToDouble(),
      protein: proteinGrams,
      carbs: carbsGrams,
      fat: fatGrams,
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
