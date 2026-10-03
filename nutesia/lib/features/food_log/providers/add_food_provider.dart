import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_parser.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/device_service.dart';

class AddFoodProvider extends ChangeNotifier {
  final AIService _ai;
  String _selectedMeal = 'Breakfast';
  bool _isAnalyzing = false;
  ParsedFoodResult? _parsedResult;
  Object? _parseError;
  AppError? _appError;

  AddFoodProvider({AIService? ai}) : _ai = ai ?? AIService() {
    _initDefaultMeal();
  }

  String get selectedMeal => _selectedMeal;
  bool get isAnalyzing => _isAnalyzing;
  ParsedFoodResult? get parsedResult => _parsedResult;
  Object? get parseError => _parseError;
  AppError? get appError => _appError;

  void _initDefaultMeal() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMeal = 'Breakfast';
    } else if (hour < 15) {
      _selectedMeal = 'Lunch';
    } else if (hour < 20) {
      _selectedMeal = 'Dinner';
    } else {
      _selectedMeal = 'Snacks';
    }
  }

  void setMeal(String meal) {
    _selectedMeal = meal;
    notifyListeners();
  }

  Future<ParsedFoodResult?> parseFood(String input, CreditProvider creditProvider) async {
    _isAnalyzing = true;
    _parseError = null;
    _appError = null;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      final result = await _ai.parseFood(
        deviceId: deviceId,
        input: input,
      );
      await creditProvider.refresh();
      _parsedResult = result;
      _isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _parseError = e;
      _appError = ErrorParser.parse(e);
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _isAnalyzing = false;
    _parsedResult = null;
    _parseError = null;
    _appError = null;
    _initDefaultMeal();
    notifyListeners();
  }
}
