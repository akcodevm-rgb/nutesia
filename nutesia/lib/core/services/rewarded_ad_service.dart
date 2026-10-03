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
      return 'ca-app-pub-7341313231725400/6331667687';
    }
    return 'ca-app-pub-7341313231725400/6331667687';
  }

  String get _testAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  Future<void> load({String? overrideAdUnitId}) async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      log('RewardedAdService: Ads are simulated on this platform.');
      return;
    }
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    final targetUnitId = overrideAdUnitId ?? _adUnitId;

    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: targetUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          log('RewardedAdService: rewarded ad loaded with unit ID: $targetUnitId');
          _rewardedAd = ad;
          _isLoading = false;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          log('RewardedAdService: failed to load rewarded ad ($targetUnitId): $error');
          _rewardedAd = null;
          _isLoading = false;

          // If loading primary ad unit failed (e.g. error code 3: no fill for newly created unit),
          // fallback to Google test ad unit ID in debug mode so testing is smooth.
          if (overrideAdUnitId == null && (kDebugMode || targetUnitId != _testAdUnitId)) {
            log('RewardedAdService: Retrying load with Google test ad unit ID...');
            load(overrideAdUnitId: _testAdUnitId).then((_) {
              if (!completer.isCompleted) completer.complete();
            }).catchError((fallbackError) {
              if (!completer.isCompleted) completer.completeError(fallbackError);
            });
          } else {
            if (!completer.isCompleted) completer.completeError(error);
          }
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

    if (_rewardedAd == null) {
      try {
        await load();
      } catch (e) {
        log('RewardedAdService: Error loading ad before show: $e');
        return false;
      }
    }

    final readyAd = _rewardedAd;
    if (readyAd == null) return false;

    final completer = Completer<bool>();
    var earnedReward = false;

    readyAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        unawaited(load().catchError((_) {}));
        if (!completer.isCompleted) completer.complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('RewardedAdService: failed to show rewarded ad: $error');
        ad.dispose();
        _rewardedAd = null;
        unawaited(load().catchError((_) {}));
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
