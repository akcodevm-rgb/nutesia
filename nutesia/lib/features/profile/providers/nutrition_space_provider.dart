import 'package:flutter/foundation.dart';
import '../../../core/services/api_data_service.dart';
import '../../../core/services/device_service.dart';
import '../../../shared/models/credit_wallet_model.dart';
import '../../../shared/models/member_model.dart';
import '../../../shared/models/nutrition_space_model.dart';
import '../../../shared/models/user_model.dart';

class NutritionSpaceProvider extends ChangeNotifier {
  final ApiDataService _api;

  NutritionSpaceModel? _space;
  String _activeMemberId = '';
  CreditWalletModel? _sharedWallet;
  bool _isLoading = false;
  String? _error;

  NutritionSpaceProvider({ApiDataService? api})
      : _api = api ?? ApiDataService() {
    loadSpace();
    loadWallet();
  }

  NutritionSpaceModel? get space => _space;
  String get activeMemberId => _activeMemberId;
  CreditWalletModel? get sharedWallet => _sharedWallet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MemberModel> get members => _space?.profiles ?? const [];

  MemberModel? get activeMember {
    if (_space == null || _space!.profiles.isEmpty) return null;
    if (_activeMemberId.isNotEmpty) {
      try {
        return _space!.profiles.firstWhere((p) => p.id == _activeMemberId);
      } catch (_) {}
    }
    return _space!.profiles.first;
  }

  void initFromUser(UserModel user) {
    final primaryMember = MemberModel(
      id: user.deviceId.isNotEmpty ? user.deviceId : 'primary',
      name: user.name.isNotEmpty ? user.name : 'Primary Profile',
      age: user.age,
      gender: user.gender,
      heightCm: user.heightCm,
      weightKg: user.weightKg,
      relationship: 'self',
      dailyTargets: user.dailyTargets,
      bmi: user.bmi,
      bmiCategory: user.bmiCategory,
      createdAt: user.createdAt,
    );

    if (_space == null || _space!.profiles.isEmpty) {
      _space = NutritionSpaceModel(
        id: user.deviceId.isNotEmpty ? user.deviceId : 'primary',
        ownerUserId: user.deviceId.isNotEmpty ? user.deviceId : 'primary',
        mode: 'PERSONAL',
        activeProfileId: primaryMember.id,
        profiles: [primaryMember],
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );
      _activeMemberId = primaryMember.id;
    } else {
      final existingProfiles = List<MemberModel>.from(_space!.profiles);
      final idx = existingProfiles.indexWhere((p) =>
          p.id == _activeMemberId ||
          p.relationship == 'self' ||
          p.relationship == 'owner' ||
          p.id == user.deviceId ||
          p.id == 'primary');
      if (idx != -1) {
        existingProfiles[idx] = primaryMember;
      } else {
        existingProfiles[0] = primaryMember;
      }
      _space = _space!.copyWith(profiles: existingProfiles, updatedAt: DateTime.now());
      if (_activeMemberId.isEmpty) {
        _activeMemberId = primaryMember.id;
      }
    }
    notifyListeners();
  }

  Future<void> loadSpace() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      final loadedSpace = await _api.getSpace(deviceId);
      _space = loadedSpace;

      if (loadedSpace.activeProfileId.isNotEmpty) {
        _activeMemberId = loadedSpace.activeProfileId;
      } else if (loadedSpace.profiles.isNotEmpty) {
        _activeMemberId = loadedSpace.profiles.first.id;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchActiveMember(String memberId) async {
    if (_space == null) return;
    _activeMemberId = memberId;
    final updated = _space!.copyWith(activeProfileId: memberId);
    _space = updated;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      await _api.saveSpace(deviceId, updated.toJson());
    } catch (_) {}
  }

  Future<void> addMember(MemberModel newMember) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final updatedSpace = await _api.addMember(deviceId, newMember);
      _space = updatedSpace;
      if (updatedSpace.profiles.isNotEmpty) {
        _activeMemberId = updatedSpace.profiles.last.id;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMember(MemberModel updatedMember) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final updatedSpace = await _api.updateMember(deviceId, updatedMember);
      _space = updatedSpace;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMember(String memberId) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final updatedSpace = await _api.deleteMember(deviceId, memberId);
      _space = updatedSpace;
      if (updatedSpace.profiles.isNotEmpty) {
        _activeMemberId = updatedSpace.profiles.first.id;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMode(String mode) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final updatedSpace = await _api.updateSpaceMode(deviceId, mode);
      _space = updatedSpace;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Alias methods for compatibility
  Future<void> addMemberProfile(MemberModel member) => addMember(member);
  Future<void> updateMemberProfile(MemberModel member) => updateMember(member);
  Future<void> deleteMemberProfile(String memberId) => deleteMember(memberId);
  Future<void> updateSpaceMode(String mode) => updateMode(mode);

  Future<void> loadWallet() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      _sharedWallet = await _api.getCreditWallet(deviceId);
      notifyListeners();
    } catch (e) {
      debugPrint('NutritionSpaceProvider.loadWallet error: $e');
    }
  }

  Future<void> rewardAd() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final updatedWallet = await _api.rewardAdCredit(deviceId);
      _sharedWallet = updatedWallet;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadSpace();
    await loadWallet();
  }
}
