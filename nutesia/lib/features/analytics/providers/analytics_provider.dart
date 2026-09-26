import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/credit_constants.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/models/nutrition_model.dart';

enum AnalyticsPeriod { weekly, monthly }

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.weekly);

// Raw historical logs fetched from Firestore for the range
final historicalLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final period = ref.watch(analyticsPeriodProvider);
  final firestore = ref.read(firestoreServiceProvider);
  final deviceId = await DeviceService.getDeviceId();

  final now = DateTime.now();
  final daysCount = period == AnalyticsPeriod.weekly ? 7 : 30;
  final startDate = now.subtract(Duration(days: daysCount - 1));

  final startKey = AppDateUtils.toKey(startDate);
  final endKey = AppDateUtils.toKey(now);

  return firestore.getDailyLogsForRange(
    deviceId: deviceId,
    startDateKey: startKey,
    endDateKey: endKey,
  );
});

// A structured view of the past 7/30 days, filling in missing days with empty values
class DailyTrendPoint {
  final DateTime date;
  final String dateKey;
  final NutritionData nutrition;
  final List<dynamic> entries; // raw list of maps

  DailyTrendPoint({
    required this.date,
    required this.dateKey,
    required this.nutrition,
    required this.entries,
  });
}

final dailyTrendPointsProvider =
    Provider.autoDispose<List<DailyTrendPoint>>((ref) {
  final period = ref.watch(analyticsPeriodProvider);
  final logsAsync = ref.watch(historicalLogsProvider);

  return logsAsync.maybeWhen(
    data: (logs) {
      final logsMap = {for (var log in logs) log['date'] as String: log};

      final now = DateTime.now();
      final daysCount = period == AnalyticsPeriod.weekly ? 7 : 30;
      final points = <DailyTrendPoint>[];

      for (int i = daysCount - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = AppDateUtils.toKey(date);

        final log = logsMap[dateKey];
        if (log != null) {
          final nutrition = NutritionData.fromJson(
              log['totalNutrition'] as Map<String, dynamic>);
          final entries = log['entries'] as List<dynamic>? ?? [];
          points.add(DailyTrendPoint(
            date: date,
            dateKey: dateKey,
            nutrition: nutrition,
            entries: entries,
          ));
        } else {
          points.add(DailyTrendPoint(
            date: date,
            dateKey: dateKey,
            nutrition: const NutritionData(),
            entries: const [],
          ));
        }
      }
      return points;
    },
    orElse: () => [],
  );
});

// State for AI deficiency prediction
class DeficiencyAnalysisState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;
  final int? requiredCredits;
  final int? currentCredits;

  DeficiencyAnalysisState({
    this.isLoading = false,
    this.error,
    this.result,
    this.requiredCredits,
    this.currentCredits,
  });

  DeficiencyAnalysisState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? result,
    int? requiredCredits,
    int? currentCredits,
  }) {
    return DeficiencyAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
      requiredCredits: requiredCredits ?? this.requiredCredits,
      currentCredits: currentCredits ?? this.currentCredits,
    );
  }
}

class DeficiencyAnalysisNotifier
    extends StateNotifier<DeficiencyAnalysisState> {
  final Ref _ref;
  final AIService _aiService = AIService();

  DeficiencyAnalysisNotifier(this._ref) : super(DeficiencyAnalysisState()) {
    // Reset analysis result when the time period changes
    _ref.listen<AnalyticsPeriod>(analyticsPeriodProvider, (_, _) {
      reset();
    });
  }

  Future<void> runAnalysis() async {
    final userProfileAsync = _ref.read(userProfileProvider);
    final user = userProfileAsync.valueOrNull;
    if (user == null) {
      state = DeficiencyAnalysisState(error: 'User profile not set up yet.');
      return;
    }

    final trendPoints = _ref.read(dailyTrendPointsProvider);
    if (trendPoints.isEmpty) {
      state = DeficiencyAnalysisState(
          error: 'No nutritional logs found in this period.');
      return;
    }

    state = state.copyWith(isLoading: true);
    var charged = false;

    try {
      await _ref.read(creditProvider.notifier).spend(
            amount: CreditConstants.deficiencyAnalysisCost,
            reason: 'deficiency_analysis',
          );
      charged = true;

      final period = _ref.read(analyticsPeriodProvider);
      final periodStr = period == AnalyticsPeriod.weekly ? '7 Days' : '30 Days';

      final daysCount = trendPoints.length;

      // Collect micro nutrient totals
      double totalVitA = 0;
      double totalVitB1 = 0;
      double totalVitB2 = 0;
      double totalVitB6 = 0;
      double totalVitB12 = 0;
      double totalVitC = 0;
      double totalVitD = 0;
      double totalVitE = 0;
      double totalVitK = 0;
      double totalFolate = 0;
      double totalCalcium = 0;
      double totalIron = 0;
      double totalZinc = 0;
      double totalMagnesium = 0;
      double totalPotassium = 0;
      double totalSodium = 0;
      double totalPhosphorus = 0;

      final topFoodsSet = <String>{};

      for (final pt in trendPoints) {
        final v = pt.nutrition.vitamins;
        totalVitA += v.vitaminA;
        totalVitB1 += v.vitaminB1;
        totalVitB2 += v.vitaminB2;
        totalVitB6 += v.vitaminB6;
        totalVitB12 += v.vitaminB12;
        totalVitC += v.vitaminC;
        totalVitD += v.vitaminD;
        totalVitE += v.vitaminE;
        totalVitK += v.vitaminK;
        totalFolate += v.folate;

        final m = pt.nutrition.minerals;
        totalCalcium += m.calcium;
        totalIron += m.iron;
        totalZinc += m.zinc;
        totalMagnesium += m.magnesium;
        totalPotassium += m.potassium;
        totalSodium += m.sodium;
        totalPhosphorus += m.phosphorus;

        for (final entryMap in pt.entries) {
          if (entryMap is Map<String, dynamic> && entryMap['foods'] != null) {
            final foods = entryMap['foods'] as List<dynamic>;
            for (final food in foods) {
              if (food is Map<String, dynamic> && food['name'] != null) {
                topFoodsSet.add(food['name'] as String);
              }
            }
          }
        }
      }

      final averageIntake = {
        'vitaminA': totalVitA / daysCount,
        'vitaminB1': totalVitB1 / daysCount,
        'vitaminB2': totalVitB2 / daysCount,
        'vitaminB6': totalVitB6 / daysCount,
        'vitaminB12': totalVitB12 / daysCount,
        'vitaminC': totalVitC / daysCount,
        'vitaminD': totalVitD / daysCount,
        'vitaminE': totalVitE / daysCount,
        'vitaminK': totalVitK / daysCount,
        'folate': totalFolate / daysCount,
        'calcium': totalCalcium / daysCount,
        'iron': totalIron / daysCount,
        'zinc': totalZinc / daysCount,
        'magnesium': totalMagnesium / daysCount,
        'potassium': totalPotassium / daysCount,
        'sodium': totalSodium / daysCount,
        'phosphorus': totalPhosphorus / daysCount,
      };

      final targets = user.dailyTargets;
      final targetMap = {
        'vitaminA': targets.vitamins.vitaminA,
        'vitaminB1': targets.vitamins.vitaminB1,
        'vitaminB2': targets.vitamins.vitaminB2,
        'vitaminB6': targets.vitamins.vitaminB6,
        'vitaminB12': targets.vitamins.vitaminB12,
        'vitaminC': targets.vitamins.vitaminC,
        'vitaminD': targets.vitamins.vitaminD,
        'vitaminE': targets.vitamins.vitaminE,
        'vitaminK': targets.vitamins.vitaminK,
        'folate': targets.vitamins.folate,
        'calcium': targets.minerals.calcium,
        'iron': targets.minerals.iron,
        'zinc': targets.minerals.zinc,
        'magnesium': targets.minerals.magnesium,
        'potassium': targets.minerals.potassium,
        'sodium': targets.minerals.sodium,
        'phosphorus': targets.minerals.phosphorus,
      };

      final analysis = await _aiService.analyzeDeficiencies(
        user: user,
        period: periodStr,
        averageIntake: averageIntake,
        targets: targetMap,
        topFoods: topFoodsSet.take(15).toList(),
      );

      state = DeficiencyAnalysisState(result: analysis);
    } on CreditException catch (e) {
      state = DeficiencyAnalysisState(
        error: e.message,
        requiredCredits: e.requiredCredits,
        currentCredits: e.currentCredits,
      );
    } catch (e) {
      if (charged) {
        await _ref.read(creditProvider.notifier).refund(
              amount: CreditConstants.deficiencyAnalysisCost,
              reason: 'deficiency_analysis_failed',
            );
      }
      state = DeficiencyAnalysisState(error: e.toString());
    }
  }

  void reset() {
    state = DeficiencyAnalysisState();
  }
}

final deficiencyAnalysisProvider = StateNotifierProvider.autoDispose<
    DeficiencyAnalysisNotifier, DeficiencyAnalysisState>((ref) {
  return DeficiencyAnalysisNotifier(ref);
});
