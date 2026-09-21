import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/rewarded_ad_service.dart';

class RewardedAdState {
  final bool isLoading;
  final bool isReady;
  final String? error;

  const RewardedAdState({
    this.isLoading = false,
    this.isReady = false,
    this.error,
  });

  RewardedAdState copyWith({
    bool? isLoading,
    bool? isReady,
    String? error,
  }) {
    return RewardedAdState(
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
      error: error,
    );
  }
}

final rewardedAdProvider =
    StateNotifierProvider<RewardedAdNotifier, RewardedAdState>((ref) {
  return RewardedAdNotifier(RewardedAdService());
});

class RewardedAdNotifier extends StateNotifier<RewardedAdState> {
  final RewardedAdService _service;

  RewardedAdNotifier(this._service) : super(const RewardedAdState()) {
    load();
  }

  Future<void> load() async {
    if (_service.isLoading || _service.isReady) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.load();
      if (mounted) {
        state = RewardedAdState(isReady: _service.isReady);
      }
    } catch (e) {
      if (mounted) {
        state = RewardedAdState(error: e.toString());
      }
    }
  }

  Future<bool> show() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final earned = await _service.show();
      if (mounted) {
        state = RewardedAdState(isReady: _service.isReady);
      }
      return earned;
    } catch (e) {
      if (mounted) {
        state = RewardedAdState(error: e.toString());
      }
      return false;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
