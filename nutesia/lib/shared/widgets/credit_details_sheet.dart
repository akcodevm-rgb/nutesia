import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/constants/credit_constants.dart';
import '../../core/providers/credit_provider.dart';
import '../../core/theme/app_theme.dart';
import 'credit_chip.dart';

/// Shows the credit details and usage menu in a modern, dark-themed sheet.
Future<void> showCreditDetailsSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => CreditDetailsSheet(parentRef: ref),
  );
}

class CreditDetailsSheet extends ConsumerWidget {
  final WidgetRef parentRef;
  const CreditDetailsSheet({super.key, required this.parentRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1626), // AppTheme.surface
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0xFF1F2D45), width: 1.5),
            left: BorderSide(color: Color(0xFF1F2D45), width: 1.5),
            right: BorderSide(color: Color(0xFF1F2D45), width: 1.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D5070),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Gap(24),

            // Header Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.primary,
                    size: 26,
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nuto Credits',
                        style: TextStyle(
                          color: Color(0xFFEFF6FF), // AppTheme.textPrimary
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      Text(
                        'Powering your smart nutrition features',
                        style: TextStyle(
                          color: Colors.blueGrey[200],
                          fontSize: 13,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Balance Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF080D1A), // AppTheme.background
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1F2D45)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          color: Color(0xFF8899B4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(4),
                      creditsAsync.when(
                        data: (wallet) => Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${wallet.creditBalance}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Text(
                              ' / ${CreditConstants.maxCreditBalance} max',
                              style: const TextStyle(
                                color: Color(0xFF3D5070),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.primary,
                          ),
                        ),
                        error: (_, __) => const Text(
                          '--',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Progress indicator visualization
                  if (creditsAsync.hasValue)
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: creditsAsync.value!.creditBalance / CreditConstants.maxCreditBalance,
                        backgroundColor: const Color(0xFF1F2D45),
                        color: AppTheme.primary,
                        strokeWidth: 5,
                      ),
                    ),
                ],
              ),
            ),
            const Gap(24),

            // Usage Menu Title
            const Text(
              'Usage & Cost Menu',
              style: TextStyle(
                color: Color(0xFFEFF6FF),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Gap(12),

            // Usage cost list
            _buildCostItem(
              icon: Icons.restaurant_menu_rounded,
              title: 'Food Analysis & Parsing',
              subtitle: 'Analyze your meal inputs, recipes, and food text logs',
              cost: CreditConstants.foodParseCost,
            ),
            const Gap(8),
            _buildCostItem(
              icon: Icons.analytics_outlined,
              title: 'Deficiency & Wellness Analysis',
              subtitle: 'Generate long-term predictions and nutrition insights',
              cost: CreditConstants.deficiencyAnalysisCost,
            ),
            const Gap(20),

            // Limits Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFFFB300), size: 18),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      'Earn 1 credit per ad watched. Max limit of ${CreditConstants.maxRewardedAdsPerDay} video ads per day.',
                      style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(28),

            // Earn Button
            ElevatedButton(
              onPressed: () async {
                // Close bottom sheet first
                Navigator.of(context).pop();
                // Start rewarded ad watch flow
                await showRewardedAdForCredit(context, parentRef);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: const Color(0xFF080D1A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline_rounded, size: 20),
                  Gap(8),
                  Text(
                    'Watch Video Ad to Earn +1 Credit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int cost,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161E30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2D45).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8899B4), size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEFF6FF),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8899B4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.25)),
            ),
            child: Text(
              '-$cost',
              style: const TextStyle(
                color: Color(0xFFFF5252),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
