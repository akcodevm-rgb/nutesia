import 'package:flutter/foundation.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/api_data_service.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/models/nutrition_model.dart';

enum AnalyticsPeriod { weekly, monthly }

class DailyTrendPoint {
  final DateTime date;
  final String dateKey;
  final NutritionData nutrition;
  final List<dynamic> entries;

  const DailyTrendPoint({
    required this.date,
    required this.dateKey,
    required this.nutrition,
    required this.entries,
  });
}

class DeficiencyAnalysisState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;
  final int? requiredCredits;
  final int? currentCredits;

  const DeficiencyAnalysisState({
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
  }) =>
      DeficiencyAnalysisState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        result: result ?? this.result,
        requiredCredits: requiredCredits ?? this.requiredCredits,
        currentCredits: currentCredits ?? this.currentCredits,
      );
}

class AnalyticsProvider extends ChangeNotifier {
  final ApiDataService _api;
  final AIService _ai;

  AnalyticsPeriod _period = AnalyticsPeriod.weekly;
  List<Map<String, dynamic>> _historicalLogs = [];
  bool _isLoadingLogs = false;
  String? _logsError;
  DeficiencyAnalysisState _deficiencyState = const DeficiencyAnalysisState();

  AnalyticsProvider({
    ApiDataService? api,
    AIService? ai,
  })  : _api = api ?? ApiDataService(),
        _ai = ai ?? AIService() {
    loadHistoricalLogs();
  }

  AnalyticsPeriod get period => _period;
  List<Map<String, dynamic>> get historicalLogs => _historicalLogs;
  bool get isLoadingLogs => _isLoadingLogs;
  String? get logsError => _logsError;
  DeficiencyAnalysisState get deficiencyState => _deficiencyState;

  List<DailyTrendPoint> get trendPoints {
    final byDate = {for (final log in _historicalLogs) log['date'] as String: log};
    final now = DateTime.now();
    final days = _period == AnalyticsPeriod.weekly ? 7 : 30;
    return List.generate(days, (index) {
      final date = now.subtract(Duration(days: days - index - 1));
      final dateKey = AppDateUtils.toKey(date);
      final log = byDate[dateKey];
      return DailyTrendPoint(
        date: date,
        dateKey: dateKey,
        nutrition: log == null
            ? const NutritionData()
            : NutritionData.fromJson(log['totalNutrition'] as Map<String, dynamic>),
        entries: log?['entries'] as List<dynamic>? ?? const [],
      );
    });
  }

  void setPeriod(AnalyticsPeriod newPeriod) {
    if (_period != newPeriod) {
      _period = newPeriod;
      _deficiencyState = const DeficiencyAnalysisState();
      notifyListeners();
      loadHistoricalLogs();
    }
  }

  Future<void> loadHistoricalLogs() async {
    _isLoadingLogs = true;
    _logsError = null;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: _period == AnalyticsPeriod.weekly ? 6 : 29));
      final logs = await _api.getDailyLogsForRange(
        deviceId: deviceId,
        startDateKey: AppDateUtils.toKey(start),
        endDateKey: AppDateUtils.toKey(now),
      );
      _historicalLogs = logs;
      _isLoadingLogs = false;
      notifyListeners();
    } catch (e) {
      _logsError = e.toString();
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  Future<void> runDeficiencyAnalysis({
    required CreditProvider creditProvider,
    required UserProfileProvider profileProvider,
  }) async {
    if (profileProvider.user == null) {
      _deficiencyState = const DeficiencyAnalysisState(error: 'User profile not set up yet.');
      notifyListeners();
      return;
    }

    _deficiencyState = _deficiencyState.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: _period == AnalyticsPeriod.weekly ? 6 : 29));
      final result = await _ai.analyzeDeficiencies(
        deviceId: await DeviceService.getDeviceId(),
        startDate: AppDateUtils.toKey(start),
        endDate: AppDateUtils.toKey(now),
      );
      await creditProvider.refresh();
      _deficiencyState = DeficiencyAnalysisState(result: result);
      notifyListeners();
    } on CreditException catch (e) {
      await creditProvider.refresh();
      _deficiencyState = DeficiencyAnalysisState(
        error: e.toString(),
        requiredCredits: 3,
        currentCredits: creditProvider.creditBalance,
      );
      notifyListeners();
    } catch (e) {
      _deficiencyState = DeficiencyAnalysisState(error: e.toString());
      notifyListeners();
    }
  }

  void resetDeficiency() {
    _deficiencyState = const DeficiencyAnalysisState();
    notifyListeners();
  }

  Future<void> refresh() => loadHistoricalLogs();
}
