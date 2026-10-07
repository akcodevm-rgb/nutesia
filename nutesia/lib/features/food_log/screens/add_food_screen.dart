import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/credit_constants.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/add_food_provider.dart';
import '../providers/confirm_food_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/credit_chip.dart';
import 'confirm_food_screen.dart';
import '../../../core/services/analytics_service.dart';
import '../../../shared/widgets/error_views/error_views.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _analyze(BuildContext context) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final addFood = context.read<AddFoodProvider>();
    final creditProvider = context.read<CreditProvider>();

    try {
      final result = await addFood.parseFood(text, creditProvider);
      if (result != null && context.mounted) {
        AnalyticsService.instance.logAIFoodParse(inputLength: text.length);
        context.read<ConfirmFoodProvider>().initFromParsed(result);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmFoodScreen(
              rawInput: text,
              mealType: addFood.selectedMeal,
            ),
          ),
        );
        _inputController.clear();
      } else if (context.mounted) {
        if (addFood.parseError is CreditException) {
          // The server refused for lack of credits: show the real balance.
          await creditProvider.refresh();
          if (!context.mounted) return;
          await showNotEnoughCreditsDialog(
            context: context,
            requiredCredits: CreditConstants.foodParseCost,
            currentCredits: creditProvider.creditBalance,
            featureName: 'food analysis',
          );
          return;
        }

        final parseError = addFood.appError ?? addFood.parseError;
        AppToast.showError(
          context,
          parseError,
          onAction: () => _analyze(context),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(
          context,
          e,
          onAction: () => _analyze(context),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddFoodProvider>(
      builder: (context, addFood, _) {
        final analyzing = addFood.isAnalyzing;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Log Food'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: CreditChip()),
              ),
            ],
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal selector
                  Text('Meal Type',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppTheme.textSecondary))
                      .animate()
                      .fadeIn(delay: 100.ms),
                  const Gap(10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.mealTypes.map((meal) {
                        final selected = addFood.selectedMeal == meal;
                        final color = AppTheme.mealColor(meal);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => addFood.setMeal(meal),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.15)
                                    : AppTheme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? color : AppTheme.cardBorder,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(_mealIcon(meal),
                                      size: 16,
                                      color: selected
                                          ? color
                                          : AppTheme.textSecondary),
                                  const Gap(6),
                                  Text(
                                    meal,
                                    style: TextStyle(
                                      color:
                                          selected ? color : AppTheme.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  const Gap(24),

                  // Input header
                  Text('What did you eat?',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold))
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const Gap(6),
                  const Text('Describe your meal naturally — amounts, items, anything.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13))
                      .animate()
                      .fadeIn(delay: 250.ms),
                  const Gap(14),

                  // Text input
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _inputController,
                        maxLines: null,
                        expands: true,
                        autofocus: true,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 16, height: 1.5),
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. 2 eggs, chapati with dal, cup of milk...\n\nor\n\nChicken biryani and a banana',
                          hintStyle:
                              TextStyle(color: AppTheme.textMuted, height: 1.6),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ),
                  const Gap(16),

                  // Example chips
                  if (!analyzing) ...[
                    const Text('Try these examples:',
                            style:
                                TextStyle(color: AppTheme.textMuted, fontSize: 12))
                        .animate()
                        .fadeIn(delay: 350.ms),
                    const Gap(8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _examples
                            .map((ex) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => _inputController.text = ex,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.card,
                                        borderRadius: BorderRadius.circular(20),
                                        border:
                                            Border.all(color: AppTheme.cardBorder),
                                      ),
                                      child: Text(ex,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ).animate().fadeIn(delay: 390.ms),
                    const Gap(16),
                  ],

                  // Analyze button
                  if (analyzing)
                    _AnalyzingWidget()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _analyze(context),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                        label: const Text('Analyze with AI'),
                      ).animate().fadeIn(delay: 400.ms),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const _examples = [
    '2 eggs and oats',
    'Chicken biryani',
    '3 idli with sambar',
    'Dal rice and roti',
    'Banana and milk',
  ];

  IconData _mealIcon(String meal) {
    switch (meal) {
      case 'Breakfast':
        return Icons.wb_sunny_outlined;
      case 'Lunch':
        return Icons.restaurant_rounded;
      case 'Dinner':
        return Icons.nights_stay_outlined;
      default:
        return Icons.apple;
    }
  }
}

class _AnalyzingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.card,
      highlightColor: AppTheme.primary.withValues(alpha: 0.2),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 20),
              Gap(10),
              Text('AI is analyzing your meal...',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
