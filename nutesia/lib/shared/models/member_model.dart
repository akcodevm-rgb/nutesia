import 'nutrition_model.dart';

class BMIAssessmentModel {
  final String type; // "ADULT" | "PEDIATRIC"
  final double bmi;
  final String category;
  final double? percentile;
  final double? zScore;
  final String assessmentText;
  final String version;

  const BMIAssessmentModel({
    this.type = 'ADULT',
    this.bmi = 0.0,
    this.category = 'Normal',
    this.percentile,
    this.zScore,
    this.assessmentText = '',
    this.version = 'v3.0.0-DRI2026',
  });

  factory BMIAssessmentModel.fromJson(Map<String, dynamic> json) =>
      BMIAssessmentModel(
        type: json['type'] as String? ?? 'ADULT',
        bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
        category: json['category'] as String? ?? 'Normal',
        percentile: (json['percentile'] as num?)?.toDouble(),
        zScore: (json['zScore'] as num?)?.toDouble(),
        assessmentText: json['assessmentText'] as String? ?? '',
        version: json['version'] as String? ?? 'v3.0.0-DRI2026',
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'bmi': bmi,
        'category': category,
        if (percentile != null) 'percentile': percentile,
        if (zScore != null) 'zScore': zScore,
        'assessmentText': assessmentText,
        'version': version,
      };
}

class MemberModel {
  final String id;
  final String spaceId;
  final String name;
  final String relationship; // "owner", "spouse", "child", "parent", "other"
  final String dateOfBirth; // "YYYY-MM-DD"
  final int age;
  final String gender; // "male", "female"
  final double heightCm;
  final double weightKg;
  final String heightUnit;
  final String weightUnit;
  final String goal;
  final String activityLevel;
  final String profileImage;
  final double bmi;
  final String bmiCategory;
  final BMIAssessmentModel bmiAssessment;
  final String profileStatus;
  final NutritionData dailyTargets;
  final DateTime createdAt;

  bool get isChild => age < 18;

  const MemberModel({
    required this.id,
    this.spaceId = '',
    required this.name,
    this.relationship = 'owner',
    this.dateOfBirth = '',
    this.age = 25,
    this.gender = 'female',
    required this.heightCm,
    required this.weightKg,
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
    this.goal = 'maintain_weight',
    this.activityLevel = 'lightly_active',
    this.profileImage = '',
    this.bmi = 0.0,
    this.bmiCategory = 'Normal',
    this.bmiAssessment = const BMIAssessmentModel(),
    this.profileStatus = 'profile_incomplete',
    this.dailyTargets = const NutritionData(),
    required this.createdAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'] as String? ?? '',
        spaceId: json['spaceId'] as String? ?? '',
        name: json['name'] as String? ?? '',
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
        bmiAssessment: json['bmiAssessment'] != null
            ? BMIAssessmentModel.fromJson(
                json['bmiAssessment'] as Map<String, dynamic>)
            : const BMIAssessmentModel(),
        profileStatus: json['profileStatus'] as String? ?? 'profile_incomplete',
        dailyTargets: json['dailyTargets'] != null
            ? NutritionData.fromJson(
                json['dailyTargets'] as Map<String, dynamic>)
            : const NutritionData(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'spaceId': spaceId,
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
        'bmiAssessment': bmiAssessment.toJson(),
        'profileStatus': profileStatus,
        'dailyTargets': dailyTargets.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  MemberModel copyWith({
    String? id,
    String? spaceId,
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
    BMIAssessmentModel? bmiAssessment,
    String? profileStatus,
    NutritionData? dailyTargets,
  }) =>
      MemberModel(
        id: id ?? this.id,
        spaceId: spaceId ?? this.spaceId,
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
        bmiAssessment: bmiAssessment ?? this.bmiAssessment,
        profileStatus: profileStatus ?? this.profileStatus,
        dailyTargets: dailyTargets ?? this.dailyTargets,
        createdAt: createdAt,
      );
}
