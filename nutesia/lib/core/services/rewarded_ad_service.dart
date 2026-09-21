import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  bool get isReady {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }
    return _rewardedAd != null;
  }
  bool get isLoading => _isLoading;

  String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  Future<void> load() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      log('RewardedAdService: Ads are simulated on this platform.');
      return;
    }
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          log('RewardedAdService: rewarded ad loaded');
          _rewardedAd = ad;
          _isLoading = false;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          log('RewardedAdService: failed to load rewarded ad: $error');
          _rewardedAd = null;
          _isLoading = false;
          completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  Future<bool> show() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      log('RewardedAdService: Simulating ad watch (2 seconds delay)...');
      _isLoading = true;
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      log('RewardedAdService: User earned simulated reward');
      return true;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      await load();
    }

    final readyAd = _rewardedAd;
    if (readyAd == null) return false;

    final completer = Completer<bool>();
    var earnedReward = false;

    readyAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        unawaited(load());
        if (!completer.isCompleted) completer.complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('RewardedAdService: failed to show rewarded ad: $error');
        ad.dispose();
        _rewardedAd = null;
        unawaited(load());
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    _rewardedAd = null;
    await readyAd.show(
      onUserEarnedReward: (_, reward) {
        log('RewardedAdService: user earned reward ${reward.amount}');
        earnedReward = true;
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
