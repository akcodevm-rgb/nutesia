import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/confirm_food_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/services/analytics_service.dart';
import '../../../shared/widgets/error_views/error_views.dart';

class ConfirmFoodScreen extends StatelessWidget {
  final String rawInput;
  final String mealType;

  const ConfirmFoodScreen({
    super.key,
    required this.rawInput,
    required this.mealType,
  });

  Future<void> _save(BuildContext context) async {
    final confirmFood = context.read<ConfirmFoodProvider>();
    final home = context.read<HomeProvider>();

    final success = await confirmFood.save(
      mealType: mealType,
      rawInput: rawInput,
      homeProvider: home,
    );

    if (success && context.mounted) {
      AppToast.showSuccess(context, '$mealType logged successfully!');
      // Pop both ConfirmScreen and AddFoodScreen
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else if (confirmFood.errorMessage != null && context.mounted) {
      AppToast.showError(
        context,
        confirmFood.errorMessage!,
        onAction: () => _save(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView('confirm_food_screen');
    });

    return Consumer<ConfirmFoodProvider>(
      builder: (context, confirmFood, _) {
        final total = confirmFood.totalNutrition;
        final foods = confirmFood.editableFoods;
        final isSaving = confirmFood.isSaving;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Confirm & Log'),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => _save(context),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary),
                      )
                    : const Text('Log',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ── Total summary bar ────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                        bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      _TotalChip(
                          label: 'Cal',
                          value: total.calories.round(),
                          color: AppTheme.calColor),
                      const Gap(16),
                      _TotalChip(
                          label: 'P',
                          value: total.protein.round(),
                          color: AppTheme.proteinColor,
                          suffix: 'g'),
                      const Gap(16),
                      _TotalChip(
                          label: 'C',
                          value: total.carbs.round(),
                          color: AppTheme.carbsColor,
                          suffix: 'g'),
                      const Gap(16),
                      _TotalChip(
                          label: 'F',
                          value: total.fat.round(),
                          color: AppTheme.fatColor,
                          suffix: 'g'),
                      const Spacer(),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.mealColor(mealType).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mealType,
                          style: TextStyle(
                            color: AppTheme.mealColor(mealType),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Food item list ───────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: foods.length + 1,
                    separatorBuilder: (_, _) => const Gap(12),
                    itemBuilder: (ctx, i) {
                      if (i == foods.length) {
                        // AI Explanation card
                        return confirmFood.explanation.isNotEmpty
                            ? _ExplanationCard(explanation: confirmFood.explanation)
                                .animate()
                                .fadeIn(delay: (i * 60 + 200).ms)
                            : const SizedBox.shrink();
                      }
                      final food = foods[i];
                      return _EditableFoodCard(
                        key: ValueKey('${food.name}_$i'),
                        food: food,
                        index: i,
                        onQuantityChanged: (qty) =>
                            confirmFood.updateQuantity(i, qty),
                        onUnitChanged: (unit) =>
                            confirmFood.updateUnit(i, unit),
                        onRemove: foods.length > 1
                            ? () => confirmFood.removeItem(i)
                            : null,
                      ).animate(delay: (i * 80).ms).fadeIn().slideX(begin: 0.2);
                    },
                  ),
                ),

                // ── Log button ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : () => _save(context),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('Log This Meal'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Editable Food Card ────────────────────────────────────────────────────

class _EditableFoodCard extends StatefulWidget {
  final FoodItem food;
  final int index;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback? onRemove;

  const _EditableFoodCard({
    super.key,
    required this.food,
    required this.index,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    this.onRemove,
  });

  @override
  State<_EditableFoodCard> createState() => _EditableFoodCardState();
}

class _EditableFoodCardState extends State<_EditableFoodCard> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    final qty = widget.food.quantity;
    _qtyController = TextEditingController(
      text: qty == qty.roundToDouble()
          ? qty.round().toString()
          : qty.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(_EditableFoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food.quantity != widget.food.quantity) {
      final qty = widget.food.quantity;
      final text = qty == qty.roundToDouble()
          ? qty.round().toString()
          : qty.toStringAsFixed(1);
      if (_qtyController.text != text) {
        _qtyController.text = text;
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.food.nutrition;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(widget.food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.error, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              // Quantity input
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (v) {
                    final qty = double.tryParse(v);
                    if (qty != null && qty > 0) {
                      widget.onQuantityChanged(qty);
                    }
                  },
                ),
              ),
              const Gap(10),
              // Unit dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  // `value` keeps the field in sync with provider state; `initialValue` is read once.
                  // ignore: deprecated_member_use
                  value: AppConstants.foodUnits.contains(widget.food.unit)
                      ? widget.food.unit
                      : AppConstants.foodUnits.first,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                  items: AppConstants.foodUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) widget.onUnitChanged(v);
                  },
                ),
              ),
            ],
          ),
          const Gap(12),
          // Nutrition row
          Row(
            children: [
              _NutriBadge('${n.calories.round()}', 'kcal', AppTheme.calColor),
              const Gap(8),
              _NutriBadge('${n.protein.round()}g', 'P', AppTheme.proteinColor),
              const Gap(8),
              _NutriBadge('${n.carbs.round()}g', 'C', AppTheme.carbsColor),
              const Gap(8),
              _NutriBadge('${n.fat.round()}g', 'F', AppTheme.fatColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutriBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _NutriBadge(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            TextSpan(
              text: ' $label',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Total Chip ────────────────────────────────────────────────────────────

class _TotalChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final String suffix;

  const _TotalChip({
    required this.label,
    required this.value,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        Text(
          '$value$suffix',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}

// ─── Explanation Card ──────────────────────────────────────────────────────

class _ExplanationCard extends StatelessWidget {
  final String explanation;

  const _ExplanationCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.primary.withValues(alpha: 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Insight',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                const Gap(4),
                Text(explanation,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
