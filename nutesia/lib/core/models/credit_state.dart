class CreditState {
  final int dailyCredits;
  final int adCredits;
  final int creditBalance;
  final String lastDailyGrantDate;
  final int rewardedAdsWatchedToday;
  final String lastAdRewardDate;
  final int totalEarnedCredits;
  final int totalSpentCredits;

  const CreditState({
    required this.dailyCredits,
    required this.adCredits,
    required this.creditBalance,
    required this.lastDailyGrantDate,
    required this.rewardedAdsWatchedToday,
    required this.lastAdRewardDate,
    required this.totalEarnedCredits,
    required this.totalSpentCredits,
  });

  const CreditState.empty()
      : dailyCredits = 0,
        adCredits = 0,
        creditBalance = 0,
        lastDailyGrantDate = '',
        rewardedAdsWatchedToday = 0,
        lastAdRewardDate = '',
        totalEarnedCredits = 0,
        totalSpentCredits = 0;

  factory CreditState.fromJson(Map<String, dynamic> json) {
    final daily = (json['dailyBalance'] as num?)?.toInt() ??
        (json['dailyCredits'] as num?)?.toInt() ??
        5;
    final ad = (json['adBalance'] as num?)?.toInt() ??
        (json['adCredits'] as num?)?.toInt() ??
        0;
    final balance = (json['creditBalance'] as num?)?.toInt() ?? (daily + ad);
    return CreditState(
      dailyCredits: daily,
      adCredits: ad,
      creditBalance: balance,
      lastDailyGrantDate: json['lastDailyGrantDate'] as String? ?? '',
      rewardedAdsWatchedToday:
          (json['rewardedAdsWatchedToday'] as num?)?.toInt() ?? 0,
      lastAdRewardDate: json['lastAdRewardDate'] as String? ?? '',
      totalEarnedCredits: (json['totalEarnedCredits'] as num?)?.toInt() ?? 0,
      totalSpentCredits: (json['totalSpentCredits'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyCredits': dailyCredits,
        'adCredits': adCredits,
        'creditBalance': creditBalance,
        'lastDailyGrantDate': lastDailyGrantDate,
        'rewardedAdsWatchedToday': rewardedAdsWatchedToday,
        'lastAdRewardDate': lastAdRewardDate,
        'totalEarnedCredits': totalEarnedCredits,
        'totalSpentCredits': totalSpentCredits,
      };

  CreditState copyWith({
    int? dailyCredits,
    int? adCredits,
    int? creditBalance,
    String? lastDailyGrantDate,
    int? rewardedAdsWatchedToday,
    String? lastAdRewardDate,
    int? totalEarnedCredits,
    int? totalSpentCredits,
  }) {
    final newDaily = dailyCredits ?? this.dailyCredits;
    final newAd = adCredits ?? this.adCredits;
    return CreditState(
      dailyCredits: newDaily,
      adCredits: newAd,
      creditBalance: creditBalance ??
          (dailyCredits != null || adCredits != null
              ? newDaily + newAd
              : this.creditBalance),
      lastDailyGrantDate: lastDailyGrantDate ?? this.lastDailyGrantDate,
      rewardedAdsWatchedToday:
          rewardedAdsWatchedToday ?? this.rewardedAdsWatchedToday,
      lastAdRewardDate: lastAdRewardDate ?? this.lastAdRewardDate,
      totalEarnedCredits: totalEarnedCredits ?? this.totalEarnedCredits,
      totalSpentCredits: totalSpentCredits ?? this.totalSpentCredits,
    );
  }
}

