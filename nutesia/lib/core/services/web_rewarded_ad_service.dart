import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

/// A singleton service that manages Google Publisher Tag (GPT) Rewarded Video Ads
/// for Flutter Web using modern compile-safe JS Interop.
class WebRewardedAdService {
  static final WebRewardedAdService instance = WebRewardedAdService._();
  WebRewardedAdService._();

  bool _isInitialized = false;
  Completer<bool>? _activeAdCompleter;
  JSObject? _activeSlot;
  Timer? _timeoutTimer;

  /// Initializes the service by adding global event listeners to the googletag pubads service.
  /// This must only be run once to prevent registering duplicate listeners.
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    final gpt = globalContext['googletag'] as JSObject?;
    if (gpt == null || gpt.isUndefinedOrNull) {
      debugPrint('WebRewardedAdService: googletag not loaded yet on initialization.');
      return;
    }

    final cmd = gpt['cmd'] as JSObject;
    cmd.callMethod('push'.toJS, (() {
      final pubads = gpt.callMethod('pubads'.toJS) as JSObject;

      // 1. Listen for ad ready and immediately show it
      pubads.callMethod(
        'addEventListener'.toJS,
        'rewardedSlotReady'.toJS,
        ((JSObject event) {
          debugPrint('WebRewardedAdService: rewardedSlotReady fired.');
          _timeoutTimer?.cancel();
          
          try {
            // Trigger the ad visibility (make it show full screen overlay)
            event.callMethod('makeRewardedVisible'.toJS);
          } catch (e) {
            debugPrint('WebRewardedAdService: Failed to make rewarded ad visible: $e');
            _completeActiveAd(false);
          }
        }).toJS,
      );

      // 2. Listen for reward granted event
      pubads.callMethod(
        'addEventListener'.toJS,
        'rewardedSlotGranted'.toJS,
        ((JSObject event) {
          debugPrint('WebRewardedAdService: rewardedSlotGranted fired. Granting reward.');
          _completeActiveAd(true);
        }).toJS,
      );

      // 3. Listen for slot closed event
      pubads.callMethod(
        'addEventListener'.toJS,
        'rewardedSlotClosed'.toJS,
        ((JSObject event) {
          debugPrint('WebRewardedAdService: rewardedSlotClosed fired. Ad was closed.');
          _completeActiveAd(false);
        }).toJS,
      );
    }).toJS);
  }

  /// Cleans up current slot and timer, and resolves the active completer.
  void _completeActiveAd(bool earned) {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    final slot = _activeSlot;
    if (slot != null) {
      final gpt = globalContext['googletag'] as JSObject?;
      if (gpt != null && !gpt.isUndefinedOrNull) {
        gpt.callMethod('destroySlots'.toJS, [slot].toJS);
      }
      _activeSlot = null;
    }

    final completer = _activeAdCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(earned);
    }
    _activeAdCompleter = null;
  }

  /// Requests and displays a real Google GPT rewarded video ad.
  /// Returns [true] if user successfully completes the video to earn the reward, or [false] otherwise.
  Future<bool> showRealGptAd() async {
    init();

    final gpt = globalContext['googletag'] as JSObject?;
    if (gpt == null || gpt.isUndefinedOrNull) {
      debugPrint('WebRewardedAdService: googletag library is unavailable.');
      return false;
    }

    // Cancel any existing active requests to prevent overlapping state
    _completeActiveAd(false);

    final completer = Completer<bool>();
    _activeAdCompleter = completer;

    // Start a 15-second timeout for loading the ad
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      debugPrint('WebRewardedAdService: Ad request timed out after 15 seconds.');
      _completeActiveAd(false);
    });

    final cmd = gpt['cmd'] as JSObject;
    cmd.callMethod('push'.toJS, (() {
      try {
        final enums = gpt['enums'] as JSObject;
        final outOfPageFormat = enums['OutOfPageFormat'] as JSObject;
        final rewardedFormat = outOfPageFormat['REWARDED'];

        // Google Ad Manager rewarded video ad unit ID
        // Testing ID is used under development / staging.
        final adUnitId = kReleaseMode
            ? '/21775338/rewarded_test' // Replace with your production GAM ad unit ID if needed
            : '/21775338/rewarded_test';

        final slot = gpt.callMethod(
          'defineOutOfPageSlot'.toJS,
          adUnitId.toJS,
          rewardedFormat,
        ) as JSObject?;

        if (slot == null || slot.isUndefinedOrNull) {
          debugPrint('WebRewardedAdService: defineOutOfPageSlot returned null (possibly unsupported device/viewport).');
          _completeActiveAd(false);
          return;
        }

        _activeSlot = slot;
        slot.callMethod('addService'.toJS, gpt.callMethod('pubads'.toJS));

        gpt.callMethod('enableServices'.toJS);
        gpt.callMethod('display'.toJS, slot);
      } catch (e) {
        debugPrint('WebRewardedAdService: Error setting up GPT ad: $e');
        _completeActiveAd(false);
      }
    }).toJS);

    return completer.future;
  }
}
