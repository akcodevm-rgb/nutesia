import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../core/constants/credit_constants.dart';
import '../../core/providers/credit_provider.dart';
import '../../core/theme/app_theme.dart';
import 'credit_chip.dart';

/// Shows the credit details and dual-bucket breakdown in a modern, dark-themed sheet.
Future<void> showCreditDetailsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const CreditDetailsSheet(),
  );
}

class CreditDetailsSheet extends StatelessWidget {
  const CreditDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Consumer<CreditProvider>(
          builder: (context, credit, _) {
            final wallet = credit.wallet;
            final balance = credit.creditBalance;
            final daily = credit.dailyCredits;
            final ad = credit.adCredits;

            return SingleChildScrollView(
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
                  const Gap(20),

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
                              'Nutesia Credit Economy',
                              style: TextStyle(
                                color: Color(0xFFEFF6FF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Text(
                              'Dual-Bucket Credit System',
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
                  const Gap(20),

                  // Total Available Balance Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080D1A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF1F2D45)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Available Credits',
                              style: TextStyle(
                                color: Color(0xFF8899B4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Gap(4),
                            if (credit.isLoading && wallet == null)
                              const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primary,
                                ),
                              )
                            else if (credit.error != null && wallet == null)
                              const Text(
                                '--',
                                style: TextStyle(
                                  color: AppTheme.warning,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Text(
                                '$balance Credits',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Daily-First Spend',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // Dual Bucket Cards: Daily Free Credits & Ad Credits
                  Row(
                    children: [
                      // Daily Bucket Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161E30),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1F2D45)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.today_rounded, size: 16, color: Color(0xFF64B5F6)),
                                  Gap(6),
                                  Text(
                                    'Daily Free',
                                    style: TextStyle(
                                      color: Color(0xFFEFF6FF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Text(
                                '$daily / ${CreditConstants.dailyFreeCredits}',
                                style: const TextStyle(
                                  color: Color(0xFF64B5F6),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const Gap(4),
                              const Text(
                                'Resets at midnight\nNo rollover',
                                style: TextStyle(
                                  color: Color(0xFF8899B4),
                                  fontSize: 10,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(12),
                      // Ad Credits Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161E30),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1F2D45)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.stars_rounded, size: 16, color: Color(0xFFFFD54F)),
                                  Gap(6),
                                  Text(
                                    'Ad Credits',
                                    style: TextStyle(
                                      color: Color(0xFFEFF6FF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Text(
                                '$ad',
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const Gap(4),
                              const Text(
                                'Earned via ads\nNo expiry date',
                                style: TextStyle(
                                  color: Color(0xFF8899B4),
                                  fontSize: 10,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // 3-Meal Mechanic Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.restaurant_rounded, color: Color(0xFF00E676), size: 20),
                        Gap(10),
                        Expanded(
                          child: Text(
                            '3-Meal Mechanic: Morning, Noon & Night meals cost 6 credits total per day (2 credits/meal). Your 5 daily free credits cover 2.5 meals — watch 1 ad daily (+1 ad credit) to log all 3 meals!',
                            style: TextStyle(
                              color: Color(0xFFB9F6CA),
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // Usage & Cost Menu Title
                  const Text(
                    'Usage & Cost Menu',
                    style: TextStyle(
                      color: Color(0xFFEFF6FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Gap(10),

                  // Usage cost list
                  _buildCostItem(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Food Nutrition Analysis',
                    subtitle: 'Analyze morning, noon, or night meal text (Daily-first)',
                    cost: CreditConstants.foodParseCost,
                  ),
                  const Gap(8),
                  _buildCostItem(
                    icon: Icons.analytics_outlined,
                    title: 'Weekly Nutrition Report',
                    subtitle: 'Generate overall nutrient report & deficiency insights',
                    cost: CreditConstants.deficiencyAnalysisCost,
                  ),
                  const Gap(20),

                  // Earn Button
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await showRewardedAdForCredit(context);
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
                          'Watch Video Ad to Earn +1 Ad Credit',
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
            );
          },
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
