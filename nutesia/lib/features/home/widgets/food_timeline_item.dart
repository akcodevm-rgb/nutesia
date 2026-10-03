import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/widgets/glass_card.dart';

class FoodTimelineItem extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int index;

  const FoodTimelineItem({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final mealColor = AppTheme.mealColor(entry.mealType);
    final mainFood = entry.foods.isNotEmpty ? entry.foods.first.name : 'Food';
    final extraCount = entry.foods.length - 1;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Meal type dot + line
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: mealColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: mealColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Center(
                  child: Icon(
                    _mealIcon(entry.mealType),
                    color: mealColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        extraCount > 0
                            ? '$mainFood +$extraCount more'
                            : mainFood,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: mealColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.mealType,
                        style: TextStyle(
                          color: mealColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: AppTheme.calColor, size: 14),
                    const Gap(3),
                    Text(
                      '${entry.totalNutrition.calories.round()} kcal',
                      style: TextStyle(
                          color: AppTheme.calColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const Gap(12),
                    Icon(Icons.fitness_center_rounded,
                        color: AppTheme.proteinColor, size: 12),
                    const Gap(3),
                    Text(
                      '${entry.totalNutrition.protein.round()}g protein',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      AppDateUtils.toTime(entry.loggedAt),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(8),
          Column(
            children: [
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.textMuted, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted, size: 18),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.2);
  }

  IconData _mealIcon(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.restaurant_rounded;
      case 'dinner':
        return Icons.nights_stay_outlined;
      default:
        return Icons.apple;
    }
  }
}

/// Groups entries by meal type and renders them with a header.
class MealGroup extends StatelessWidget {
  final String mealType;
  final List<FoodEntry> entries;
  final void Function(FoodEntry)? onEntryTap;
  final void Function(String)? onEntryDelete;

  const MealGroup({
    super.key,
    required this.mealType,
    required this.entries,
    this.onEntryTap,
    this.onEntryDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final mealColor = AppTheme.mealColor(mealType);
    final totalCal = entries.fold<double>(
        0, (sum, e) => sum + e.totalNutrition.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: mealColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(10),
              Text(mealType,
                  style: TextStyle(
                    color: mealColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
              const Spacer(),
              Text(
                '${totalCal.round()} kcal',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        ...entries.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FoodTimelineItem(
                entry: e.value,
                index: e.key,
                onTap: () => onEntryTap?.call(e.value),
                onDelete: () => onEntryDelete?.call(e.value.id),
              ),
            )),
      ],
    );
  }
}
