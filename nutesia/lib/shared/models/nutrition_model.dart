// Vitamins model (values in daily RDA units: mcg or mg)
class Vitamins {
  final double vitaminA; // mcg RAE  (RDA: 900)
  final double vitaminB1; // mg thiamin (RDA: 1.2)
  final double vitaminB2; // mg riboflavin (RDA: 1.3)
  final double vitaminB6; // mg        (RDA: 1.7)
  final double vitaminB12; // mcg      (RDA: 2.4)
  final double vitaminC; // mg         (RDA: 90)
  final double vitaminD; // mcg        (RDA: 15)
  final double vitaminE; // mg         (RDA: 15)
  final double vitaminK; // mcg        (RDA: 120)
  final double folate; // mcg DFE      (RDA: 400)

  const Vitamins({
    this.vitaminA = 0,
    this.vitaminB1 = 0,
    this.vitaminB2 = 0,
    this.vitaminB6 = 0,
    this.vitaminB12 = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.vitaminE = 0,
    this.vitaminK = 0,
    this.folate = 0,
  });

  factory Vitamins.fromJson(Map<String, dynamic> json) => Vitamins(
        vitaminA: _toDouble(json['A']),
        vitaminB1: _toDouble(json['B1']),
        vitaminB2: _toDouble(json['B2']),
        vitaminB6: _toDouble(json['B6']),
        vitaminB12: _toDouble(json['B12']),
        vitaminC: _toDouble(json['C']),
        vitaminD: _toDouble(json['D']),
        vitaminE: _toDouble(json['E']),
        vitaminK: _toDouble(json['K']),
        folate: _toDouble(json['folate']),
      );

  Map<String, dynamic> toJson() => {
        'A': vitaminA,
        'B1': vitaminB1,
        'B2': vitaminB2,
        'B6': vitaminB6,
        'B12': vitaminB12,
        'C': vitaminC,
        'D': vitaminD,
        'E': vitaminE,
        'K': vitaminK,
        'folate': folate,
      };

  Vitamins operator +(Vitamins o) => Vitamins(
        vitaminA: vitaminA + o.vitaminA,
        vitaminB1: vitaminB1 + o.vitaminB1,
        vitaminB2: vitaminB2 + o.vitaminB2,
        vitaminB6: vitaminB6 + o.vitaminB6,
        vitaminB12: vitaminB12 + o.vitaminB12,
        vitaminC: vitaminC + o.vitaminC,
        vitaminD: vitaminD + o.vitaminD,
        vitaminE: vitaminE + o.vitaminE,
        vitaminK: vitaminK + o.vitaminK,
        folate: folate + o.folate,
      );
}

// Minerals model (values in mg)
class Minerals {
  final double calcium; // mg  (RDA: 1000)
  final double iron; // mg     (RDA: 18)
  final double zinc; // mg     (RDA: 11)
  final double magnesium; // mg (RDA: 420)
  final double potassium; // mg (RDA: 3400)
  final double sodium; // mg   (RDA: 2300)
  final double phosphorus; // mg (RDA: 700)

  const Minerals({
    this.calcium = 0,
    this.iron = 0,
    this.zinc = 0,
    this.magnesium = 0,
    this.potassium = 0,
    this.sodium = 0,
    this.phosphorus = 0,
  });

  factory Minerals.fromJson(Map<String, dynamic> json) => Minerals(
        calcium: _toDouble(json['calcium']),
        iron: _toDouble(json['iron']),
        zinc: _toDouble(json['zinc']),
        magnesium: _toDouble(json['magnesium']),
        potassium: _toDouble(json['potassium']),
        sodium: _toDouble(json['sodium']),
        phosphorus: _toDouble(json['phosphorus']),
      );

  Map<String, dynamic> toJson() => {
        'calcium': calcium,
        'iron': iron,
        'zinc': zinc,
        'magnesium': magnesium,
        'potassium': potassium,
        'sodium': sodium,
        'phosphorus': phosphorus,
      };

  Minerals operator +(Minerals o) => Minerals(
        calcium: calcium + o.calcium,
        iron: iron + o.iron,
        zinc: zinc + o.zinc,
        magnesium: magnesium + o.magnesium,
        potassium: potassium + o.potassium,
        sodium: sodium + o.sodium,
        phosphorus: phosphorus + o.phosphorus,
      );
}

// Complete nutritional data for a food item
class NutritionData {
  final double calories;
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final Vitamins vitamins;
  final Minerals minerals;

  const NutritionData({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.vitamins = const Vitamins(),
    this.minerals = const Minerals(),
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) => NutritionData(
        calories: _toDouble(json['calories']),
        protein: _toDouble(json['protein']),
        carbs: _toDouble(json['carbs']),
        fat: _toDouble(json['fat']),
        vitamins: json['vitamins'] != null
            ? Vitamins.fromJson(json['vitamins'] as Map<String, dynamic>)
            : const Vitamins(),
        minerals: json['minerals'] != null
            ? Minerals.fromJson(json['minerals'] as Map<String, dynamic>)
            : const Minerals(),
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'vitamins': vitamins.toJson(),
        'minerals': minerals.toJson(),
      };

  NutritionData operator +(NutritionData o) => NutritionData(
        calories: calories + o.calories,
        protein: protein + o.protein,
        carbs: carbs + o.carbs,
        fat: fat + o.fat,
        vitamins: vitamins + o.vitamins,
        minerals: minerals + o.minerals,
      );

  NutritionData scale(double factor) => NutritionData(
        calories: calories * factor,
        protein: protein * factor,
        carbs: carbs * factor,
        fat: fat * factor,
        vitamins: Vitamins(
          vitaminA: vitamins.vitaminA * factor,
          vitaminB1: vitamins.vitaminB1 * factor,
          vitaminB2: vitamins.vitaminB2 * factor,
          vitaminB6: vitamins.vitaminB6 * factor,
          vitaminB12: vitamins.vitaminB12 * factor,
          vitaminC: vitamins.vitaminC * factor,
          vitaminD: vitamins.vitaminD * factor,
          vitaminE: vitamins.vitaminE * factor,
          vitaminK: vitamins.vitaminK * factor,
          folate: vitamins.folate * factor,
        ),
        minerals: Minerals(
          calcium: minerals.calcium * factor,
          iron: minerals.iron * factor,
          zinc: minerals.zinc * factor,
          magnesium: minerals.magnesium * factor,
          potassium: minerals.potassium * factor,
          sodium: minerals.sodium * factor,
          phosphorus: minerals.phosphorus * factor,
        ),
      );
}

double _toDouble(dynamic val) {
  if (val == null) return 0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0;
  return 0;
}
