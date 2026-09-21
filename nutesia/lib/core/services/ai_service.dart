import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import '../../shared/models/food_entry_model.dart';
import '../../shared/models/nutrition_model.dart';
import '../../shared/models/user_model.dart';


/// The result from AI food parsing.
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

/// AI Food Parsing Service using Groq (llama-3.3-70b-versatile).
///
/// Reads GROQ_API_KEY from .env file.
///
/// TO SWITCH TO FIREBASE CLOUD FUNCTIONS IN PRODUCTION:
///   Replace [_callGroq] with an http.post to your Cloud Function URL.
///   The Cloud Function can proxy the same request securely.
class AIService {
  static const String _model = 'llama-3.3-70b-versatile';
  static const double _temperature = 0.3;
  static const int _maxTokens = 1024;

  String get _apiKey => AppConfig.get('GROQ_API_KEY');

  static const String _systemPrompt = '''
You are NutesiaAI, a precise nutrition analysis assistant.
When the user describes food they ate, you must:
1. Break the input into individual food items.
2. Estimate realistic quantities if not specified.
3. Look up accurate nutritional values for the specified or estimated quantity of each food item. You MUST scale/multiply all nutritional values (calories, protein, carbs, fat, vitamins, minerals) by the quantity! (For example, if 1 piece of Masala Dosa has 400 calories, then 3 pieces of Masala Dosa must have 1200 calories. You MUST return 1200.0 calories for 3 pieces of Masala Dosa, not 400.0).
4. Return ONLY a valid JSON object — no extra text, no markdown, no explanation before or after.
5. Use USDA standard average nutritional values.
6. If the input is NOT related to food or beverages (for example: generic greetings, questions, or random words like "hello", "keyboard", "how are you"), you MUST return a JSON object with an "error" key explaining why the input is invalid, keeping "foods" empty and "explanation" empty.

Required JSON format:
{
  "foods": [
    {
      "name": "Food Item Name",
      "quantity": 1.0,
      "unit": "serving|grams|pieces|ml|bowl|cup|slice",
      "calories": 200.0,
      "protein": 10.0,
      "carbs": 25.0,
      "fat": 8.0,
      "vitamins": {
        "vitaminA": 0.0,
        "vitaminB1": 0.0,
        "vitaminB2": 0.0,
        "vitaminB6": 0.0,
        "vitaminB12": 0.0,
        "vitaminC": 0.0,
        "vitaminD": 0.0,
        "vitaminE": 0.0,
        "vitaminK": 0.0,
        "folate": 0.0
      },
      "minerals": {
        "calcium": 0.0,
        "iron": 0.0,
        "zinc": 0.0,
        "magnesium": 0.0,
        "potassium": 0.0,
        "sodium": 0.0,
        "phosphorus": 0.0
      }
    }
  ],
  "explanation": "A brief 1-2 sentence health insight about this meal.",
  "error": "If the input is not food, describe the error here (e.g. 'This input doesn't look like food. Please describe what you ate.'), otherwise keep it empty or omit it."
}

Rules:
- All numeric values MUST be type double (e.g. 10.0 not 10).
- Vitamin A, K units are micrograms (mcg). All others are mg or mcg as standard.
- Calories are kilocalories.
- The total calories for any food item MUST be mathematically consistent with its macronutrients: calories = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0). Double check this math before returning the response.
- For complex/cooked regional dishes (e.g. Masala Dosa, Biryani, Curries, Pizza), ensure realistic ratios of fat, carbs, and protein. (For example, a single masala dosa typically has ~350-400 kcal, ~7-9g protein, ~50g carbs, and ~15-20g fat due to cooking oils/ghee and potato filling. Thus, 3 pieces should be around 1100-1200 kcal, with ~24g protein, ~145-150g carbs, and ~50-55g fat).
- If you don't know an exact value, use a reasonable estimate. Never use null.
- The "explanation" field must be a non-empty string with health insights.
- Return ONLY the raw JSON. No ```json fences. No text before or after the JSON.
- If the input is not food or is irrelevant, return: {"foods": [], "explanation": "", "error": "This input doesn't look like food. Please describe what you ate."}
''';

  bool _isObviousNonFood(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return true;
    final nonFoodWords = {
      'hello', 'hi', 'hey', 'howdy', 'greetings', 'yo',
      'how', 'what', 'who', 'where', 'why',
      'keyboard', 'mouse', 'computer', 'screen', 'phone', 'table', 'chair',
      'test', 'testing', 'abc', 'xyz', '123'
    };
    return nonFoodWords.contains(lower);
  }

  Future<ParsedFoodResult> parseFood(String input) async {
    log('AIService.parseFood: Input received: "$input"');
    if (_isObviousNonFood(input)) {
      throw Exception("This doesn't look like food. Please describe what you ate.");
    }

    if (_apiKey.isEmpty || _apiKey == 'your_groq_api_key_here') {
      log('NutesiaAI: No GROQ_API_KEY found, using mock data');
      return _mockParse(input);
    }

    try {
      final rawJson = await _callGroq(input);
      if (rawJson == null) throw Exception('Empty response from AI');
      return _parseGroqResponse(rawJson, input);
    } catch (e) {
      log('NutesiaAI: Groq call failed ($e), falling back to mock');
      return _mockParse(input);
    }
  }

  /// Calls the Groq Chat Completions API.
  Future<String?> _callGroq(String userInput) async {
    log('AIService._callGroq: Making API call for input: "$userInput"');
    final endpoint = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final body = {
      'model': _model,
      'temperature': _temperature,
      'max_tokens': _maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': userInput},
      ],
    };

    try {
      final response = await http.post(
        endpoint,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      log('AIService._callGroq: Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        log('AIService._callGroq: Response content length: ${content?.length ?? 0}');
        return content;
      } else {
        log('Groq API Error: ${response.statusCode} ${response.body}');
        throw Exception('Groq API returned ${response.statusCode}');
      }
    } catch (e) {
      log('AIService._callGroq: Exception during API call: $e');
      rethrow;
    }
  }

  /// Parses the Groq JSON response into a [ParsedFoodResult].
  ParsedFoodResult _parseGroqResponse(String rawJson, String originalInput) {
    log('AIService._parseGroqResponse: Parsing JSON response for input: "$originalInput"');
    try {
      final Map<String, dynamic> data = json.decode(rawJson);
      log('AIService._parseGroqResponse: JSON decoded successfully');

      if (data.containsKey('error') && data['error'] != null && (data['error'] as String).isNotEmpty) {
        throw Exception(data['error']);
      }

      final List<dynamic> rawFoods = data['foods'] as List<dynamic>? ?? [];
      final String explanation = data['explanation'] as String? ?? '';

      log('AIService._parseGroqResponse: Found ${rawFoods.length} foods, explanation length: ${explanation.length}');

      if (rawFoods.isEmpty) {
        throw Exception("No food items were detected in your input. Please describe what you ate.");
      }

      final foods = rawFoods.map((f) => _foodItemFromJson(f as Map<String, dynamic>)).toList();

      NutritionData total = const NutritionData();
      for (final food in foods) {
        total = total + food.nutrition;
      }

      log('AIService._parseGroqResponse: Total nutrition - calories: ${total.calories}, protein: ${total.protein}');
      return ParsedFoodResult(
        foods: foods,
        totalNutrition: total,
        explanation: explanation.isNotEmpty
            ? explanation
            : _buildFallbackExplanation(foods, total),
      );
    } catch (e) {
      log('AIService._parseGroqResponse: Error parsing JSON: $e');
      log('AIService._parseGroqResponse: Raw JSON: $rawJson');
      rethrow;
    }
  }

  FoodItem _foodItemFromJson(Map<String, dynamic> f) {
    return FoodItem(
      name: f['name'] as String? ?? 'Unknown food',
      quantity: _toDouble(f['quantity']),
      unit: f['unit'] as String? ?? 'serving',
      baseNutrition: NutritionData(
        calories: _toDouble(f['calories']),
        protein: _toDouble(f['protein']),
        carbs: _toDouble(f['carbs']),
        fat: _toDouble(f['fat']),
        vitamins: _vitaminsFromJson(f['vitamins'] as Map<String, dynamic>?),
        minerals: _mineralsFromJson(f['minerals'] as Map<String, dynamic>?),
      ),
    );
  }

  Vitamins _vitaminsFromJson(Map<String, dynamic>? v) {
    if (v == null) return const Vitamins();
    return Vitamins(
      vitaminA: _toDouble(v['vitaminA']),
      vitaminB1: _toDouble(v['vitaminB1']),
      vitaminB2: _toDouble(v['vitaminB2']),
      vitaminB6: _toDouble(v['vitaminB6']),
      vitaminB12: _toDouble(v['vitaminB12']),
      vitaminC: _toDouble(v['vitaminC']),
      vitaminD: _toDouble(v['vitaminD']),
      vitaminE: _toDouble(v['vitaminE']),
      vitaminK: _toDouble(v['vitaminK']),
      folate: _toDouble(v['folate']),
    );
  }

  Minerals _mineralsFromJson(Map<String, dynamic>? m) {
    if (m == null) return const Minerals();
    return Minerals(
      calcium: _toDouble(m['calcium']),
      iron: _toDouble(m['iron']),
      zinc: _toDouble(m['zinc']),
      magnesium: _toDouble(m['magnesium']),
      potassium: _toDouble(m['potassium']),
      sodium: _toDouble(m['sodium']),
      phosphorus: _toDouble(m['phosphorus']),
    );
  }

  /// Safe int/double/string-to-double converter.
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  // ─── Fallback Mock ────────────────────────────────────────────────────────
  // Used when: API key not set, or Groq call fails.

  ParsedFoodResult _mockParse(String input) {
    log('AIService._mockParse: Using mock parser for input: "$input"');
    final lower = input.toLowerCase();
    final foods = <FoodItem>[];

    // Eggs
    if (lower.contains('egg') || lower.contains('eggs')) {
      final qty = _extractNumber(lower, ['egg', 'eggs']) ?? 2;
      log('AIService._mockParse: Detected eggs, quantity: $qty');
      final name = lower.contains('scramble')
          ? 'Scrambled Eggs'
          : lower.contains('omelette') || lower.contains('omelet')
              ? 'Omelette'
              : 'Boiled Eggs';
      foods.add(FoodItem(
        name: name,
        quantity: qty.toDouble(),
        unit: 'pieces',
        baseNutrition: NutritionData(
          calories: 77.0 * qty,
          protein: 6.3 * qty,
          carbs: 0.6 * qty,
          fat: 5.3 * qty,
          vitamins: Vitamins(
            vitaminA: 270.0 * qty,
            vitaminB12: 0.89 * qty,
            vitaminD: 2.0 * qty,
            vitaminE: 0.5 * qty,
            vitaminB2: 0.24 * qty,
          ),
          minerals: Minerals(
            calcium: 28.0 * qty,
            iron: 0.9 * qty,
            zinc: 0.6 * qty,
            phosphorus: 97.0 * qty,
          ),
        ),
      ));
    }

    // Chicken Biryani
    if (lower.contains('biryani')) {
      foods.add(FoodItem(
        name: lower.contains('mutton')
            ? 'Mutton Biryani'
            : lower.contains('veg')
                ? 'Veg Biryani'
                : 'Chicken Biryani',
        quantity: 300,
        unit: 'grams',
        baseNutrition: const NutritionData(
          calories: 490,
          protein: 28,
          carbs: 55,
          fat: 16,
          vitamins: Vitamins(vitaminA: 45.0, vitaminB12: 0.3, vitaminC: 3.0),
          minerals: Minerals(calcium: 40.0, iron: 2.1, zinc: 2.5, potassium: 320.0),
        ),
      ));
    }

    // Dal
    if (lower.contains('dal') || lower.contains('dhal') || lower.contains('lentil')) {
      foods.add(FoodItem(
        name: 'Dal (Lentil Curry)',
        quantity: 200,
        unit: 'grams',
        baseNutrition: const NutritionData(
          calories: 176,
          protein: 13,
          carbs: 28,
          fat: 2,
          vitamins: Vitamins(vitaminB1: 0.2, folate: 90.0, vitaminC: 3.0),
          minerals: Minerals(iron: 3.3, calcium: 38.0, zinc: 1.8, potassium: 369.0),
        ),
      ));
    }

    // Rice
    if (lower.contains('rice') && !lower.contains('biryani')) {
      foods.add(FoodItem(
        name: 'Cooked Rice',
        quantity: 200,
        unit: 'grams',
        baseNutrition: const NutritionData(
          calories: 260,
          protein: 5.4,
          carbs: 57,
          fat: 0.4,
          vitamins: Vitamins(vitaminB1: 0.02, folate: 4.0),
          minerals: Minerals(calcium: 10.0, iron: 0.4, magnesium: 19.0, phosphorus: 68.0),
        ),
      ));
    }

    // Roti
    if (lower.contains('roti') || lower.contains('chapati')) {
      final qty = _extractNumber(lower, ['roti', 'chapati']) ?? 2;
      foods.add(FoodItem(
        name: 'Roti / Chapati',
        quantity: qty.toDouble(),
        unit: 'pieces',
        baseNutrition: NutritionData(
          calories: 71.0 * qty,
          protein: 2.7 * qty,
          carbs: 15.0 * qty,
          fat: 0.4 * qty,
          vitamins: Vitamins(vitaminB1: 0.07 * qty, folate: 14.0 * qty),
          minerals: Minerals(calcium: 14.0 * qty, iron: 0.8 * qty, phosphorus: 33.0 * qty),
        ),
      ));
    }

    // Chicken (generic)
    if (lower.contains('chicken') && !lower.contains('biryani')) {
      final isFried = lower.contains('fried');
      foods.add(FoodItem(
        name: isFried ? 'Fried Chicken' : lower.contains('curry') ? 'Chicken Curry' : 'Grilled Chicken',
        quantity: 150,
        unit: 'grams',
        baseNutrition: NutritionData(
          calories: isFried ? 320 : 248,
          protein: isFried ? 30 : 38,
          carbs: isFried ? 10 : 0,
          fat: isFried ? 18 : 9.4,
          vitamins: const Vitamins(vitaminB12: 0.3, vitaminB6: 1.0, vitaminD: 0.2),
          minerals: const Minerals(iron: 1.1, zinc: 2.7, potassium: 440.0, phosphorus: 280.0),
        ),
      ));
    }

    // Milk
    if (lower.contains('milk')) {
      final qty = lower.contains('glass') ? 250 : 200;
      foods.add(FoodItem(
        name: 'Whole Milk',
        quantity: qty.toDouble(),
        unit: 'ml',
        baseNutrition: NutritionData(
          calories: qty * 0.61,
          protein: qty * 0.032,
          carbs: qty * 0.048,
          fat: qty * 0.032,
          vitamins: Vitamins(
            vitaminA: qty.toDouble() * 0.45,
            vitaminB12: qty.toDouble() * 0.0044,
            vitaminD: qty.toDouble() * 0.013,
          ),
          minerals: Minerals(
            calcium: qty.toDouble() * 1.22,
            phosphorus: qty.toDouble() * 0.96,
            potassium: qty.toDouble() * 1.5,
          ),
        ),
      ));
    }

    // Banana
    if (lower.contains('banana')) {
      final qty = _extractNumber(lower, ['banana', 'bananas']) ?? 1;
      foods.add(FoodItem(
        name: 'Banana',
        quantity: qty.toDouble(),
        unit: 'medium',
        baseNutrition: NutritionData(
          calories: 89.0 * qty,
          protein: 1.1 * qty,
          carbs: 23.0 * qty,
          fat: 0.3 * qty,
          vitamins: Vitamins(vitaminB6: 0.4 * qty, vitaminC: 8.7 * qty, folate: 20.0 * qty),
          minerals: Minerals(potassium: 358.0 * qty, magnesium: 27.0 * qty),
        ),
      ));
    }

    // Oats
    if (lower.contains('oat') || lower.contains('oatmeal') || lower.contains('porridge')) {
      foods.add(FoodItem(
        name: 'Oatmeal',
        quantity: 1,
        unit: 'bowl',
        baseNutrition: const NutritionData(
          calories: 166,
          protein: 5.9,
          carbs: 28,
          fat: 3.6,
          vitamins: Vitamins(vitaminB1: 0.17, folate: 14.0),
          minerals: Minerals(iron: 2.0, magnesium: 61.0, phosphorus: 180.0, potassium: 143.0),
        ),
      ));
    }

    // Idli
    if (lower.contains('idli')) {
      final qty = _extractNumber(lower, ['idli']) ?? 3;
      foods.add(FoodItem(
        name: 'Idli',
        quantity: qty.toDouble(),
        unit: 'pieces',
        baseNutrition: NutritionData(
          calories: 39.0 * qty,
          protein: 1.8 * qty,
          carbs: 7.8 * qty,
          fat: 0.2 * qty,
          vitamins: Vitamins(folate: 5.0 * qty, vitaminB1: 0.03 * qty),
          minerals: Minerals(calcium: 8.0 * qty, iron: 0.3 * qty),
        ),
      ));
    }

    // Fallback
    if (foods.isEmpty) {
      final label = input.trim().length > 40 ? '${input.trim().substring(0, 40)}...' : input.trim();
      foods.add(FoodItem(
        name: label,
        quantity: 1,
        unit: 'serving',
        baseNutrition: const NutritionData(
          calories: 220,
          protein: 8,
          carbs: 28,
          fat: 7,
          vitamins: Vitamins(vitaminC: 5.0, vitaminA: 50.0, vitaminB12: 0.2),
          minerals: Minerals(calcium: 50.0, iron: 1.0, potassium: 200.0),
        ),
      ));
    }

    NutritionData total = const NutritionData();
    for (final f in foods) {
      total = total + f.nutrition;
    }

    log('AIService._mockParse: Returning ${foods.length} foods, total calories: ${total.calories}');
    return ParsedFoodResult(
      foods: foods,
      totalNutrition: total,
      explanation: _buildFallbackExplanation(foods, total),
    );
  }

  // ─── Deficiency Analysis ──────────────────────────────────────────────────

  static const String _deficiencySystemPrompt = '''
You are NutesiaAI, a clinical nutrition specialist.
You are given a user's profile and their average daily nutrient intake (vitamins and minerals) over a period (7 days or 30 days), compared to their Recommended Daily Allowance (RDA) targets.

Analyze this data and return a JSON object estimating potential vitamin and mineral deficiency risks, symptoms they might experience, and highly specific dietary recommendations to resolve these deficiencies.

Required JSON format:
{
  "riskLevel": "Low|Moderate|High",
  "summary": "A 2-3 sentence clinical summary of the user's nutritional health.",
  "deficiencies": [
    {
      "nutrient": "Iron|Vitamin D|Vitamin C|etc.",
      "probability": "Low|Moderate|High",
      "symptoms": ["Symptom 1", "Symptom 2"],
      "explanation": "Brief explanation of why they are at risk and how the intake compares to the target."
    }
  ],
  "recommendations": [
    {
      "food": "Food Name (e.g. Spinach, Salmon)",
      "reason": "Explain why this food helps (e.g. Rich in iron, containing Vitamin C to help absorption).",
      "tips": "Practical tip on how to consume it."
    }
  ]
}

Rules:
- Identify only nutrients that are significantly below the target RDA (e.g. below 75%).
- Do not list nutrients that are adequate.
- Provide practical, action-oriented food suggestions (not supplement brands).
- Return ONLY valid JSON, no explanations before or after.
''';

  /// Predicts vitamin/mineral deficiency risks based on user profile and average nutrient intakes.
  Future<Map<String, dynamic>> analyzeDeficiencies({
    required UserModel user,
    required String period, // '7 Days' or '30 Days'
    required Map<String, double> averageIntake,
    required Map<String, double> targets,
    required List<String> topFoods,
  }) async {
    log('AIService.analyzeDeficiencies: Running analysis for ${user.name}');
    if (_apiKey.isEmpty || _apiKey == 'your_groq_api_key_here') {
      log('NutesiaAI: No GROQ_API_KEY found, using mock deficiency analysis');
      return _mockDeficiencyAnalysis(user, period, averageIntake, targets);
    }

    final inputBuffer = StringBuffer();
    inputBuffer.writeln('User Profile:');
    inputBuffer.writeln('- Name: ${user.name}');
    inputBuffer.writeln('- Age: ${user.age}');
    inputBuffer.writeln('- Gender: ${user.gender}');
    inputBuffer.writeln('- Goal: ${user.goal}');
    inputBuffer.writeln('\nPeriod analyzed: $period');
    inputBuffer.writeln('\nTop Foods Eaten: ${topFoods.join(', ')}');
    inputBuffer.writeln('\nNutrient intake (average daily vs target):');
    averageIntake.forEach((nutrient, avg) {
      final target = targets[nutrient] ?? 0;
      inputBuffer.writeln('- $nutrient: ${avg.toStringAsFixed(1)} / ${target.toStringAsFixed(1)}');
    });

    final body = {
      'model': _model,
      'temperature': 0.2,
      'max_tokens': 1500,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': _deficiencySystemPrompt},
        {'role': 'user', 'content': inputBuffer.toString()},
      ],
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return json.decode(content) as Map<String, dynamic>;
      } else {
        throw Exception('Groq API returned ${response.statusCode}');
      }
    } catch (e) {
      log('AIService.analyzeDeficiencies: API call failed ($e), falling back to mock');
      return _mockDeficiencyAnalysis(user, period, averageIntake, targets);
    }
  }

  /// Backup logic to calculate deficiency risk based on actual data when API key is missing/fails.
  Map<String, dynamic> _mockDeficiencyAnalysis(
    UserModel user,
    String period,
    Map<String, double> averageIntake,
    Map<String, double> targets,
  ) {
    final deficiencies = <Map<String, dynamic>>[];
    final recommendations = <Map<String, dynamic>>[];
    
    // Check key nutrients
    averageIntake.forEach((nutrient, avg) {
      final target = targets[nutrient] ?? 0;
      if (target > 0 && (avg / target) < 0.75) {
        final pct = (avg / target * 100).round();
        final keyName = nutrient.toLowerCase();
        if (keyName.contains('vitaminc') || keyName.contains('c')) {
          if (keyName.contains('c') && !keyName.contains('calcium') && !keyName.contains('zinc')) {
            deficiencies.add({
              'nutrient': 'Vitamin C',
              'probability': 'Moderate',
              'symptoms': ['Fatigue', 'Easy bruising', 'Weak immune system', 'Bleeding gums'],
              'explanation': 'Your average Vitamin C intake is only $pct% of the recommended allowance. Vitamin C is vital for immune function and iron absorption.'
            });
            recommendations.add({
              'food': 'Oranges & Bell Peppers',
              'reason': 'Oranges, lemons, strawberries, and red/yellow bell peppers are extremely high in Vitamin C.',
              'tips': 'Eat fresh citrus fruits as a mid-day snack, or add bell peppers to your lunch salads.'
            });
          }
        }
        
        if (keyName.contains('iron')) {
          deficiencies.add({
            'nutrient': 'Iron',
            'probability': 'High',
            'symptoms': ['Fatigue', 'Pale skin', 'Cold hands and feet', 'Shortness of breath'],
            'explanation': 'Your average Iron intake is at $pct% of the recommended allowance. Iron is essential for producing hemoglobin, which carries oxygen in the blood.'
          });
          recommendations.add({
            'food': 'Spinach & Lentils',
            'reason': 'Spinach is a great plant-based source of iron, and dal/lentils provide a substantial iron boost.',
            'tips': 'Cook spinach with tomatoes or a squeeze of lemon. Vitamin C increases plant-based iron absorption by up to 300%.'
          });
        }
        
        if (keyName.contains('calcium')) {
          deficiencies.add({
            'nutrient': 'Calcium',
            'probability': 'Moderate',
            'symptoms': ['Muscle cramps', 'Numbness in hands/feet', 'Weak nails', 'Lethargy'],
            'explanation': 'Your average Calcium intake is only $pct% of your target. Calcium is key for strong bones, muscle function, and nerve signaling.'
          });
          recommendations.add({
            'food': 'Yogurt, Milk & Chia Seeds',
            'reason': 'Dairy products like milk and yogurt are high in bioavailable calcium. Chia seeds are a great plant-based alternative.',
            'tips': 'Include a bowl of curd/yogurt with lunch, or drink a glass of milk before bed.'
          });
        }
        
        if (keyName.contains('vitamind') || keyName.contains('d')) {
          if (keyName.contains('d') && !keyName.contains('sodium') && !keyName.contains('folate')) {
            deficiencies.add({
              'nutrient': 'Vitamin D',
              'probability': 'Moderate',
              'symptoms': ['Bone pain', 'Muscle weakness', 'Mood changes', 'Frequent infections'],
              'explanation': 'Your average Vitamin D intake is at $pct% of target. Vitamin D helps your body absorb calcium and is vital for bone and immune health.'
            });
            recommendations.add({
              'food': 'Egg Yolks & Mushrooms',
              'reason': 'Very few foods naturally contain Vitamin D, but egg yolks and sun-exposed mushrooms are decent sources.',
              'tips': 'Try to get 10-15 minutes of early morning sunlight daily, and consume whole eggs instead of just whites.'
            });
          }
        }
        
        if (keyName.contains('magnesium')) {
          deficiencies.add({
            'nutrient': 'Magnesium',
            'probability': 'Low',
            'symptoms': ['Muscle twitches', 'Fatigue', 'Muscle weakness', 'High blood pressure'],
            'explanation': 'Your average Magnesium intake is at $pct% of the target. Magnesium supports muscle and nerve function, and energy production.'
          });
          recommendations.add({
            'food': 'Almonds & Dark Chocolate',
            'reason': 'Almonds, cashews, and dark chocolate are excellent sources of magnesium.',
            'tips': 'Eat a handful of soaked almonds daily in the morning.'
          });
        }
      }
    });

    if (deficiencies.isEmpty) {
      return {
        'riskLevel': 'Low',
        'summary': 'Great job! Your micronutrient intake looks excellent. You are meeting your daily targets for all tracked vitamins and minerals over the analyzed period.',
        'deficiencies': [],
        'recommendations': [
          {
            'food': 'Varied Whole Foods',
            'reason': 'Maintaining a diverse diet of fresh fruits, vegetables, grains, and proteins ensures continued nutritional balance.',
            'tips': 'Keep eating a rainbow of foods daily to sustain your micronutrient levels.'
          }
        ]
      };
    }

    final riskLevel = deficiencies.length >= 3 ? 'High' : 'Moderate';
    return {
      'riskLevel': riskLevel,
      'summary': 'Based on your $period nutritional logs, we detected a few micronutrient gaps. You are currently under-consuming some key vitamins/minerals, placing you at a $riskLevel risk for related deficiencies.',
      'deficiencies': deficiencies,
      'recommendations': recommendations.take(3).toList(),
    };
  }

  int? _extractNumber(String text, List<String> keywords) {
    for (final kw in keywords) {
      for (final p in [
        RegExp(r'(\d+)\s*' + kw),
        RegExp(kw + r'\s*[x×]\s*(\d+)'),
        RegExp(r'(\d+)\s+' + kw),
      ]) {
        final m = p.firstMatch(text);
        if (m != null) return int.tryParse(m.group(1)!);
      }
    }
    return null;
  }

  String _buildFallbackExplanation(List<FoodItem> foods, NutritionData total) {
    final names = foods.map((f) => f.name).join(' + ');
    final insights = <String>[];

    if (total.protein >= 30) insights.add('excellent protein source');
    else if (total.protein >= 15) insights.add('good protein content');
    if (total.carbs > 60) insights.add('high in carbohydrates for energy');
    if (total.fat < 5) insights.add('low fat');
    else if (total.fat > 20) insights.add('moderate fat — watch portions');
    if (total.minerals.iron > 3) insights.add('rich in iron');
    if (total.vitamins.vitaminC > 30) insights.add('high in Vitamin C');
    if (total.calories < 250) insights.add('light & low calorie');
    else if (total.calories > 700) insights.add('energy-dense — portion mindfully');
    if (total.minerals.calcium > 200) insights.add('calcium-rich');

    final insightStr = insights.isEmpty ? 'provides a balanced mix of nutrients' : insights.join(', ');
    return '$names — $insightStr. Total: ${total.calories.round()} kcal.';
  }
}

