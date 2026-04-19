import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/meal_state.dart';

abstract class NutritionRepository {
  Future<NutritionState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedMeals,
  });

  Future<bool> markMealCompleted(
    String seniorId, {
    required String mealId,
    DateTime? now,
  });

  Future<bool> markMealMissed(
    String seniorId, {
    required String mealId,
    DateTime? now,
  });

  Future<List<PersistedEventRecord>> fetchRecentMealEvents(
    String seniorId, {
    int limit,
  });
}
