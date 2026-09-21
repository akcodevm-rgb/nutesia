import 'nutrition_model.dart';

class UserModel {
  final String deviceId;
  final String name;
  final int age;
  final String gender; // 'male' | 'female'
  final double heightCm;
  final double weightKg;
  final String goal; // 'lose' | 'maintain' | 'gain'
  final double bmi;
  final String bmiCategory;
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
    required this.dailyTargets,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        deviceId: json['deviceId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        age: json['age'] as int? ?? 0,
        gender: json['gender'] as String? ?? 'male',
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        goal: json['goal'] as String? ?? 'maintain',
        bmi: (json['bmi'] as num?)?.toDouble() ?? 0,
        bmiCategory: json['bmiCategory'] as String? ?? 'Normal',
        dailyTargets: json['dailyTargets'] != null
            ? NutritionData.fromJson(
                json['dailyTargets'] as Map<String, dynamic>)
            : const NutritionData(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

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
        dailyTargets: dailyTargets ?? this.dailyTargets,
        createdAt: createdAt,
      );
}
