import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../shared/widgets/credit_chip.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/analytics_provider.dart';
import 'skeuo_widgets.dart';
import '../../../shared/widgets/error_views/error_views.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        final period = analytics.period;
        final trendPoints = analytics.trendPoints;
        final isLoading = analytics.isLoadingLogs;
        final error = analytics.logsError;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Clinical Analytics & Trends'),
            actions: [
              const Center(child: CreditChip()),
              const Gap(8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => analytics.refresh(),
              ),
            ],
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (isLoading && trendPoints.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (error != null && trendPoints.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: AppErrorCard(
                        error: ErrorParser.parse(error),
                        onAction: () => analytics.refresh(),
                      ),
                    ),
                  );
                }

                final hasData = trendPoints.any((pt) => pt.nutrition.calories > 0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(analytics, period),
                      const Gap(24),
                      if (!hasData) ...[
                        _buildEmptyStateCard(context),
                      ] else ...[
                        _buildCalorieTrendChart(context, trendPoints),
                        const Gap(24),
                        _buildMacroAverages(context, trendPoints),
                        const Gap(24),
                        _buildMicronutrientStatus(context, trendPoints),
                        const Gap(24),
                        _buildAiDeficiencyPredictor(context, analytics, trendPoints),
                        const Gap(32),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ─── Period Selector ────────────────────────────────────────────────────────

  Widget _buildPeriodSelector(AnalyticsProvider analytics, AnalyticsPeriod selected) {
    return SkeuoToggle(
      options: const ['7 Days (Weekly)', '30 Days (Monthly)'],
      selectedIndex: selected == AnalyticsPeriod.weekly ? 0 : 1,
      onChanged: (index) {
        analytics.setPeriod(
          index == 0 ? AnalyticsPeriod.weekly : AnalyticsPeriod.monthly,
        );
      },
    );
  }

  // ─── Empty State Card ──────────────────────────────────────────────────────

  Widget _buildEmptyStateCard(BuildContext context) {
    return SkeuoCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
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
          const Text(
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
  ) {
    final userProfile = context.watch<UserProfileProvider>().user;
    final calorieTarget = userProfile?.dailyTargets.calories ?? 2000.0;

    return SkeuoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calorie Intake History',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Gap(4),
                  Text('Daily Intake vs. Target',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.calColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Goal: ${calorieTarget.round()} kcal',
                  style: const TextStyle(
                      color: AppTheme.calColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const Gap(24),
          SkeuoLineChart(
            values1: points.map((pt) => pt.nutrition.calories).toList(),
            values2: points.map((pt) => calorieTarget).toList(),
            targetValue: calorieTarget,
            labels: points.map((pt) {
              final isToday = pt.dateKey == AppDateUtils.todayKey();
              if (isToday) return 'Today';
              return points.length > 7
                  ? '${pt.date.day}'
                  : AppDateUtils.toWeekday(pt.date).substring(0, 3);
            }).toList(),
            tooltipLabel: 'kcal',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Macro Averages ────────────────────────────────────────────────────────

  Widget _buildMacroAverages(
    BuildContext context,
    List<DailyTrendPoint> points,
  ) {
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

    final userProfile = context.watch<UserProfileProvider>().user;
    final targets = userProfile?.dailyTargets;
    final proteinTarget = targets?.protein ?? 120.0;
    final carbsTarget = targets?.carbs ?? 250.0;
    final fatTarget = targets?.fat ?? 70.0;

    return SkeuoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Avg Macronutrient Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SkeuoDial(
                percent: proteinTarget > 0 ? avgProtein / proteinTarget : 0.0,
                title: 'Protein',
                valueText: '${avgProtein.round()}g',
                activeColor: AppTheme.proteinColor,
              ),
              SkeuoDial(
                percent: carbsTarget > 0 ? avgCarbs / carbsTarget : 0.0,
                title: 'Carbs',
                valueText: '${avgCarbs.round()}g',
                activeColor: AppTheme.carbsColor,
              ),
              SkeuoDial(
                percent: fatTarget > 0 ? avgFat / fatTarget : 0.0,
                title: 'Fat',
                valueText: '${avgFat.round()}g',
                activeColor: AppTheme.fatColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Micronutrient Grid ─────────────────────────────────────────────────────

  Widget _buildMicronutrientStatus(
    BuildContext context,
    List<DailyTrendPoint> points,
  ) {
    final userProfile = context.watch<UserProfileProvider>().user;
    if (userProfile == null) return const SizedBox.shrink();

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

    final microData = [
      _MicroItem('Vitamin C', avgVitC, targets.vitamins.vitaminC, 'mg'),
      _MicroItem('Iron', avgIron, targets.minerals.iron, 'mg'),
      _MicroItem('Calcium', avgCalcium, targets.minerals.calcium, 'mg'),
      _MicroItem('Vitamin D', avgVitD, targets.vitamins.vitaminD, 'mcg'),
      _MicroItem('Magnesium', avgMagnesium, targets.minerals.magnesium, 'mg'),
      _MicroItem('Vitamin A', avgVitA, targets.vitamins.vitaminA, 'mcg'),
      _MicroItem('Zinc', avgZinc, targets.minerals.zinc, 'mg'),
    ];

    final lowCount = microData.where((m) => m.pct < 0.7).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Micronutrient Health Indicators',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (lowCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$lowCount Low',
                  style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const Gap(12),
        SizedBox(
          height: 125,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: microData.length,
            separatorBuilder: (c, i) => const Gap(12),
            itemBuilder: (context, index) {
              final m = microData[index];
              final isLow = m.pct < 0.7;

              return SkeuoCard(
                baseColor:
                    isLow ? const Color(0xFF1E0E14) : const Color(0xFF0F1524),
                borderRadius: 16,
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              m.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLow
                                    ? AppTheme.error
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLow ? AppTheme.error : AppTheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isLow ? AppTheme.error : AppTheme.primary,
                                  blurRadius: 3,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: m.avg.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isLow
                                        ? AppTheme.error
                                        : AppTheme.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${m.target.round()}${m.unit}',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Gap(6),
                          SkeuoProgress(
                            value: m.pct,
                            color: isLow ? AppTheme.error : AppTheme.primary,
                            height: 8,
                          ),
                        ],
                      )
                    ],
                  ),
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
    AnalyticsProvider analytics,
    List<DailyTrendPoint> points,
  ) {
    final state = analytics.deficiencyState;
    final period = analytics.period;
    final periodStr = period == AnalyticsPeriod.weekly ? 'Weekly' : 'Monthly';
    final creditProvider = context.read<CreditProvider>();
    final profileProvider = context.read<UserProfileProvider>();

    return SkeuoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.psychology_outlined,
                    color: AppTheme.primary, size: 24),
              ),
              const Gap(12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Deficiency Diagnostic',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Bio-nutritional Timeline Analysis',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              )
            ],
          ),
          const Gap(20),
          if (state.isLoading) ...[
            _buildLoadingState(),
          ] else if (state.error != null) ...[
            AppErrorCard(
              error: ErrorParser.parse(state.error),
              customActionLabel: (state.requiredCredits != null && state.currentCredits != null)
                  ? 'Watch Ad (+1 Credit)'
                  : 'Try Again 🔮',
              onAction: () {
                if (state.requiredCredits != null && state.currentCredits != null) {
                  showNotEnoughCreditsDialog(
                    context: context,
                    requiredCredits: state.requiredCredits!,
                    currentCredits: state.currentCredits!,
                    featureName: 'deficiency analysis',
                  );
                } else {
                  analytics.runDeficiencyAnalysis(
                    creditProvider: creditProvider,
                    profileProvider: profileProvider,
                  );
                }
              },
            ),
          ] else if (state.result != null) ...[
            _buildResultsView(context, state.result!),
          ] else ...[
            const Text(
              'Your eating logs contain critical clues about your micronutrient health. Let NutesiaAI scan your nutritional timelines to predict potential vitamin/mineral deficiencies and symptoms.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
            const Gap(20),
            ElevatedButton(
              onPressed: () => analytics.runDeficiencyAnalysis(
                creditProvider: creditProvider,
                profileProvider: profileProvider,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Run $periodStr Diagnostic Scan 🔮'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const SkeuoRadar(),
            const Gap(16),
            const Text(
              'SCANNING TIMELINE...',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2),
            ),
            const Gap(4),
            const Text(
              'Scanning micronutrient intake patterns...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
        Row(
          children: [
            const Text('Deficiency Risk Level: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withValues(alpha: 0.4)),
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
        Text(
          summary,
          style: const TextStyle(
              fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
        ),
        const Gap(16),
        const Divider(),
        const Gap(12),
        if (deficienciesList.isNotEmpty) ...[
          const Text('Predicted Gaps & Risks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Gap(10),
          ...deficienciesList.map((d) {
            final def = d as Map<String, dynamic>;
            final nutrient = def['nutrient']?.toString() ?? '';
            final rawProb = def['probability'];
            String prob = 'Moderate';
            double? numericProb;
            if (rawProb is num) {
              numericProb = rawProb.toDouble();
              if (numericProb <= 1.0) {
                prob = '${(numericProb * 100).toStringAsFixed(0)}%';
              } else {
                prob = '${numericProb.toStringAsFixed(0)}%';
              }
            } else if (rawProb is String) {
              prob = rawProb;
              final parsed = double.tryParse(rawProb.replaceAll('%', ''));
              if (parsed != null) {
                numericProb = parsed;
                if (!rawProb.contains('%')) {
                  if (numericProb <= 1.0) {
                    prob = '${(numericProb * 100).toStringAsFixed(0)}%';
                  } else {
                    prob = '${numericProb.toStringAsFixed(0)}%';
                  }
                }
              }
            }
            final explanation = def['explanation']?.toString() ?? '';
            final symptoms = (def['symptoms'] as List<dynamic>?)
                    ?.map((s) => s.toString())
                    .toList() ??
                [];

            Color probColor = AppTheme.primary;
            if (numericProb != null) {
              final checkVal = numericProb > 1.0 ? numericProb / 100.0 : numericProb;
              if (checkVal >= 0.7) {
                probColor = AppTheme.error;
              } else if (checkVal >= 0.4) {
                probColor = AppTheme.warning;
              }
            } else {
              if (prob.toLowerCase() == 'high') {
                probColor = AppTheme.error;
              } else if (prob.toLowerCase() == 'moderate') {
                probColor = AppTheme.warning;
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card.withValues(alpha: 0.5),
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
                      color: AppTheme.primary.withValues(alpha: 0.08),
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

  double get pct => target > 0 ? (avg / target).clamp(0.0, 1.0) : 0.0;
}
