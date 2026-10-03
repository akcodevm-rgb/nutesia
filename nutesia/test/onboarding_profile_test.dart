import 'package:flutter_test/flutter_test.dart';
import 'package:nutesia/shared/models/user_model.dart';
import 'package:nutesia/shared/models/nutrition_model.dart';
import 'package:nutesia/features/profile/providers/nutrition_space_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserModel Serialization & Completion Tests', () {
    test('UserModel.fromJson parses flat JSON correctly', () {
      final json = {
        'deviceId': 'user_123',
        'name': 'Alex',
        'age': 28,
        'gender': 'male',
        'heightCm': 175.0,
        'weightKg': 72.0,
        'goal': 'maintain',
        'bmi': 23.5,
        'bmiCategory': 'Normal',
        'profileStatus': 'profile_complete',
        'createdAt': '2026-09-08T12:00:00.000Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.deviceId, equals('user_123'));
      expect(user.name, equals('Alex'));
      expect(user.age, equals(28));
      expect(user.heightCm, equals(175.0));
      expect(user.weightKg, equals(72.0));
      expect(user.isProfileComplete, isTrue);
    });

    test('UserModel.fromJson parses backend NutritionSpaceResponse format', () {
      final backendResponse = {
        'id': 'user_456',
        'ownerUserId': 'user_456',
        'mode': 'PERSONAL',
        'activeProfileId': 'mem_001',
        'profiles': [
          {
            'id': 'mem_001',
            'name': 'Sarah Connor',
            'age': 32,
            'gender': 'female',
            'heightCm': 168.0,
            'weightKg': 60.0,
            'goal': 'maintain',
            'bmi': 21.3,
            'bmiCategory': 'Normal',
            'profileStatus': 'profile_complete',
            'dailyTargets': {
              'calories': 2000.0,
              'protein': 120.0,
              'carbs': 240.0,
              'fat': 60.0,
            },
            'createdAt': '2026-09-08T12:00:00.000Z',
          }
        ],
      };

      final user = UserModel.fromJson(backendResponse);
      expect(user.deviceId, equals('user_456'));
      expect(user.name, equals('Sarah Connor'));
      expect(user.age, equals(32));
      expect(user.gender, equals('female'));
      expect(user.heightCm, equals(168.0));
      expect(user.weightKg, equals(60.0));
      expect(user.dailyTargets.calories, equals(2000.0));
      expect(user.isProfileComplete, isTrue);
    });

    test('isProfileComplete identifies complete vs incomplete profiles', () {
      final completeUser = UserModel(
        deviceId: 'd1',
        name: 'John',
        age: 25,
        gender: 'male',
        heightCm: 180,
        weightKg: 75,
        goal: 'maintain',
        bmi: 23.1,
        bmiCategory: 'Normal',
        dailyTargets: const NutritionData(),
        createdAt: DateTime.now(),
      );
      expect(completeUser.isProfileComplete, isTrue);

      final defaultUser = UserModel(
        deviceId: 'd1',
        name: 'User',
        age: 25,
        gender: 'male',
        heightCm: 180,
        weightKg: 75,
        goal: 'maintain',
        bmi: 23.1,
        bmiCategory: 'Normal',
        dailyTargets: const NutritionData(),
        createdAt: DateTime.now(),
      );
      expect(defaultUser.isProfileComplete, isFalse);

      final emptyNameUser = completeUser.copyWith(name: '');
      expect(emptyNameUser.isProfileComplete, isFalse);

      final zeroHeightUser = completeUser.copyWith(heightCm: 0);
      expect(zeroHeightUser.isProfileComplete, isFalse);
    });
  });

  group('NutritionSpaceProvider initFromUser tests', () {
    test('initFromUser populates space correctly', () {
      final provider = NutritionSpaceProvider();
      final user = UserModel(
        deviceId: 'dev_999',
        name: 'Emma Watson',
        age: 30,
        gender: 'female',
        heightCm: 165,
        weightKg: 55,
        goal: 'maintain',
        bmi: 20.2,
        bmiCategory: 'Normal',
        dailyTargets: const NutritionData(calories: 1900),
        createdAt: DateTime.now(),
      );

      provider.initFromUser(user);
      expect(provider.space, isNotNull);
      expect(provider.members.length, equals(1));
      expect(provider.activeMember?.name, equals('Emma Watson'));
      expect(provider.activeMember?.dailyTargets.calories, equals(1900));
    });
  });
}
