import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/credit_state.dart';
import '../services/credit_service.dart';
import '../services/device_service.dart';

final creditServiceProvider = Provider<CreditService>((ref) => CreditService());

final deviceIdProvider =
    FutureProvider<String>((ref) => DeviceService.getDeviceId());

final creditProvider =
    StateNotifierProvider<CreditNotifier, AsyncValue<CreditState>>((ref) {
  return CreditNotifier(ref.read(creditServiceProvider));
});

class CreditNotifier extends StateNotifier<AsyncValue<CreditState>> {
  final CreditService _service;
  String? _deviceId;

  CreditNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _deviceId = await DeviceService.getDeviceId();
      final stateAfterGrant =
          await _service.grantDailyCreditsIfNeeded(_deviceId!);
      if (mounted) state = AsyncValue.data(stateAfterGrant);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<String> _requireDeviceId() async {
    _deviceId ??= await DeviceService.getDeviceId();
    return _deviceId!;
  }

  Future<void> refresh() async {
    final deviceId = await _requireDeviceId();
    state = AsyncValue.data(await _service.grantDailyCreditsIfNeeded(deviceId));
  }

  Future<void> spend({
    required int amount,
    required String reason,
  }) async {
    final deviceId = await _requireDeviceId();
    final granted = await _service.grantDailyCreditsIfNeeded(deviceId);
    if (mounted) state = AsyncValue.data(granted);
    final updated = await _service.spendCredits(
      deviceId: deviceId,
      amount: amount,
      reason: reason,
    );
    if (mounted) state = AsyncValue.data(updated);
  }

  Future<void> refund({
    required int amount,
    required String reason,
  }) async {
    final deviceId = await _requireDeviceId();
    final updated = await _service.refundCredits(
      deviceId: deviceId,
      amount: amount,
      reason: reason,
    );
    if (mounted) state = AsyncValue.data(updated);
  }

  Future<void> addRewardedAdCredit() async {
    final deviceId = await _requireDeviceId();
    final granted = await _service.grantDailyCreditsIfNeeded(deviceId);
    if (mounted) state = AsyncValue.data(granted);
    final updated = await _service.addRewardedAdCredit(deviceId);
    if (mounted) state = AsyncValue.data(updated);
  }
}
