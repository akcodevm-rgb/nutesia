class CreditState {
  final int creditBalance;
  final String lastDailyGrantDate;
  final int rewardedAdsWatchedToday;
  final String lastAdRewardDate;
  final int totalEarnedCredits;
  final int totalSpentCredits;

  const CreditState({
    required this.creditBalance,
    required this.lastDailyGrantDate,
    required this.rewardedAdsWatchedToday,
    required this.lastAdRewardDate,
    required this.totalEarnedCredits,
    required this.totalSpentCredits,
  });

  const CreditState.empty()
      : creditBalance = 0,
        lastDailyGrantDate = '',
        rewardedAdsWatchedToday = 0,
        lastAdRewardDate = '',
        totalEarnedCredits = 0,
        totalSpentCredits = 0;

  factory CreditState.fromJson(Map<String, dynamic> json) => CreditState(
        creditBalance: (json['creditBalance'] as num?)?.toInt() ?? 0,
        lastDailyGrantDate: json['lastDailyGrantDate'] as String? ?? '',
        rewardedAdsWatchedToday:
            (json['rewardedAdsWatchedToday'] as num?)?.toInt() ?? 0,
        lastAdRewardDate: json['lastAdRewardDate'] as String? ?? '',
        totalEarnedCredits: (json['totalEarnedCredits'] as num?)?.toInt() ?? 0,
        totalSpentCredits: (json['totalSpentCredits'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'creditBalance': creditBalance,
        'lastDailyGrantDate': lastDailyGrantDate,
        'rewardedAdsWatchedToday': rewardedAdsWatchedToday,
        'lastAdRewardDate': lastAdRewardDate,
        'totalEarnedCredits': totalEarnedCredits,
        'totalSpentCredits': totalSpentCredits,
      };

  CreditState copyWith({
    int? creditBalance,
    String? lastDailyGrantDate,
    int? rewardedAdsWatchedToday,
    String? lastAdRewardDate,
    int? totalEarnedCredits,
    int? totalSpentCredits,
  }) {
    return CreditState(
      creditBalance: creditBalance ?? this.creditBalance,
      lastDailyGrantDate: lastDailyGrantDate ?? this.lastDailyGrantDate,
      rewardedAdsWatchedToday:
          rewardedAdsWatchedToday ?? this.rewardedAdsWatchedToday,
      lastAdRewardDate: lastAdRewardDate ?? this.lastAdRewardDate,
      totalEarnedCredits: totalEarnedCredits ?? this.totalEarnedCredits,
      totalSpentCredits: totalSpentCredits ?? this.totalSpentCredits,
    );
  }
}
