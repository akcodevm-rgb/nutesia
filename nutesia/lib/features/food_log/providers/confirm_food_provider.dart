import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/services/ai_service.dart';

class ConfirmFoodProvider extends ChangeNotifier {
  List<FoodItem> _editableFoods = [];
  String _explanation = '';
  bool _isSaving = false;
  String? _errorMessage;

  List<FoodItem> get editableFoods => _editableFoods;
  String get explanation => _explanation;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  NutritionData get totalNutrition {
    NutritionData total = const NutritionData();
    for (final f in _editableFoods) {
      total = total + f.nutrition;
    }
    return total;
  }

  void initFromParsed(ParsedFoodResult? parsed) {
    _editableFoods = parsed?.foods.map((f) => FoodItem(
          name: f.name,
          quantity: f.quantity,
          unit: f.unit,
          baseQuantity: f.baseQuantity,
          baseNutrition: f.baseNutrition,
        )).toList() ?? [];
    _explanation = parsed?.explanation ?? '';
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }

  void updateQuantity(int index, double quantity) {
    if (index >= 0 && index < _editableFoods.length) {
      _editableFoods[index].quantity = quantity;
      notifyListeners();
    }
  }

  void updateUnit(int index, String unit) {
    if (index >= 0 && index < _editableFoods.length) {
      _editableFoods[index].unit = unit;
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (_editableFoods.length > 1 && index >= 0 && index < _editableFoods.length) {
      _editableFoods.removeAt(index);
      notifyListeners();
    }
  }

  Future<bool> save({
    required String mealType,
    required String rawInput,
    required HomeProvider homeProvider,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();

      final entry = FoodEntry(
        id: const Uuid().v4(),
        deviceId: deviceId,
        date: AppDateUtils.todayKey(),
        mealType: mealType,
        foods: _editableFoods,
        totalNutrition: totalNutrition,
        explanation: _explanation,
        rawInput: rawInput,
        loggedAt: DateTime.now(),
      );

      await homeProvider.addEntry(entry);

      // Log each food item added
      for (final food in _editableFoods) {
        await AnalyticsService.instance.logFoodItemAdded(
          foodName: food.name,
          calories: food.nutrition.calories,
          mealType: mealType,
        );
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = AppErrorHandler.toHumanMessage(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
