import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/member_model.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/manage_members_sheet.dart';
import '../../food_log/screens/add_food_screen.dart';
import '../../profile/providers/nutrition_space_provider.dart';
import '../providers/home_provider.dart';

class ChildNutritionSection extends StatelessWidget {
  final List<MemberModel> children;

  const ChildNutritionSection({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.child_care_rounded,
                size: 18,
                color: Colors.orangeAccent,
              ),
            ),
            const Gap(8),
            Text(
              "Child Nutrition Overview",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${children.length} ${children.length == 1 ? 'Child' : 'Children'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChildProfileCard(child: child),
            )),
      ],
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  final MemberModel child;

  const _ChildProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeProvider, NutritionSpaceProvider>(
      builder: (context, homeProvider, spaceProvider, _) {
        final consumed = homeProvider.getMemberDailySummary(child.id);
        final targets = child.dailyTargets.calories > 0
            ? child.dailyTargets
            : const NutritionData(calories: 1600, protein: 45, carbs: 180, fat: 50);

        final calGoal = targets.calories > 0 ? targets.calories : 1600.0;
        final calConsumed = consumed.calories;
        final calRemaining = (calGoal - calConsumed).clamp(0.0, double.infinity);
        final calPct = (calConsumed / calGoal).clamp(0.0, 1.0);

        final proteinGoal = targets.protein > 0 ? targets.protein : 45.0;
        final proteinConsumed = consumed.protein;
        final proteinPct = (proteinConsumed / proteinGoal).clamp(0.0, 1.0);

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Avatar, Name, Age, Switch Action ──────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: Text(
                      child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                child.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                child.age > 0 ? '${child.age} yrs' : 'Child',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(2),
                        Text(
                          child.bmi > 0
                              ? 'BMI ${child.bmi.toStringAsFixed(1)} • ${child.bmiCategory}'
                              : 'Daily Target: ${calGoal.round()} kcal',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit Button
                  InkWell(
                    onTap: () => _showEditChildModal(context, child),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorder.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          Gap(3),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(6),
                  // Quick Switch Button
                  InkWell(
                    onTap: () {
                      spaceProvider.switchActiveMember(child.id);
                      homeProvider.updateActiveMember(child.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${child.name}\'s profile'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              size: 14, color: AppTheme.primary),
                          Gap(4),
                          Text(
                            'Switch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),

              // ── Key Nutrition Metrics: Calories & Protein ─────────────────
              Row(
                children: [
                  // Calories Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.calColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.calColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Calories (kcal)',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(calPct * 100).round()}%',
                                style: const TextStyle(
                                  color: AppTheme.calColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${calConsumed.round()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.calColor,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${calGoal.round()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: calPct,
                              minHeight: 4,
                              backgroundColor:
                                  AppTheme.calColor.withValues(alpha: 0.15),
                              valueColor:
                                  const AlwaysStoppedAnimation(AppTheme.calColor),
                            ),
                          ),
                          const Gap(4),
                          Text(
                            calRemaining > 0
                                ? '${calRemaining.round()} kcal left'
                                : 'Goal reached! 🎉',
                            style: TextStyle(
                              fontSize: 10,
                              color: calRemaining > 0
                                  ? AppTheme.textMuted
                                  : AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(10),

                  // Protein Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.proteinColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.proteinColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Protein (g)',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(proteinPct * 100).round()}%',
                                style: const TextStyle(
                                  color: AppTheme.proteinColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${proteinConsumed.round()}g',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.proteinColor,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${proteinGoal.round()}g',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: proteinPct,
                              minHeight: 4,
                              backgroundColor:
                                  AppTheme.proteinColor.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.proteinColor),
                            ),
                          ),
                          const Gap(4),
                          Text(
                            proteinConsumed >= proteinGoal
                                ? 'Daily protein met! 💪'
                                : '${(proteinGoal - proteinConsumed).round()}g needed',
                            style: TextStyle(
                              fontSize: 10,
                              color: proteinConsumed >= proteinGoal
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(10),

              // ── Quick Log Food For Child Action ───────────────────────────
              InkWell(
                onTap: () {
                  // Switch to child profile and open Log Food Screen
                  spaceProvider.switchActiveMember(child.id);
                  homeProvider.updateActiveMember(child.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddFoodScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 15, color: AppTheme.textSecondary),
                      const Gap(6),
                      Text(
                        'Log Meal for ${child.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditChildModal(BuildContext context, MemberModel child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ManageMembersSheet(memberToEdit: child),
    );
  }
}
