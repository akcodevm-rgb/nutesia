import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';
import '../../../core/constants/credit_constants.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/services/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

// ─── Parsed Food Notifier ──────────────────────────────────────────────────

class ParsedFoodNotifier extends StateNotifier<AsyncValue<ParsedFoodResult?>> {
  final AIService _ai;
  final Ref _ref;

  ParsedFoodNotifier(this._ai, this._ref) : super(const AsyncValue.data(null));

  Future<ParsedFoodResult?> parse(String input) async {
    log('ParsedFoodNotifier.parse: Starting parse for input: "$input"');
    state = const AsyncValue.loading();
    var charged = false;
    try {
      await _ref.read(creditProvider.notifier).spend(
            amount: CreditConstants.foodParseCost,
            reason: 'food_parse',
          );
      charged = true;

      final result = await _ai.parseFood(input);
      if (!mounted) return null;
      state = AsyncValue.data(result);
      log('ParsedFoodNotifier.parse: Parse successful, returning result');
      return result;
    } catch (e, st) {
      log('ParsedFoodNotifier.parse: Parse failed with error: $e');
      if (charged) {
        await _ref.read(creditProvider.notifier).refund(
              amount: CreditConstants.foodParseCost,
              reason: 'food_parse_failed',
            );
      }
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final parsedFoodProvider = StateNotifierProvider.autoDispose<ParsedFoodNotifier,
    AsyncValue<ParsedFoodResult?>>(
  (ref) => ParsedFoodNotifier(ref.read(aiServiceProvider), ref),
);
