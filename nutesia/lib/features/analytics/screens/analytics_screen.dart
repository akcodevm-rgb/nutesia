import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/constants/credit_constants.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/credit_chip.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final trendPoints = ref.watch(dailyTrendPointsProvider);
    final logsAsync = ref.watch(historicalLogsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Analytics & Trends'),
        actions: [
          const Center(child: CreditChip()),
          const Gap(8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(historicalLogsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: logsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to load analytics data: $err',
                style: const TextStyle(color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (logs) {
            final hasData = trendPoints.any((pt) => pt.nutrition.calories > 0);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(ref, period),
                  const Gap(20),
                  if (!hasData) ...[
                    _buildEmptyStateCard(context),
                  ] else ...[
                    _buildCalorieTrendChart(context, trendPoints, ref),
                    const Gap(20),
                    _buildMacroAverages(context, trendPoints),
                    const Gap(20),
                    _buildMicronutrientStatus(context, trendPoints, ref),
                    const Gap(20),
                    _buildAiDeficiencyPredictor(context, ref, trendPoints),
                    const Gap(24),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Period Selector ────────────────────────────────────────────────────────

  Widget _buildPeriodSelector(WidgetRef ref, AnalyticsPeriod selected) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(analyticsPeriodProvider.notifier).state =
                  AnalyticsPeriod.weekly,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected == AnalyticsPeriod.weekly
                      ? AppTheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == AnalyticsPeriod.weekly
                        ? AppTheme.primary.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '7 Days (Weekly)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected == AnalyticsPeriod.weekly
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(analyticsPeriodProvider.notifier).state =
                  AnalyticsPeriod.monthly,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected == AnalyticsPeriod.monthly
                      ? AppTheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == AnalyticsPeriod.monthly
                        ? AppTheme.primary.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '30 Days (Monthly)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected == AnalyticsPeriod.monthly
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State Card ──────────────────────────────────────────────────────

  Widget _buildEmptyStateCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      borderColor: AppTheme.cardBorder,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppTheme.primary,
            ),
          ),
          const Gap(20),
          Text(
            'No Data Logged Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(10),
          Text(
            'Start logging your meals on the Home tab. Once you log daily intake, weekly and monthly nutrition analysis will populate here!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  // ─── Calorie Trend Chart ───────────────────────────────────────────────────

  Widget _buildCalorieTrendChart(
    BuildContext context,
    List<DailyTrendPoint> points,
    WidgetRef ref,
  ) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final calorieTarget = userProfile?.dailyTargets.calories ?? 2000.0;

    // Find max value in list to scale heights
    double maxVal = calorieTarget;
    for (final pt in points) {
      if (pt.nutrition.calories > maxVal) {
        maxVal = pt.nutrition.calories;
      }
    }
    // Give some breathing room at the top
    maxVal *= 1.1;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calorie Intake History',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const Gap(4),
                  const Text('Daily Intake vs. Target',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.calColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Goal: ${calorieTarget.round()} kcal',
                  style: const TextStyle(
                      color: AppTheme.calColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
          const Gap(24),
          // Chart view
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((pt) {
                final heightPct =
                    (pt.nutrition.calories / maxVal).clamp(0.05, 1.0);
                final metTarget = pt.nutrition.calories >= calorieTarget;
                final isToday = pt.dateKey == AppDateUtils.todayKey();

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barHeight = constraints.maxHeight * heightPct;
                            return Tooltip(
                              message:
                                  '${AppDateUtils.toShort(pt.date)}: ${pt.nutrition.calories.round()} kcal',
                              triggerMode: TooltipTriggerMode.tap,
                              child: Container(
                                width: points.length > 7 ? 6 : 14,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isToday
                                        ? [
                                            AppTheme.primary,
                                            AppTheme.primaryLight
                                          ]
                                        : metTarget
                                            ? [
                                                AppTheme.calColor,
                                                AppTheme.warning
                                              ]
                                            : [
                                                AppTheme.calColor
                                                    .withOpacity(0.5),
                                                AppTheme.calColor
                                              ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: isToday
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primary
                                                .withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, -2),
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Gap(8),
                      // Date label
                      Text(
                        points.length > 7
                            ? (pt.date.day % 5 == 0 || isToday
                                ? '${pt.date.day}'
                                : '')
                            : AppDateUtils.toWeekday(pt.date).substring(0, 3),
                        style: TextStyle(
                          color: isToday
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Macro Averages ────────────────────────────────────────────────────────

  Widget _buildMacroAverages(
      BuildContext context, List<DailyTrendPoint> points) {
    // Filter to only days where calorie > 0 (to get a representative average of actual eating days)
    final activeDays = points.where((pt) => pt.nutrition.calories > 0).toList();
    final count = activeDays.isEmpty ? 1 : activeDays.length;

    double avgProtein = 0;
    double avgCarbs = 0;
    double avgFat = 0;

    for (final pt in activeDays) {
      avgProtein += pt.nutrition.protein;
      avgCarbs += pt.nutrition.carbs;
      avgFat += pt.nutrition.fat;
    }

    avgProtein /= count;
    avgCarbs /= count;
    avgFat /= count;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Average Macronutrient Intake',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Gap(16),
          Row(
            children: [
              _buildMacroProgress(
                  context, 'Protein', avgProtein, 'g', AppTheme.proteinColor),
              const Gap(12),
              _buildMacroProgress(
                  context, 'Carbs', avgCarbs, 'g', AppTheme.carbsColor),
              const Gap(12),
              _buildMacroProgress(
                  context, 'Fat', avgFat, 'g', AppTheme.fatColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress(
    BuildContext context,
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            const Gap(4),
            Text(
              '${value.round()}$unit',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Micronutrient Grid ─────────────────────────────────────────────────────

  Widget _buildMicronutrientStatus(
    BuildContext context,
    List<DailyTrendPoint> points,
    WidgetRef ref,
  ) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    if (userProfile == null) return const SizedBox.shrink();

    // Average micronutrients over all range days
    final daysCount = points.length;
    double totalVitA = 0;
    double totalVitC = 0;
    double totalVitD = 0;
    double totalCalcium = 0;
    double totalIron = 0;
    double totalZinc = 0;
    double totalMagnesium = 0;

    for (final pt in points) {
      totalVitA += pt.nutrition.vitamins.vitaminA;
      totalVitC += pt.nutrition.vitamins.vitaminC;
      totalVitD += pt.nutrition.vitamins.vitaminD;
      totalCalcium += pt.nutrition.minerals.calcium;
      totalIron += pt.nutrition.minerals.iron;
      totalZinc += pt.nutrition.minerals.zinc;
      totalMagnesium += pt.nutrition.minerals.magnesium;
    }

    final avgVitA = totalVitA / daysCount;
    final avgVitC = totalVitC / daysCount;
    final avgVitD = totalVitD / daysCount;
    final avgCalcium = totalCalcium / daysCount;
    final avgIron = totalIron / daysCount;
    final avgZinc = totalZinc / daysCount;
    final avgMagnesium = totalMagnesium / daysCount;

    final targets = userProfile.dailyTargets;

    // Helper map of key micro nutrients to track
    final microData = [
      _MicroItem('Vitamin C', avgVitC, targets.vitamins.vitaminC, 'mg'),
      _MicroItem('Iron', avgIron, targets.minerals.iron, 'mg'),
      _MicroItem('Calcium', avgCalcium, targets.minerals.calcium, 'mg'),
      _MicroItem('Vitamin D', avgVitD, targets.vitamins.vitaminD, 'mcg'),
      _MicroItem('Magnesium', avgMagnesium, targets.minerals.magnesium, 'mg'),
      _MicroItem('Vitamin A', avgVitA, targets.vitamins.vitaminA, 'mcg'),
      _MicroItem('Zinc', avgZinc, targets.minerals.zinc, 'mg'),
    ];

    // Count how many are critically low (<70%)
    final lowCount = microData.where((m) => m.pct < 0.7).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Micronutrient Health',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (lowCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$lowCount Low Nutrients',
                  style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const Gap(12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: microData.length,
            separatorBuilder: (c, i) => const Gap(10),
            itemBuilder: (context, index) {
              final m = microData[index];
              final isLow = m.pct < 0.7;

              return Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isLow ? AppTheme.error.withOpacity(0.04) : AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLow
                        ? AppTheme.error.withOpacity(0.3)
                        : AppTheme.cardBorder,
                    width: isLow ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLow ? AppTheme.error : AppTheme.textPrimary,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${m.avg.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isLow ? AppTheme.error : AppTheme.primary,
                                ),
                              ),
                              TextSpan(
                                text: ' / ${m.target.round()}${m.unit}',
                                style: const TextStyle(
                                    fontSize: 9, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Gap(4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: m.pct.clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: isLow
                                ? AppTheme.error.withOpacity(0.15)
                                : AppTheme.primary.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(
                              isLow ? AppTheme.error : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── AI Deficiency Predictor Panel ──────────────────────────────────────────

  Widget _buildAiDeficiencyPredictor(
    BuildContext context,
    WidgetRef ref,
    List<DailyTrendPoint> points,
  ) {
    final state = ref.watch(deficiencyAnalysisProvider);
    final period = ref.watch(analyticsPeriodProvider);
    final periodStr = period == AnalyticsPeriod.weekly ? 'Weekly' : 'Monthly';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppTheme.primary.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined,
                    color: AppTheme.primary, size: 22),
              ),
              const Gap(10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Deficiency Prediction',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Analyzes vitamin & mineral intake gaps',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    )
                  ],
                ),
              )
            ],
          ),
          const Gap(16),
          if (state.isLoading) ...[
            _buildLoadingState(),
          ] else if (state.error != null) ...[
            Text('Analysis error: ${state.error}',
                style: const TextStyle(color: AppTheme.error)),
            const Gap(12),
            if (state.requiredCredits != null && state.currentCredits != null)
              ElevatedButton.icon(
                onPressed: () => showNotEnoughCreditsDialog(
                  context: context,
                  ref: ref,
                  requiredCredits: state.requiredCredits!,
                  currentCredits: state.currentCredits!,
                  featureName: 'deficiency analysis',
                ),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text('Watch Ad'),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  final creditState = ref.read(creditProvider).valueOrNull;
                  final currentCredits = creditState?.creditBalance ?? 0;
                  if (currentCredits < CreditConstants.deficiencyAnalysisCost) {
                    await showNotEnoughCreditsDialog(
                      context: context,
                      ref: ref,
                      requiredCredits: CreditConstants.deficiencyAnalysisCost,
                      currentCredits: currentCredits,
                      featureName: 'deficiency analysis',
                    );
                    return;
                  }
                  ref.read(deficiencyAnalysisProvider.notifier).runAnalysis();
                },
                child: const Text('Try Again 🔮'),
              ),
          ] else if (state.result != null) ...[
            _buildResultsView(context, state.result!),
          ] else ...[
            // Call to Action
            const Text(
              'Your eating logs contain critical clues about your micronutrient health. Let NutoAI scan your nutritional timelines to predict potential vitamin/mineral deficiencies and symptoms.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: () async {
                final creditState = ref.read(creditProvider).valueOrNull;
                final currentCredits = creditState?.creditBalance ?? 0;
                if (currentCredits < CreditConstants.deficiencyAnalysisCost) {
                  await showNotEnoughCreditsDialog(
                    context: context,
                    ref: ref,
                    requiredCredits: CreditConstants.deficiencyAnalysisCost,
                    currentCredits: currentCredits,
                    featureName: 'deficiency analysis',
                  );
                  return;
                }
                ref.read(deficiencyAnalysisProvider.notifier).runAnalysis();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text('Run $periodStr AI Deficiency Scan 🔮'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const Gap(16),
            Text(
              'Running Clinical Model...',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            const Gap(4),
            Text(
              'Scanning micronutrient intake patterns...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeOut(duration: 1000.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(BuildContext context, Map<String, dynamic> data) {
    final riskLevel = data['riskLevel'] as String? ?? 'Low';
    final summary = data['summary'] as String? ?? '';
    final deficienciesList = data['deficiencies'] as List<dynamic>? ?? [];
    final recommendations = data['recommendations'] as List<dynamic>? ?? [];

    Color riskColor = AppTheme.primary;
    if (riskLevel.toLowerCase() == 'high') {
      riskColor = AppTheme.error;
    } else if (riskLevel.toLowerCase() == 'moderate') {
      riskColor = AppTheme.warning;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Risk level header
        Row(
          children: [
            const Text('Deficiency Risk Level: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withOpacity(0.4)),
              ),
              child: Text(
                '$riskLevel Risk',
                style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
              ),
            ),
          ],
        ),
        const Gap(12),
        // Clinical summary
        Text(
          summary,
          style: const TextStyle(
              fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
        ),
        const Gap(16),
        const Divider(),
        const Gap(12),

        // Deficiencies list
        if (deficienciesList.isNotEmpty) ...[
          const Text('Predicted Gaps & Risks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Gap(10),
          ...deficienciesList.map((d) {
            final def = d as Map<String, dynamic>;
            final nutrient = def['nutrient'] as String? ?? '';
            final prob = def['probability'] as String? ?? 'Moderate';
            final explanation = def['explanation'] as String? ?? '';
            final symptoms = (def['symptoms'] as List<dynamic>?)
                    ?.map((s) => s.toString())
                    .toList() ??
                [];

            Color probColor = AppTheme.primary;
            if (prob.toLowerCase() == 'high')
              probColor = AppTheme.error;
            else if (prob.toLowerCase() == 'moderate')
              probColor = AppTheme.warning;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(nutrient,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        '$prob Prob',
                        style: TextStyle(
                            color: probColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10),
                      ),
                    ],
                  ),
                  const Gap(6),
                  Text(explanation,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.3)),
                  if (symptoms.isNotEmpty) ...[
                    const Gap(8),
                    const Text('Watch out for symptoms:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: AppTheme.textMuted)),
                    const Gap(4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: symptoms
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: AppTheme.cardBorder),
                                ),
                                child: Text(s,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.textSecondary)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
          const Gap(10),
        ],

        // Recommendations list
        if (recommendations.isNotEmpty) ...[
          const Divider(),
          const Gap(12),
          const Text('Recommended Dietary Additions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Gap(10),
          ...recommendations.map((r) {
            final rec = r as Map<String, dynamic>;
            final food = rec['food'] as String? ?? '';
            final reason = rec['reason'] as String? ?? '';
            final tips = rec['tips'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        color: AppTheme.primary, size: 16),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(food,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.primary)),
                        const Gap(2),
                        Text(reason,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                height: 1.3)),
                        if (tips.isNotEmpty) ...[
                          const Gap(4),
                          Text('Tip: $tips',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textMuted)),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _MicroItem {
  final String name;
  final double avg;
  final double target;
  final String unit;

  _MicroItem(this.name, this.avg, this.target, this.unit);

  double get pct => target > 0 ? avg / target : 0.0;
}
