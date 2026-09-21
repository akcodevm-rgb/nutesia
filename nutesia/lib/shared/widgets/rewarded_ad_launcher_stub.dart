import 'package:flutter/material.dart';

/// Fallback launcher implementation for mobile / desktop platforms.
Future<bool> launchWebRewardedAd(BuildContext context) async {
  throw UnsupportedError('launchWebRewardedAd is only supported on Web');
}
