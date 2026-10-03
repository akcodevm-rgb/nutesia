import 'package:flutter/foundation.dart';
import '../../core/utils/error_handler.dart';
import '../../features/profile/providers/nutrition_space_provider.dart';
import '../models/member_model.dart';

class ManageMembersProvider extends ChangeNotifier {
  final MemberModel? initialMember;

  String _name = '';
  int _age = 10;
  String _gender = 'female';
  String _relationship = 'child';
  String _height = '145';
  String _weight = '40';
  String _goal = 'maintain_weight';
  bool _isSubmitting = false;
  String? _errorMessage;

  ManageMembersProvider({this.initialMember}) {
    if (initialMember != null) {
      _name = initialMember!.name;
      _age = initialMember!.age > 0 ? initialMember!.age : 10;
      _gender = initialMember!.gender.isNotEmpty ? initialMember!.gender : 'female';
      _relationship = initialMember!.relationship.isNotEmpty ? initialMember!.relationship : 'child';
      _height = initialMember!.heightCm > 0 ? initialMember!.heightCm.round().toString() : '145';
      _weight = initialMember!.weightKg > 0 ? initialMember!.weightKg.round().toString() : '40';
      _goal = initialMember!.goal.isNotEmpty ? initialMember!.goal : 'maintain_weight';
    }
  }

  bool get isEditMode => initialMember != null;
  String get name => _name;
  int get age => _age;
  String get gender => _gender;
  String get relationship => _relationship;
  String get height => _height;
  String get weight => _weight;
  String get goal => _goal;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void setName(String val) {
    _name = val;
    notifyListeners();
  }

  void setAge(int val) {
    _age = val;
    notifyListeners();
  }

  void setGender(String val) {
    _gender = val;
    notifyListeners();
  }

  void setRelationship(String val) {
    _relationship = val;
    notifyListeners();
  }

  void setHeight(String val) {
    _height = val;
    notifyListeners();
  }

  void setWeight(String val) {
    _weight = val;
    notifyListeners();
  }

  void setGoal(String val) {
    _goal = val;
    notifyListeners();
  }

  void reset() {
    if (initialMember != null) {
      _name = initialMember!.name;
      _age = initialMember!.age;
      _gender = initialMember!.gender;
      _relationship = initialMember!.relationship;
      _height = initialMember!.heightCm.round().toString();
      _weight = initialMember!.weightKg.round().toString();
      _goal = initialMember!.goal;
    } else {
      _name = '';
      _age = 10;
      _gender = 'female';
      _relationship = 'child';
      _height = '145';
      _weight = '40';
      _goal = 'maintain_weight';
    }
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submit(NutritionSpaceProvider spaceProvider) async {
    if (_name.trim().isEmpty) {
      _errorMessage = 'Please enter name';
      notifyListeners();
      return false;
    }

    if (_age <= 0 || _age > 120) {
      _errorMessage = 'Please enter a valid age between 1 and 120';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditMode && initialMember != null) {
        final updatedMember = initialMember!.copyWith(
          name: _name.trim(),
          relationship: _relationship,
          age: _age,
          gender: _gender,
          heightCm: double.tryParse(_height) ?? initialMember!.heightCm,
          weightKg: double.tryParse(_weight) ?? initialMember!.weightKg,
          goal: _goal,
        );

        await spaceProvider.updateMemberProfile(updatedMember);
      } else {
        final member = MemberModel(
          id: '',
          name: _name.trim(),
          relationship: _relationship,
          dateOfBirth: '',
          age: _age,
          gender: _gender,
          heightCm: double.tryParse(_height) ?? 145.0,
          weightKg: double.tryParse(_weight) ?? 40.0,
          goal: _goal,
          createdAt: DateTime.now(),
        );

        await spaceProvider.addMemberProfile(member);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = AppErrorHandler.toHumanMessage(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(NutritionSpaceProvider spaceProvider) async {
    if (initialMember == null || initialMember!.id.isEmpty) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await spaceProvider.deleteMemberProfile(initialMember!.id);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = AppErrorHandler.toHumanMessage(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
