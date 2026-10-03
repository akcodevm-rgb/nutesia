import 'package:flutter/foundation.dart';
import '../../../core/services/device_service.dart';
import '../../../core/utils/bmi_utils.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../shared/models/user_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/providers/nutrition_space_provider.dart';

class OnboardingProvider extends ChangeNotifier {
  int _currentStep = 0;
  String _name = '';
  int _age = 25;
  String _gender = 'male';
  double _heightCm = 170.0;
  double _weightKg = 70.0;
  String _goal = 'maintain';
  bool _disclaimerAccepted = false;
  bool _isSaving = false;
  String? _errorMessage;
  AppError? _appError;

  int get currentStep => _currentStep;
  String get name => _name;
  int get age => _age;
  String get gender => _gender;
  double get heightCm => _heightCm;
  double get weightKg => _weightKg;
  String get goal => _goal;
  bool get disclaimerAccepted => _disclaimerAccepted;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  AppError? get appError => _appError;

  BMIResult get bmi => BMIUtils.calculate(weightKg: _weightKg, heightCm: _heightCm);

  NutritionData get targets => BMIUtils.generateTargets(
        weightKg: _weightKg,
        heightCm: _heightCm,
        age: _age,
        gender: _gender,
        goal: _goal,
      );

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setAge(int age) {
    _age = age;
    if (_age < 18 && _goal == 'lose') {
      _goal = 'maintain';
    }
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void setHeight(double height) {
    _heightCm = height;
    notifyListeners();
  }

  void setWeight(double weight) {
    _weightKg = weight;
    notifyListeners();
  }

  void setGoal(String goal) {
    _goal = goal;
    notifyListeners();
  }

  void setDisclaimerAccepted(bool accepted) {
    _disclaimerAccepted = accepted;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _name = '';
    _age = 25;
    _gender = 'male';
    _heightCm = 170.0;
    _weightKg = 70.0;
    _goal = 'maintain';
    _disclaimerAccepted = false;
    _isSaving = false;
    _errorMessage = null;
    _appError = null;
    notifyListeners();
  }

  Future<bool> saveProfile(UserProfileProvider profileProvider, [NutritionSpaceProvider? spaceProvider]) async {
    _isSaving = true;
    _errorMessage = null;
    _appError = null;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      final bmiResult = bmi;
      final targetNutrition = targets;

      final user = UserModel(
        deviceId: deviceId,
        name: _name.trim().isEmpty ? 'User' : _name.trim(),
        age: _age,
        gender: _gender,
        heightCm: _heightCm,
        weightKg: _weightKg,
        goal: _goal,
        bmi: bmiResult.bmi,
        bmiCategory: bmiResult.category,
        dailyTargets: targetNutrition,
        createdAt: DateTime.now(),
      );

      await profileProvider.saveProfile(user);
      if (spaceProvider != null) {
        spaceProvider.initFromUser(user);
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _appError = AppErrorHandler.parse(e);
      _errorMessage = _appError!.message;
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
