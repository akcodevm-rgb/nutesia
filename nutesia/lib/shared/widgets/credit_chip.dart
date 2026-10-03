import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../core/providers/credit_provider.dart';
import '../../core/providers/rewarded_ad_provider.dart';
import '../../core/services/credit_service.dart';
import '../../core/theme/app_theme.dart';
import 'credit_details_sheet.dart';
import 'error_views/error_views.dart';

class CreditChip extends StatelessWidget {
  const CreditChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CreditProvider, RewardedAdProvider>(
      builder: (context, credit, adProvider, _) {
        final balance = credit.creditBalance;
        final isLoading = credit.isLoading;
        final error = credit.error;
        final adLoading = adProvider.isLoading;

        return InkWell(
          onTap: () => showCreditDetailsSheet(context),
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
                if (isLoading && balance == 0)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                else if (error != null && balance == 0)
                  const Text(
                    '!',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  )
                else
                  Text(
                    '$balance',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                if (adLoading) ...[
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
      },
    );
  }
}

Future<void> showNotEnoughCreditsDialog({
  required BuildContext context,
  required int requiredCredits,
  required int currentCredits,
  required String featureName,
}) async {
  await AppErrorDialog.show(
    context,
    error: BusinessAppError.insufficientCredits(
      message: 'You need $requiredCredits credits for $featureName. You currently have $currentCredits credits.',
    ),
    customTitle: 'Not Enough Credits',
    customActionLabel: 'Watch Ad (+1 Credit)',
    onAction: () async {
      await showRewardedAdForCredit(context);
    },
  );
}

Future<void> showRewardedAdForCredit(BuildContext context) async {
  final creditProvider = context.read<CreditProvider>();
  final adProvider = context.read<RewardedAdProvider>();

  try {
    final bool earnedReward = await adProvider.show();

    if (!earnedReward) {
      if (context.mounted) {
        AppToast.showWarning(context, 'Ad was not completed. Reward not granted.');
      }
      return;
    }

    await creditProvider.addRewardedAdCredit();
    if (context.mounted) {
      AppToast.showSuccess(context, '+1 credit added to your wallet!');
    }
  } on RewardLimitException catch (e) {
    if (context.mounted) {
      AppToast.showWarning(context, e.message);
    }
  } catch (e) {
    if (context.mounted) {
      AppToast.showError(context, e);
    }
  }
}
