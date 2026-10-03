import 'package:flutter_test/flutter_test.dart';
import 'package:nutesia/shared/models/member_model.dart';
import 'package:nutesia/shared/models/nutrition_space_model.dart';

void main() {
  test('NutritionSpaceModel deserializes PERSONAL and FAMILY spaces', () {
    final personalJson = {
      'id': 'space_001',
      'ownerUserId': 'user_001',
      'mode': 'PERSONAL',
      'maxMembers': 3,
      'profiles': [
        {
          'id': 'mem_001',
          'spaceId': 'space_001',
          'name': 'Sarah',
          'relationship': 'owner',
          'dateOfBirth': '1996-04-12',
          'age': 30,
          'gender': 'female',
          'heightCm': 168.0,
          'weightKg': 62.0,
          'bmi': 22.0,
          'bmiCategory': 'Normal',
        }
      ],
    };

    final personalSpace = NutritionSpaceModel.fromJson(personalJson);
    expect(personalSpace.isFamilyMode, isFalse);
    expect(personalSpace.profiles.length, equals(1));
    expect(personalSpace.canAddMember, isTrue);
    expect(personalSpace.activeProfile?.name, equals('Sarah'));

    // Upgrade to FAMILY with child
    final familySpace = personalSpace.copyWith(
      mode: 'FAMILY',
      profiles: [
        personalSpace.profiles.first,
        MemberModel(
          id: 'mem_002',
          spaceId: 'space_001',
          name: 'Leo',
          relationship: 'child',
          dateOfBirth: '2016-01-01',
          age: 10,
          gender: 'male',
          heightCm: 138.0,
          weightKg: 32.0,
          bmi: 16.8,
          bmiCategory: 'Healthy Weight',
          bmiAssessment: const BMIAssessmentModel(
            type: 'PEDIATRIC',
            bmi: 16.8,
            category: 'Healthy Weight',
            percentile: 50.0,
          ),
          createdAt: DateTime.now(),
        ),
      ],
    );

    expect(familySpace.isFamilyMode, isTrue);
    expect(familySpace.profiles.length, equals(2));
    expect(familySpace.profiles[1].isChild, isTrue);
    expect(familySpace.profiles[1].bmiAssessment.percentile, equals(50.0));
  });
}
