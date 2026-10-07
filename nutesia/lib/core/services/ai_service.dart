import 'dart:convert';
import '../../shared/models/food_entry_model.dart';
import '../../shared/models/nutrition_model.dart';
import 'api_data_service.dart';
import 'credit_service.dart';

class ParsedFoodResult {
  final List<FoodItem> foods;
  final NutritionData totalNutrition;
  final String explanation;

  const ParsedFoodResult({
    required this.foods,
    required this.totalNutrition,
    required this.explanation,
  });
}

/// Thin client for Nutesia's server-owned AI operations. Prompts, models, credit
/// policy and any provider fallback live exclusively in the backend.
class AIService {
  AIService({ApiDataService? api}) : _api = api ?? ApiDataService();

  final ApiDataService _api;

  Future<ParsedFoodResult> parseFood({
    required String deviceId,
    required String input,
  }) async {
    String content;
    try {
      content = await _api.parseFood(deviceId: deviceId, input: input);
    } on NetworkException catch (error) {
      if (error.statusCode == 402) throw const CreditException(currentCredits: 0);
      rethrow;
    }
    final data = jsonDecode(content) as Map<String, dynamic>;
    final error = data['error'] as String?;
    if (error != null && error.isNotEmpty) throw Exception(error);

    final foods = (data['foods'] as List<dynamic>? ?? const [])
        .map((item) => _foodFromJson(item as Map<String, dynamic>))
        .toList();
    if (foods.isEmpty) {
      throw Exception('No food items were detected. Please describe what you ate.');
    }
    var total = const NutritionData();
    for (final food in foods) {
      total = total + food.nutrition;
    }
    return ParsedFoodResult(
      foods: foods,
      totalNutrition: total,
      explanation: data['explanation'] as String? ?? '',
    );
  }

  Future<Map<String, dynamic>> analyzeDeficiencies({
    required String deviceId,
    required String startDate,
    required String endDate,
  }) async {
    String content;
    try {
      content = await _api.analyzeDeficiencies(
        deviceId: deviceId, startDate: startDate, endDate: endDate,
      );
    } on NetworkException catch (error) {
      if (error.statusCode == 402) throw const CreditException(currentCredits: 0);
      rethrow;
    }
    return jsonDecode(content) as Map<String, dynamic>;
  }

  FoodItem _foodFromJson(Map<String, dynamic> item) => FoodItem(
        name: item['name'] as String? ?? 'Unknown food',
        quantity: _number(item['quantity']),
        unit: item['unit'] as String? ?? 'serving',
        baseNutrition: NutritionData(
          calories: _number(item['calories']),
          protein: _number(item['protein']),
          carbs: _number(item['carbs']),
          fat: _number(item['fat']),
          vitamins: _vitamins(item['vitamins'] as Map<String, dynamic>?),
          minerals: _minerals(item['minerals'] as Map<String, dynamic>?),
        ),
      );

  Vitamins _vitamins(Map<String, dynamic>? value) => Vitamins(
        vitaminA: _number(value?['vitaminA']), vitaminB1: _number(value?['vitaminB1']),
        vitaminB2: _number(value?['vitaminB2']), vitaminB6: _number(value?['vitaminB6']),
        vitaminB12: _number(value?['vitaminB12']), vitaminC: _number(value?['vitaminC']),
        vitaminD: _number(value?['vitaminD']), vitaminE: _number(value?['vitaminE']),
        vitaminK: _number(value?['vitaminK']), folate: _number(value?['folate']),
      );

  Minerals _minerals(Map<String, dynamic>? value) => Minerals(
        calcium: _number(value?['calcium']), iron: _number(value?['iron']),
        zinc: _number(value?['zinc']), magnesium: _number(value?['magnesium']),
        potassium: _number(value?['potassium']), sodium: _number(value?['sodium']),
        phosphorus: _number(value?['phosphorus']),
      );

  double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
