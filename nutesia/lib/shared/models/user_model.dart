import 'nutrition_model.dart';

class CalculationMetadata {
  final String status;
  final DateTime? calculatedAt;
  final String algorithmVersion;
  final String safetyState;

  const CalculationMetadata({
    this.status = 'not_calculated',
    this.calculatedAt,
    this.algorithmVersion = '',
    this.safetyState = 'normal',
  });

  factory CalculationMetadata.fromJson(Map<String, dynamic> json) => CalculationMetadata(
        status: json['status'] as String? ?? 'not_calculated',
        calculatedAt: json['calculatedAt'] != null
            ? DateTime.tryParse(json['calculatedAt'] as String)
            : null,
        algorithmVersion: json['algorithmVersion'] as String? ?? '',
        safetyState: json['safetyState'] as String? ?? 'normal',
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'calculatedAt': calculatedAt?.toIso8601String(),
        'algorithmVersion': algorithmVersion,
        'safetyState': safetyState,
      };
}

class UserModel {
  final String deviceId;
  final String name;
  final int age;
  final String gender; // 'male' | 'female'
  final double heightCm;
  final double weightKg;
  final String goal; // 'lose_weight' | 'maintain_weight' | 'gain_weight'
  final double bmi;
  final String bmiCategory;
  final String profileStatus; // 'profile_complete' | 'profile_incomplete' | 'profile_needs_update'
  final CalculationMetadata calculation;
  final NutritionData dailyTargets;
  final DateTime createdAt;

  const UserModel({
    required this.deviceId,
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.bmi,
    required this.bmiCategory,
    this.profileStatus = 'profile_incomplete',
    this.calculation = const CalculationMetadata(),
    required this.dailyTargets,
    required this.createdAt,
  });

  /// Returns true if the user has completed onboarding with valid name, metrics, and age.
  bool get isProfileComplete =>
      name.trim().isNotEmpty &&
      name.trim() != 'Primary Member' &&
      name.trim() != 'User' &&
      heightCm > 0 &&
      weightKg > 0 &&
      age > 0;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('profiles') &&
        json['profiles'] is List &&
        (json['profiles'] as List).isNotEmpty) {
      final profiles = json['profiles'] as List;
      final activeId = json['activeProfileId'] as String?;
      Map<String, dynamic>? activeProfile;
      if (activeId != null && activeId.isNotEmpty) {
        for (final p in profiles) {
          if (p is Map<String, dynamic> && p['id'] == activeId) {
            activeProfile = p;
            break;
          }
        }
      }
      activeProfile ??= (profiles.first as Map<String, dynamic>);

      final deviceId = (json['ownerUserId'] ?? json['id'] ?? json['deviceId'] ?? '').toString();

      return UserModel(
        deviceId: deviceId,
        name: activeProfile['name'] as String? ?? '',
        age: activeProfile['age'] as int? ?? 0,
        gender: activeProfile['gender'] as String? ?? 'male',
        heightCm: (activeProfile['heightCm'] as num?)?.toDouble() ?? 0,
        weightKg: (activeProfile['weightKg'] as num?)?.toDouble() ?? 0,
        goal: activeProfile['goal'] as String? ?? 'maintain_weight',
        bmi: (activeProfile['bmi'] as num?)?.toDouble() ?? 0,
        bmiCategory: activeProfile['bmiCategory'] as String? ?? 'Normal',
        profileStatus: activeProfile['profileStatus'] as String? ?? 'profile_incomplete',
        calculation: activeProfile['calculation'] != null && activeProfile['calculation'] is Map<String, dynamic>
            ? CalculationMetadata.fromJson(activeProfile['calculation'] as Map<String, dynamic>)
            : const CalculationMetadata(),
        dailyTargets: activeProfile['dailyTargets'] != null && activeProfile['dailyTargets'] is Map<String, dynamic>
            ? NutritionData.fromJson(activeProfile['dailyTargets'] as Map<String, dynamic>)
            : const NutritionData(),
        createdAt: activeProfile['createdAt'] != null
            ? (DateTime.tryParse(activeProfile['createdAt'] as String) ?? DateTime.now())
            : DateTime.now(),
      );
    }

    return UserModel(
      deviceId: (json['deviceId'] ?? json['id'] ?? json['ownerUserId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? 'male',
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      goal: json['goal'] as String? ?? 'maintain_weight',
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0,
      bmiCategory: json['bmiCategory'] as String? ?? 'Normal',
      profileStatus: json['profileStatus'] as String? ?? 'profile_incomplete',
      calculation: json['calculation'] != null && json['calculation'] is Map<String, dynamic>
          ? CalculationMetadata.fromJson(
              json['calculation'] as Map<String, dynamic>)
          : const CalculationMetadata(),
      dailyTargets: json['dailyTargets'] != null && json['dailyTargets'] is Map<String, dynamic>
          ? NutritionData.fromJson(
              json['dailyTargets'] as Map<String, dynamic>)
          : const NutritionData(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'name': name,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal,
        'bmi': bmi,
        'bmiCategory': bmiCategory,
        'profileStatus': profileStatus,
        'calculation': calculation.toJson(),
        'dailyTargets': dailyTargets.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? goal,
    double? bmi,
    String? bmiCategory,
    String? profileStatus,
    CalculationMetadata? calculation,
    NutritionData? dailyTargets,
  }) =>
      UserModel(
        deviceId: deviceId,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        goal: goal ?? this.goal,
        bmi: bmi ?? this.bmi,
        bmiCategory: bmiCategory ?? this.bmiCategory,
        profileStatus: profileStatus ?? this.profileStatus,
        calculation: calculation ?? this.calculation,
        dailyTargets: dailyTargets ?? this.dailyTargets,
        createdAt: createdAt,
      );
}
