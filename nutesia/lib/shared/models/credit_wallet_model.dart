class CreditWalletModel {
  final String id;
  final String spaceId;
  final int dailyBalance;
  final int adBalance;
  final int creditBalance;
  final String lastDailyGrantDate;
  final int rewardedAdsWatchedToday;
  final String lastAdRewardDate;
  final int totalEarnedCredits;
  final int totalSpentCredits;
  final DateTime updatedAt;

  const CreditWalletModel({
    required this.id,
    required this.spaceId,
    this.dailyBalance = 5,
    this.adBalance = 0,
    this.creditBalance = 5,
    this.lastDailyGrantDate = '',
    this.rewardedAdsWatchedToday = 0,
    this.lastAdRewardDate = '',
    this.totalEarnedCredits = 5,
    this.totalSpentCredits = 0,
    required this.updatedAt,
  });

  bool get canWatchAd => rewardedAdsWatchedToday < 30;

  factory CreditWalletModel.fromJson(Map<String, dynamic> json) =>
      CreditWalletModel(
        id: json['id'] as String? ?? '',
        spaceId: json['spaceId'] as String? ?? '',
        dailyBalance: json['dailyBalance'] as int? ?? 5,
        adBalance: json['adBalance'] as int? ?? 0,
        creditBalance: json['creditBalance'] as int? ??
            ((json['dailyBalance'] as int? ?? 5) +
                (json['adBalance'] as int? ?? 0)),
        lastDailyGrantDate: json['lastDailyGrantDate'] as String? ?? '',
        rewardedAdsWatchedToday:
            json['rewardedAdsWatchedToday'] as int? ?? 0,
        lastAdRewardDate: json['lastAdRewardDate'] as String? ?? '',
        totalEarnedCredits: json['totalEarnedCredits'] as int? ?? 5,
        totalSpentCredits: json['totalSpentCredits'] as int? ?? 0,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'spaceId': spaceId,
        'dailyBalance': dailyBalance,
        'adBalance': adBalance,
        'creditBalance': creditBalance,
        'lastDailyGrantDate': lastDailyGrantDate,
        'rewardedAdsWatchedToday': rewardedAdsWatchedToday,
        'lastAdRewardDate': lastAdRewardDate,
        'totalEarnedCredits': totalEarnedCredits,
        'totalSpentCredits': totalSpentCredits,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
