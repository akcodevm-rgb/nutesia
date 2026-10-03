import 'package:flutter_test/flutter_test.dart';
import 'package:nutesia/core/utils/bmi_utils.dart';
import 'package:nutesia/core/utils/date_utils.dart';

void main() {
  group('BMIUtils.calculate', () {
    test('computes BMI to one decimal with its category', () {
      final r = BMIUtils.calculate(weightKg: 70, heightCm: 175);
      expect(r.bmi, 22.9);
      expect(r.category, 'Normal');
    });

    test('uses the WHO category boundaries', () {
      String cat(double kg) => BMIUtils.calculate(weightKg: kg, heightCm: 100).category;
      expect(cat(18.4), 'Underweight');
      expect(cat(18.5), 'Normal');
      expect(cat(25.0), 'Overweight');
      expect(cat(30.0), 'Obese');
    });

    test('rejects impossible measurements', () {
      final r = BMIUtils.calculate(weightKg: 0, heightCm: 175);
      expect(r.bmi, 0);
      expect(r.category, 'Unknown');
    });
  });

  group('BMIUtils.generateTargets', () {
    test('maintenance targets for a 30-year-old man, 70 kg, 175 cm', () {
      final t = BMIUtils.generateTargets(
          weightKg: 70, heightCm: 175, age: 30, gender: 'male', goal: 'maintain');
      // Harris-Benedict BMR 1695.7 × 1.4 activity = 2374 kcal.
      expect(t.calories, 2374);
      expect(t.protein, 70); // 1.0 g/kg
      expect(t.fat, 71); // 27% of calories
      expect(t.carbs, 363); // the remainder
    });

    test('losing weight lowers calories and raises protein', () {
      targetsFor(String goal) => BMIUtils.generateTargets(
          weightKg: 70, heightCm: 175, age: 30, gender: 'female', goal: goal);
      final keep = targetsFor('maintain'), lose = targetsFor('lose'), gain = targetsFor('gain');
      expect(lose.calories, keep.calories - 300);
      expect(gain.calories, keep.calories + 300);
      expect(lose.protein, greaterThan(keep.protein));
      expect(gain.protein, greaterThan(lose.protein));
    });

    test('never goes below 1200 kcal', () {
      final t = BMIUtils.generateTargets(
          weightKg: 35, heightCm: 140, age: 80, gender: 'female', goal: 'lose');
      expect(t.calories, 1200);
    });
  });

  group('AppDateUtils', () {
    test('date keys are ISO days', () {
      expect(AppDateUtils.toKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('relative labels for today and yesterday', () {
      final now = DateTime.now();
      expect(AppDateUtils.toRelative(now), 'Today');
      expect(AppDateUtils.toRelative(now.subtract(const Duration(days: 1))), 'Yesterday');
    });
  });
}
