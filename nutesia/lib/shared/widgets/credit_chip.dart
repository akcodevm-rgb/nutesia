import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/constants/credit_constants.dart';
import '../../core/providers/credit_provider.dart';
import '../../core/providers/rewarded_ad_provider.dart';
import '../../core/services/credit_service.dart';
import '../../core/theme/app_theme.dart';
import 'credit_details_sheet.dart';
import 'rewarded_ad_launcher.dart';
import 'web_mock_ad_dialog.dart';


class CreditChip extends ConsumerWidget {
  const CreditChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditProvider);
    final adState = ref.watch(rewardedAdProvider);

    return InkWell(
      onTap: () => showCreditDetailsSheet(context, ref),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.primary),
            const Gap(4),
            creditsAsync.when(
              data: (wallet) => Text(
                '${wallet.creditBalance}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              loading: () => const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
              error: (_, _) => const Text(
                '!',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (adState.isLoading) ...[
              const Gap(6),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showNotEnoughCreditsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int requiredCredits,
  required int currentCredits,
  required String featureName,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Not enough credits'),
      content: Text(
        'You need $requiredCredits credits for $featureName. '
        'You have $currentCredits credits. Watch an ad to earn '
        '${CreditConstants.rewardedAdCredit} credit.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await showRewardedAdForCredit(context, ref);
          },
          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
          label: const Text('Watch Ad'),
        ),
      ],
    ),
  );
}

Future<void> showRewardedAdForCredit(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.of(context);
  // Capture notifiers before any asynchronous gap to avoid disposed widget ref errors
  final creditNotifier = ref.read(creditProvider.notifier);
  final adNotifier = ref.read(rewardedAdProvider.notifier);

  try {
    final bool earnedReward;
    if (kIsWeb) {
      earnedReward = await launchWebRewardedAd(context);
    } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      earnedReward = await adNotifier.show();
    } else {
      earnedReward = await WebMockAdDialog.show(context);
    }

    if (!earnedReward) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ad was not completed')),
      );
      return;
    }

    await creditNotifier.addRewardedAdCredit();
    messenger.showSnackBar(
      const SnackBar(content: Text('+1 credit added')),
    );
  } on RewardLimitException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: AppTheme.warning),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Could not add ad credit: $e'),
        backgroundColor: AppTheme.error,
      ),
    );
  }
}
