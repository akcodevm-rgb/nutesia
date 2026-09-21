import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../home/providers/home_provider.dart';

class FoodDetailScreen extends ConsumerWidget {
  final FoodEntry entry;

  const FoodDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(entry.mealType),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.error),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ──────────────────────────────────
          _HeaderCard(entry: entry).animate().fadeIn().slideY(begin: 0.2),
          const Gap(16),

          // ── Macros ───────────────────────────────────────
          Text('Macronutrients',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppTheme.textSecondary))
              .animate()
              .fadeIn(delay: 100.ms),
          const Gap(8),
          _MacroGrid(nutrition: entry.totalNutrition)
              .animate()
              .fadeIn(delay: 150.ms),
          const Gap(16),

          // ── Food items breakdown ─────────────────────────
          if (entry.foods.length > 1) ...[
            Text('Food Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppTheme.textSecondary))
                .animate()
                .fadeIn(delay: 200.ms),
            const Gap(8),
            ...entry.foods.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FoodBreakdownCard(food: e.value)
                      .animate(delay: (200 + e.key * 60).ms)
                      .fadeIn()
                      .slideX(begin: 0.2),
                )),
            const Gap(8),
          ],

          // ── Vitamins ─────────────────────────────────────
          Text('Vitamins',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppTheme.textSecondary))
              .animate()
              .fadeIn(delay: 250.ms),
          const Gap(8),
          _VitaminMineralCard(nutrition: entry.totalNutrition)
              .animate()
              .fadeIn(delay: 300.ms),
          const Gap(16),

          // ── AI Explanation ────────────────────────────────
          if (entry.explanation.isNotEmpty)
            _AiExplanationCard(explanation: entry.explanation)
                .animate()
                .fadeIn(delay: 350.ms),
          const Gap(80),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This will permanently remove this food entry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(foodEntriesProvider.notifier).deleteEntry(entry.id);
      Navigator.of(context).pop();
    }
  }
}

// ─── Header Card ──────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final FoodEntry entry;

  const _HeaderCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final mealColor = AppTheme.mealColor(entry.mealType);
    final mainFood =
        entry.foods.isNotEmpty ? entry.foods.first.name : 'Meal';
    final extra = entry.foods.length - 1;

    return GlassCard(
      borderColor: mealColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_mealEmoji(entry.mealType),
                  style: const TextStyle(fontSize: 28)),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extra > 0 ? '$mainFood + $extra more' : mainFood,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      '${AppDateUtils.toTime(entry.loggedAt)} · ${entry.rawInput}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          overflow: TextOverflow.ellipsis),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BigNutri('${entry.totalNutrition.calories.round()}',
                  'kcal', AppTheme.calColor),
              _BigNutri('${entry.totalNutrition.protein.round()}g',
                  'Protein', AppTheme.proteinColor),
              _BigNutri('${entry.totalNutrition.carbs.round()}g',
                  'Carbs', AppTheme.carbsColor),
              _BigNutri('${entry.totalNutrition.fat.round()}g', 'Fat',
                  AppTheme.fatColor),
            ],
          ),
        ],
      ),
    );
  }

  String _mealEmoji(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      default:
        return '🍎';
    }
  }
}

class _BigNutri extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _BigNutri(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ─── Macro Grid ────────────────────────────────────────────────────────────

class _MacroGrid extends StatelessWidget {
  final NutritionData nutrition;

  const _MacroGrid({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          _DetailRow('Calories', '${nutrition.calories.round()} kcal',
              AppTheme.calColor),
          _DetailRow('Protein', '${nutrition.protein.round()} g',
              AppTheme.proteinColor),
          _DetailRow('Carbohydrates', '${nutrition.carbs.round()} g',
              AppTheme.carbsColor),
          _DetailRow(
              'Fat', '${nutrition.fat.round()} g', AppTheme.fatColor,
              isLast: true),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _DetailRow(this.label, this.value, this.color,
      {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const Gap(12),
              Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}

// ─── Food Breakdown Card ───────────────────────────────────────────────────

class _FoodBreakdownCard extends StatelessWidget {
  final FoodItem food;

  const _FoodBreakdownCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Text(
                '${food.quantity.round()} ${food.unit}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              _SmallBadge('${food.nutrition.calories.round()} kcal',
                  AppTheme.calColor),
              const Gap(6),
              _SmallBadge('${food.nutrition.protein.round()}g P',
                  AppTheme.proteinColor),
              const Gap(6),
              _SmallBadge('${food.nutrition.carbs.round()}g C',
                  AppTheme.carbsColor),
              const Gap(6),
              _SmallBadge('${food.nutrition.fat.round()}g F',
                  AppTheme.fatColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Vitamins & Minerals Card ──────────────────────────────────────────────

class _VitaminMineralCard extends StatefulWidget {
  final NutritionData nutrition;

  const _VitaminMineralCard({required this.nutrition});

  @override
  State<_VitaminMineralCard> createState() => _VitaminMineralCardState();
}

class _VitaminMineralCardState extends State<_VitaminMineralCard> {
  bool _showMinerals = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.nutrition.vitamins;
    final m = widget.nutrition.minerals;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TabBtn('Vitamins', !_showMinerals,
                  () => setState(() => _showMinerals = false)),
              const Gap(8),
              _TabBtn('Minerals', _showMinerals,
                  () => setState(() => _showMinerals = true)),
            ],
          ),
          const Gap(12),
          AnimatedCrossFade(
            crossFadeState: _showMinerals
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: Column(
              children: [
                _MicroDetailRow('Vitamin A', _fmt(v.vitaminA), 'mcg'),
                _MicroDetailRow('Vitamin B1', _fmt(v.vitaminB1), 'mg'),
                _MicroDetailRow('Vitamin B6', _fmt(v.vitaminB6), 'mg'),
                _MicroDetailRow('Vitamin B12', _fmt(v.vitaminB12), 'mcg'),
                _MicroDetailRow('Vitamin C', _fmt(v.vitaminC), 'mg'),
                _MicroDetailRow('Vitamin D', _fmt(v.vitaminD), 'mcg'),
                _MicroDetailRow('Vitamin E', _fmt(v.vitaminE), 'mg'),
                _MicroDetailRow('Vitamin K', _fmt(v.vitaminK), 'mcg'),
                _MicroDetailRow('Folate', _fmt(v.folate), 'mcg',
                    isLast: true),
              ],
            ),
            secondChild: Column(
              children: [
                _MicroDetailRow('Calcium', _fmt(m.calcium), 'mg'),
                _MicroDetailRow('Iron', _fmt(m.iron), 'mg'),
                _MicroDetailRow('Zinc', _fmt(m.zinc), 'mg'),
                _MicroDetailRow('Magnesium', _fmt(m.magnesium), 'mg'),
                _MicroDetailRow('Potassium', _fmt(m.potassium), 'mg'),
                _MicroDetailRow('Sodium', _fmt(m.sodium), 'mg'),
                _MicroDetailRow('Phosphorus', _fmt(m.phosphorus), 'mg',
                    isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v < 1 ? v.toStringAsFixed(2) : v.round().toString();
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}

class _MicroDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isLast;

  const _MicroDetailRow(this.label, this.value, this.unit,
      {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              Text('$value $unit',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}

// ─── AI Explanation ────────────────────────────────────────────────────────

class _AiExplanationCard extends StatelessWidget {
  final String explanation;

  const _AiExplanationCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.primary.withOpacity(0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.primary, size: 20),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Health Insight',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Gap(6),
                Text(explanation,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
