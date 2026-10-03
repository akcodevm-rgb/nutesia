import 'nutrition_model.dart';
import 'user_model.dart';

class MemberProfileModel {
  final String id;
  final String name;
  final String relationship; // 'owner' | 'spouse' | 'child' | 'parent'
  final String dateOfBirth; // YYYY-MM-DD
  final int age;
  final String gender; // 'male' | 'female'
  final double heightCm;
  final double weightKg;
  final String heightUnit;
  final String weightUnit;
  final String goal; // 'lose_weight' | 'maintain_weight' | 'gain_weight'
  final String activityLevel;
  final String profileImage;
  final double bmi;
  final String bmiCategory;
  final String profileStatus;
  final CalculationMetadata calculation;
  final NutritionData dailyTargets;
  final DateTime createdAt;

  const MemberProfileModel({
    required this.id,
    required this.name,
    this.relationship = 'owner',
    this.dateOfBirth = '',
    this.age = 0,
    this.gender = 'female',
    this.heightCm = 0.0,
    this.weightKg = 0.0,
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
    this.goal = 'maintain_weight',
    this.activityLevel = 'lightly_active',
    this.profileImage = '',
    this.bmi = 0.0,
    this.bmiCategory = 'Normal',
    this.profileStatus = 'profile_incomplete',
    this.calculation = const CalculationMetadata(),
    this.dailyTargets = const NutritionData(),
    required this.createdAt,
  });

  bool get isChild => age < 18 || relationship == 'child';
  bool get isOwner => relationship == 'owner';

  factory MemberProfileModel.fromJson(Map<String, dynamic> json) {
    return MemberProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Member',
      relationship: json['relationship'] as String? ?? 'owner',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? 'female',
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      heightUnit: json['heightUnit'] as String? ?? 'cm',
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      goal: json['goal'] as String? ?? 'maintain_weight',
      activityLevel: json['activityLevel'] as String? ?? 'lightly_active',
      profileImage: json['profileImage'] as String? ?? '',
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
      bmiCategory: json['bmiCategory'] as String? ?? 'Normal',
      profileStatus: json['profileStatus'] as String? ?? 'profile_incomplete',
      calculation: json['calculation'] != null
          ? CalculationMetadata.fromJson(json['calculation'] as Map<String, dynamic>)
          : const CalculationMetadata(),
      dailyTargets: json['dailyTargets'] != null
          ? NutritionData.fromJson(json['dailyTargets'] as Map<String, dynamic>)
          : const NutritionData(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'dateOfBirth': dateOfBirth,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'heightUnit': heightUnit,
        'weightUnit': weightUnit,
        'goal': goal,
        'activityLevel': activityLevel,
        'profileImage': profileImage,
        'bmi': bmi,
        'bmiCategory': bmiCategory,
        'profileStatus': profileStatus,
        'calculation': calculation.toJson(),
        'dailyTargets': dailyTargets.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  MemberProfileModel copyWith({
    String? id,
    String? name,
    String? relationship,
    String? dateOfBirth,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? heightUnit,
    String? weightUnit,
    String? goal,
    String? activityLevel,
    String? profileImage,
    double? bmi,
    String? bmiCategory,
    String? profileStatus,
    CalculationMetadata? calculation,
    NutritionData? dailyTargets,
  }) {
    return MemberProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      profileImage: profileImage ?? this.profileImage,
      bmi: bmi ?? this.bmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      profileStatus: profileStatus ?? this.profileStatus,
      calculation: calculation ?? this.calculation,
      dailyTargets: dailyTargets ?? this.dailyTargets,
      createdAt: createdAt,
    );
  }
}
