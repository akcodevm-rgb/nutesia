import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_parser.dart';
import '../models/credit_state.dart';
import '../services/credit_service.dart';
import '../services/device_service.dart';

class CreditProvider extends ChangeNotifier {
  final CreditService _service;
  CreditState? _wallet;
  bool _isLoading = false;
  String? _error;
  AppError? _appError;
  String? _deviceId;

  CreditProvider({CreditService? service})
      : _service = service ?? CreditService() {
    loadWallet();
  }

  CreditState? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppError? get appError => _appError;
  int get creditBalance => _wallet?.creditBalance ?? 0;
  int get dailyCredits => _wallet?.dailyCredits ?? 0;
  int get adCredits => _wallet?.adCredits ?? 0;

  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    _appError = null;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      _wallet = await _service.loadWallet(deviceId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _appError = ErrorParser.parse(e);
      _error = _appError!.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      _wallet = await _service.loadWallet(deviceId);
      _error = null;
      _appError = null;
      notifyListeners();
    } catch (e) {
      _appError = ErrorParser.parse(e);
      _error = _appError!.message;
      notifyListeners();
    }
  }

  Future<void> addRewardedAdCredit() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      _wallet = await _service.addRewardedAdCredit(deviceId);
      _error = null;
      _appError = null;
      notifyListeners();
    } catch (e) {
      _appError = ErrorParser.parse(e);
      _error = _appError!.message;
      notifyListeners();
      rethrow;
    }
  }
}
