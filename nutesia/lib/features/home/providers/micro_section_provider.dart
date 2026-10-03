import 'package:flutter/foundation.dart';

class MicroSectionProvider extends ChangeNotifier {
  bool _vitaminsExpanded = false;
  bool _mineralsExpanded = false;

  bool get vitaminsExpanded => _vitaminsExpanded;
  bool get mineralsExpanded => _mineralsExpanded;

  void toggleVitamins() {
    _vitaminsExpanded = !_vitaminsExpanded;
    notifyListeners();
  }

  void toggleMinerals() {
    _mineralsExpanded = !_mineralsExpanded;
    notifyListeners();
  }
}
