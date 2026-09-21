import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../shared/widgets/glass_card.dart';

class DailySummaryCard extends StatelessWidget {
  final NutritionData consumed;
  final NutritionData targets;

  const DailySummaryCard({
    super.key,
    required this.consumed,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (targets.calories - consumed.calories).clamp(0, double.infinity);
    final pct = targets.calories > 0
        ? (consumed.calories / targets.calories).clamp(0.0, 1.0)
        : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Calories',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const Gap(4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${consumed.calories.round()}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.calColor,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${targets.calories.round()} kcal',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${remaining.round()} kcal remaining',
                      style: TextStyle(
                          color: pct >= 1.0
                              ? AppTheme.error
                              : AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _CaloriePctBadge(pct: pct),
            ],
          ),
          const Gap(16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation(
                pct < 0.8
                    ? AppTheme.primary
                    : pct < 1.0
                        ? AppTheme.warning
                        : AppTheme.error,
              ),
            ),
          ),
          const Gap(20),
          // Macro row
          _MacroSummaryRow(consumed: consumed, targets: targets),
        ],
      ),
    );
  }
}

class _CaloriePctBadge extends StatelessWidget {
  final double pct;

  const _CaloriePctBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.calColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.calColor.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(
          '${(pct * 100).round()}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.calColor,
          ),
        ),
      ),
    );
  }
}

class _MacroSummaryRow extends StatelessWidget {
  final NutritionData consumed;
  final NutritionData targets;

  const _MacroSummaryRow(
      {required this.consumed, required this.targets});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MacroMini(
            label: 'Protein',
            consumed: consumed.protein,
            target: targets.protein,
            unit: 'g',
            color: AppTheme.proteinColor),
        const Gap(8),
        _MacroMini(
            label: 'Carbs',
            consumed: consumed.carbs,
            target: targets.carbs,
            unit: 'g',
            color: AppTheme.carbsColor),
        const Gap(8),
        _MacroMini(
            label: 'Fat',
            consumed: consumed.fat,
            target: targets.fat,
            unit: 'g',
            color: AppTheme.fatColor),
      ],
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;

  const _MacroMini({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const Gap(4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${consumed.round()}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  TextSpan(
                    text: '/${target.round()}$unit',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Gap(6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 3,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
