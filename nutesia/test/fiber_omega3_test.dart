import 'package:flutter_test/flutter_test.dart';
import 'package:nutesia/core/utils/bmi_utils.dart';
import 'package:nutesia/shared/models/nutrition_model.dart';

void main() {
  test('fiber and omega-3 survive JSON and add up across foods', () {
    final rice = NutritionData.fromJson({
      'calories': 200,
      'fiber': 1.5,
      'omega3': 0.02,
    });
    final salmon = NutritionData.fromJson({
      'calories': 230,
      'fiber': 0,
      'omega3': 1.8,
    });
    final total = rice + salmon;
    expect(total.fiber, closeTo(1.5, 1e-9));
    expect(total.omega3, closeTo(1.82, 1e-9));

    final restored = NutritionData.fromJson(total.toJson());
    expect(restored.fiber, closeTo(1.5, 1e-9));
    expect(restored.omega3, closeTo(1.82, 1e-9));
  });

  test('changing the portion scales fiber and omega-3', () {
    const half = NutritionData(fiber: 8, omega3: 1.2);
    final doubled = half.scale(2);
    expect(doubled.fiber, 16);
    expect(doubled.omega3, closeTo(2.4, 1e-9));
  });

  test('daily targets read from the server include fiber and omega-3', () {
    final targets = NutritionData.fromJson({
      'calories': 2200,
      'fiber': 34.0,
      'omega3': 1.6,
    });
    expect(targets.fiber, 34);
    expect(targets.omega3, 1.6);
  });

  test('offline targets match the server reference values', () {
    final man = BMIUtils.generateTargets(
      weightKg: 75,
      heightCm: 178,
      age: 30,
      gender: 'male',
      goal: 'maintain',
    );
    expect(man.fiber, 34);
    expect(man.omega3, 1.6);
    final child = BMIUtils.generateTargets(
      weightKg: 25,
      heightCm: 125,
      age: 7,
      gender: 'female',
      goal: 'maintain',
    );
    expect(child.fiber, 14);
    expect(child.omega3, 0.9);
  });
}
