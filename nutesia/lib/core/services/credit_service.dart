import '../models/credit_state.dart';
import 'api_data_service.dart';

class CreditException implements Exception {
  const CreditException({required this.currentCredits});
  final int currentCredits;
  @override
  String toString() => 'Not enough credits';
}

class RewardLimitException implements Exception {
  const RewardLimitException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// API-only wallet client. Credit rules and mutations are enforced by Go.
class CreditService {
  CreditService({ApiDataService? api}) : _api = api ?? ApiDataService();
  final ApiDataService _api;

  Future<CreditState> loadWallet(String deviceId) async =>
      CreditState.fromJson(await _api.getWallet(deviceId));

  Future<CreditState> addRewardedAdCredit(String deviceId) async {
    try {
      return CreditState.fromJson(await _api.rewardAd(deviceId));
    } on ApiException catch (error) {
      if (error.statusCode == 409) throw const RewardLimitException('Daily ad reward limit reached');
      rethrow;
    }
  }
}
