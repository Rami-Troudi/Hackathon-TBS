import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class SeniorNutritionData {
  const SeniorNutritionData({
    required this.seniorId,
    required this.state,
    required this.recentEvents,
  });

  final String? seniorId;
  final NutritionState state;
  final List<PersistedEventRecord> recentEvents;
}

final seniorNutritionDataProvider =
    FutureProvider.autoDispose<SeniorNutritionData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final repository = ref.watch(nutritionRepositoryProvider);
  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const SeniorNutritionData(
      seniorId: null,
      state: NutritionState(slots: <MealSlotState>[]),
      recentEvents: <PersistedEventRecord>[],
    );
  }

  final state =
      await repository.getTodayState(seniorId, reconcileMissedMeals: true);
  final recent = await repository.fetchRecentMealEvents(seniorId);
  return SeniorNutritionData(
    seniorId: seniorId,
    state: state,
    recentEvents: recent,
  );
});

class GuardianNutritionMonitoringData {
  const GuardianNutritionMonitoringData({
    required this.seniorId,
    required this.seniorProfile,
    required this.todayState,
    required this.completedLast7Days,
    required this.missedLast7Days,
    required this.recentEvents,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final NutritionState todayState;
  final int completedLast7Days;
  final int missedLast7Days;
  final List<PersistedEventRecord> recentEvents;
}

final guardianNutritionMonitoringDataProvider =
    FutureProvider.autoDispose<GuardianNutritionMonitoringData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final nutritionRepository = ref.watch(nutritionRepositoryProvider);

  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const GuardianNutritionMonitoringData(
      seniorId: null,
      seniorProfile: null,
      todayState: NutritionState(slots: <MealSlotState>[]),
      completedLast7Days: 0,
      missedLast7Days: 0,
      recentEvents: <PersistedEventRecord>[],
    );
  }

  final profile = await profileRepository.getSeniorProfileById(seniorId);
  final todayState = await nutritionRepository.getTodayState(seniorId,
      reconcileMissedMeals: true);
  final recent = await nutritionRepository.fetchRecentMealEvents(
    seniorId,
    limit: 120,
  );
  final sevenDaysAgo =
      DateTime.now().toLocal().subtract(const Duration(days: 7));
  final trend = recent.where(
    (event) => event.happenedAt.toLocal().isAfter(sevenDaysAgo),
  );
  final completed =
      trend.where((event) => event.type == AppEventType.mealCompleted).length;
  final missed =
      trend.where((event) => event.type == AppEventType.mealMissed).length;

  return GuardianNutritionMonitoringData(
    seniorId: seniorId,
    seniorProfile: profile,
    todayState: todayState,
    completedLast7Days: completed,
    missedLast7Days: missed,
    recentEvents: recent,
  );
});
