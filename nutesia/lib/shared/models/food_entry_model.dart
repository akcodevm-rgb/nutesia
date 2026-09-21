import 'nutrition_model.dart';

class FoodItem {
  final String name;
  double quantity;
  String unit;
  final double baseQuantity;
  final NutritionData baseNutrition; // per original quantity

  FoodItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.baseNutrition,
    double? baseQuantity,
  }) : baseQuantity = baseQuantity ?? (quantity > 0 ? quantity : 1.0);

  /// Returns nutrition scaled to current quantity.
  /// If quantity changed from base, scales accordingly.
  NutritionData get nutrition {
    if (baseQuantity == 0) return baseNutrition;
    final factor = quantity / baseQuantity;
    return baseNutrition.scale(factor);
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toDouble() ?? 0;
    return FoodItem(
      name: json['name'] as String? ?? '',
      quantity: qty,
      unit: json['unit'] as String? ?? 'g',
      baseQuantity: (json['baseQuantity'] as num?)?.toDouble() ?? (qty > 0 ? qty : 1.0),
      baseNutrition: json['nutrition'] != null
          ? NutritionData.fromJson(
              json['nutrition'] as Map<String, dynamic>)
          : const NutritionData(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'baseQuantity': baseQuantity,
        'nutrition': baseNutrition.toJson(),
      };

  FoodItem copyWith({String? name, double? quantity, String? unit, double? baseQuantity}) => FoodItem(
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        baseQuantity: baseQuantity ?? this.baseQuantity,
        baseNutrition: baseNutrition,
      );
}

class FoodEntry {
  final String id;
  final String deviceId;
  final String date; // 'YYYY-MM-DD'
  final String mealType; // 'Breakfast' | 'Lunch' | 'Dinner' | 'Snacks'
  final List<FoodItem> foods;
  final NutritionData totalNutrition;
  final String explanation;
  final String rawInput;
  final DateTime loggedAt;

  const FoodEntry({
    required this.id,
    required this.deviceId,
    required this.date,
    required this.mealType,
    required this.foods,
    required this.totalNutrition,
    required this.explanation,
    required this.rawInput,
    required this.loggedAt,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'] as String? ?? '',
        deviceId: json['deviceId'] as String? ?? '',
        date: json['date'] as String? ?? '',
        mealType: json['mealType'] as String? ?? 'Snacks',
        foods: (json['foods'] as List<dynamic>? ?? [])
            .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalNutrition: json['totalNutrition'] != null
            ? NutritionData.fromJson(
                json['totalNutrition'] as Map<String, dynamic>)
            : const NutritionData(),
        explanation: json['explanation'] as String? ?? '',
        rawInput: json['rawInput'] as String? ?? '',
        loggedAt: json['loggedAt'] != null
            ? DateTime.parse(json['loggedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'date': date,
        'mealType': mealType,
        'foods': foods.map((e) => e.toJson()).toList(),
        'totalNutrition': totalNutrition.toJson(),
        'explanation': explanation,
        'rawInput': rawInput,
        'loggedAt': loggedAt.toIso8601String(),
      };

  FoodEntry copyWith({
    String? mealType,
    List<FoodItem>? foods,
    NutritionData? totalNutrition,
  }) =>
      FoodEntry(
        id: id,
        deviceId: deviceId,
        date: date,
        mealType: mealType ?? this.mealType,
        foods: foods ?? this.foods,
        totalNutrition: totalNutrition ?? this.totalNutrition,
        explanation: explanation,
        rawInput: rawInput,
        loggedAt: loggedAt,
      );
}
