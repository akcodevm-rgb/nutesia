import 'package:flutter_test/flutter_test.dart';
import 'package:nutesia/core/models/credit_state.dart';

void main() {
  test('CreditState deserializes dual bucket JSON accurately', () {
    final json = {
      'dailyCredits': 3,
      'adCredits': 4,
      'creditBalance': 7,
      'lastDailyGrantDate': '2026-08-30',
      'rewardedAdsWatchedToday': 1,
      'lastAdRewardDate': '2026-08-30',
      'totalEarnedCredits': 10,
      'totalSpentCredits': 3,
    };

    final state = CreditState.fromJson(json);

    expect(state.dailyCredits, equals(3));
    expect(state.adCredits, equals(4));
    expect(state.creditBalance, equals(7));
    expect(state.rewardedAdsWatchedToday, equals(1));
  });

  test('CreditState copyWith updates dual bucket values correctly', () {
    const initial = CreditState(
      dailyCredits: 5,
      adCredits: 0,
      creditBalance: 5,
      lastDailyGrantDate: '2026-08-30',
      rewardedAdsWatchedToday: 0,
      lastAdRewardDate: '',
      totalEarnedCredits: 5,
      totalSpentCredits: 0,
    );

    final updated = initial.copyWith(dailyCredits: 3, adCredits: 2);

    expect(updated.dailyCredits, equals(3));
    expect(updated.adCredits, equals(2));
    expect(updated.creditBalance, equals(5));
  });
}
