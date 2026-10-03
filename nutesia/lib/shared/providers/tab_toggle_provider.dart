import 'package:flutter/foundation.dart';

class TabToggleProvider extends ChangeNotifier {
  bool _isSecondary = false;

  TabToggleProvider({bool initialSecondary = false}) : _isSecondary = initialSecondary;

  bool get isSecondary => _isSecondary;
  bool get isPrimary => !_isSecondary;

  void selectPrimary() {
    if (_isSecondary) {
      _isSecondary = false;
      notifyListeners();
    }
  }

  void selectSecondary() {
    if (!_isSecondary) {
      _isSecondary = true;
      notifyListeners();
    }
  }

  void toggle() {
    _isSecondary = !_isSecondary;
    notifyListeners();
  }
}
