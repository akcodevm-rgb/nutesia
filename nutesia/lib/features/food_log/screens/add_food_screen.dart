import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/credit_constants.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/food_log_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/credit_chip.dart';
import 'confirm_food_screen.dart';
import '../../../core/services/analytics_service.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _inputController = TextEditingController();
  String _selectedMeal = 'Breakfast';
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    // Default to current meal based on time
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMeal = 'Breakfast';
    } else if (hour < 15) {
      _selectedMeal = 'Lunch';
    } else if (hour < 20) {
      _selectedMeal = 'Dinner';
    } else {
      _selectedMeal = 'Snacks';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _inputController.text.trim();
    log('AddFoodScreen._analyze: Starting analysis for text: "$text"');
    if (text.isEmpty) {
      log('AddFoodScreen._analyze: Text is empty, showing snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what you ate'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final creditState = ref.read(creditProvider).valueOrNull;
    final currentCredits = creditState?.creditBalance ?? 0;
    if (currentCredits < CreditConstants.foodParseCost) {
      await showNotEnoughCreditsDialog(
        context: context,
        ref: ref,
        requiredCredits: CreditConstants.foodParseCost,
        currentCredits: currentCredits,
        featureName: 'food analysis',
      );
      return;
    }

    setState(() => _analyzing = true);
    FocusScope.of(context).unfocus();

    try {
      log('AddFoodScreen._analyze: Calling parse');
      final result = await ref.read(parsedFoodProvider.notifier).parse(text);

      // Log AI Parsing
      await AnalyticsService.instance.logAIFoodParse(inputLength: text.length);

      log('AddFoodScreen._analyze: Parse returned: ${result != null ? 'success' : 'null'}');
      if (result != null && mounted) {
        log('AddFoodScreen._analyze: Navigating to ConfirmFoodScreen');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmFoodScreen(
              rawInput: text,
              mealType: _selectedMeal,
            ),
          ),
        );
        log('AddFoodScreen._analyze: Returned from ConfirmFoodScreen, resetting');
        _inputController.clear();
      } else if (mounted) {
        Object? parseError;
        ref.read(parsedFoodProvider).whenOrNull(
              error: (error, _) => parseError = error,
            );

        if (parseError is CreditException) {
          final creditError = parseError as CreditException;
          await showNotEnoughCreditsDialog(
            context: context,
            ref: ref,
            requiredCredits: CreditConstants.foodParseCost,
            currentCredits: creditError.currentCredits,
            featureName: 'food analysis',
          );
          return;
        }

        log('AddFoodScreen._analyze: Parse failed, showing error snackbar');
        final errorMessage = parseError?.toString().replaceAll('Exception: ', '') ?? 'Failed to analyze the meal. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      log('AddFoodScreen._analyze: Exception caught: $e');
      log(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      log('AddFoodScreen._analyze: Finally block, setting analyzing to false');
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep provider alive while this screen is shown
    ref.watch(parsedFoodProvider);

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
                    final selected = _selectedMeal == meal;
                    final color = AppTheme.mealColor(meal);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMeal = meal),
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
              Text('Describe your meal naturally — amounts, items, anything.',
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
                    decoration: InputDecoration(
                      hintText:
                          'e.g. 2 eggs, chapati with dal, cup of milk...\n\nor\n\nChicken biryani and a banana',
                      hintStyle:
                          TextStyle(color: AppTheme.textMuted, height: 1.6),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),
              const Gap(16),

              // Example chips
              if (!_analyzing) ...[
                Text('Try these examples:',
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
              if (_analyzing)
                _AnalyzingWidget()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _analyze,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: const Text('Analyze with AI'),
                  ).animate().fadeIn(delay: 400.ms),
                ),
            ],
          ),
        ),
      ),
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
