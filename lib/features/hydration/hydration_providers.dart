import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class SeniorHydrationData {
  const SeniorHydrationData({
    required this.seniorId,
    required this.state,
    required this.recentEvents,
  });

  final String? seniorId;
  final HydrationState state;
  final List<PersistedEventRecord> recentEvents;
}

final seniorHydrationDataProvider =
    FutureProvider.autoDispose<SeniorHydrationData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final repository = ref.watch(hydrationRepositoryProvider);
  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const SeniorHydrationData(
      seniorId: null,
      state: HydrationState(
        slots: <HydrationSlotState>[],
        dailyGoalCompletions: 3,
      ),
      recentEvents: <PersistedEventRecord>[],
    );
  }

  final state = await repository.getTodayState(
    seniorId,
    reconcileMissedSlots: true,
  );
  final recent = await repository.fetchRecentHydrationEvents(seniorId);
  return SeniorHydrationData(
    seniorId: seniorId,
    state: state,
    recentEvents: recent,
  );
});

class GuardianHydrationMonitoringData {
  const GuardianHydrationMonitoringData({
    required this.seniorId,
    required this.seniorProfile,
    required this.todayState,
    required this.completedLast7Days,
    required this.missedLast7Days,
    required this.recentEvents,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final HydrationState todayState;
  final int completedLast7Days;
  final int missedLast7Days;
  final List<PersistedEventRecord> recentEvents;
}

final guardianHydrationMonitoringDataProvider =
    FutureProvider.autoDispose<GuardianHydrationMonitoringData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final hydrationRepository = ref.watch(hydrationRepositoryProvider);

  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const GuardianHydrationMonitoringData(
      seniorId: null,
      seniorProfile: null,
      todayState: HydrationState(
        slots: <HydrationSlotState>[],
        dailyGoalCompletions: 3,
      ),
      completedLast7Days: 0,
      missedLast7Days: 0,
      recentEvents: <PersistedEventRecord>[],
    );
  }

  final profile = await profileRepository.getSeniorProfileById(seniorId);
  final todayState = await hydrationRepository.getTodayState(
    seniorId,
    reconcileMissedSlots: true,
  );
  final recent = await hydrationRepository.fetchRecentHydrationEvents(
    seniorId,
    limit: 100,
  );
  final sevenDaysAgo =
      DateTime.now().toLocal().subtract(const Duration(days: 7));
  final trend = recent.where(
    (event) => event.happenedAt.toLocal().isAfter(sevenDaysAgo),
  );
  final completed = trend
      .where((event) => event.type == AppEventType.hydrationCompleted)
      .length;
  final missed =
      trend.where((event) => event.type == AppEventType.hydrationMissed).length;

  return GuardianHydrationMonitoringData(
    seniorId: seniorId,
    seniorProfile: profile,
    todayState: todayState,
    completedLast7Days: completed,
    missedLast7Days: missed,
    recentEvents: recent,
  );
});
