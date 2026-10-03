import 'package:flutter/foundation.dart';
import '../services/rewarded_ad_service.dart';

class RewardedAdProvider extends ChangeNotifier {
  final RewardedAdService _service;
  bool _isLoading = false;
  bool _isReady = false;
  String? _error;

  RewardedAdProvider({RewardedAdService? service})
      : _service = service ?? RewardedAdService() {
    load();
  }

  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  String? get error => _error;

  Future<void> load() async {
    if (_service.isLoading || _service.isReady) {
      _isReady = _service.isReady;
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.load();
      _isReady = _service.isReady;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isReady = false;
      notifyListeners();
    }
  }

  Future<bool> show() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final earned = await _service.show();
      _isReady = _service.isReady;
      _isLoading = false;
      notifyListeners();
      return earned;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isReady = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
