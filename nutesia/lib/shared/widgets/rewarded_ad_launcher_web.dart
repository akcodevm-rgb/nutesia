import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../core/services/web_rewarded_ad_service.dart';
import 'web_mock_ad_dialog.dart';

/// Web implementation of the rewarded ad launcher.
/// Automatically detects localhost or debug builds to fall back to the premium mock dialog.
/// In production, it shows a loading spinner, requests the GPT rewarded ad, and displays
/// a "No ads available" warning snackbar if the ad fails to fill or load.
Future<bool> launchWebRewardedAd(BuildContext context) async {
  final hostname = web.window.location.hostname;
  final isLocalhost = hostname == 'localhost' || hostname == '127.0.0.1';

  // Local development / debug builds simulation path
  if (isLocalhost || kDebugMode) {
    debugPrint('RewardedAdLauncher: Running in local/debug mode. Launching mock ad.');
    return await WebMockAdDialog.show(context);
  }

  // Production path: Show loading overlay
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1626), // AppTheme.surface
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1F2D45), width: 1.5), // AppTheme.cardBorder
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.1), // AppTheme.primary
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Color(0xFF00E676), // AppTheme.primary
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Loading video ad...',
              style: TextStyle(
                color: const Color(0xFFEFF6FF), // AppTheme.textPrimary
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    // Request and show the GPT rewarded video ad
    final bool adResult = await WebRewardedAdService.instance.showRealGptAd();

    // Dismiss loading indicator
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!adResult) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('No ads available, try again later'),
          backgroundColor: Color(0xFFFF5252), // AppTheme.error
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    return true;
  } catch (e) {
    debugPrint('RewardedAdLauncher: Exception while displaying GPT ad: $e');
    // Dismiss loading indicator
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Failed to load ad. Please try again.'),
        backgroundColor: Color(0xFFFF5252), // AppTheme.error
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }
}
