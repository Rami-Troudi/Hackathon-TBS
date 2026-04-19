import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class GuardianCheckInMonitoringData {
  const GuardianCheckInMonitoringData({
    required this.seniorId,
    required this.seniorProfile,
    required this.todayState,
    required this.recentCheckInEvents,
    required this.completedInLast7Days,
    required this.missedInLast7Days,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final CheckInState todayState;
  final List<PersistedEventRecord> recentCheckInEvents;
  final int completedInLast7Days;
  final int missedInLast7Days;
}

final guardianCheckInMonitoringDataProvider =
    FutureProvider.autoDispose<GuardianCheckInMonitoringData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final checkInRepository = ref.watch(checkInRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);

  final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
  final now = DateTime.now();
  if (seniorId == null) {
    return GuardianCheckInMonitoringData(
      seniorId: null,
      seniorProfile: null,
      todayState: CheckInState(
        status: CheckInStatus.pending,
        windowLabel: 'Daily morning check-in',
        windowStart: DateTime(now.year, now.month, now.day, 8),
        windowEnd: DateTime(now.year, now.month, now.day, 12),
      ),
      recentCheckInEvents: const <PersistedEventRecord>[],
      completedInLast7Days: 0,
      missedInLast7Days: 0,
    );
  }

  final seniorProfile = await profileRepository.getSeniorProfileById(seniorId);
  final todayState = await checkInRepository.getTodayState(
    seniorId,
    reconcileMissedWindow: true,
  );
  final recentEvents = await checkInRepository.fetchRecentCheckIns(
    seniorId,
    limit: 20,
  );
  final trendEvents = await eventRepository.fetchTimelineForSenior(
    seniorId,
    order: TimelineOrder.newestFirst,
    types: const <AppEventType>{
      AppEventType.checkInCompleted,
      AppEventType.checkInMissed,
    },
    limit: 120,
  );
  final sevenDaysAgo = now.toLocal().subtract(const Duration(days: 7));
  final eventsInWindow = trendEvents.where(
    (event) => event.happenedAt.toLocal().isAfter(sevenDaysAgo),
  );
  final completed = eventsInWindow
      .where((event) => event.type == AppEventType.checkInCompleted)
      .length;
  final missed = eventsInWindow
      .where((event) => event.type == AppEventType.checkInMissed)
      .length;

  return GuardianCheckInMonitoringData(
    seniorId: seniorId,
    seniorProfile: seniorProfile,
    todayState: todayState,
    recentCheckInEvents: recentEvents,
    completedInLast7Days: completed,
    missedInLast7Days: missed,
  );
});

final guardianCheckInTodayMissedProvider = Provider.autoDispose<int>((ref) {
  final monitoringAsync = ref.watch(guardianCheckInMonitoringDataProvider);
  return monitoringAsync.maybeWhen(
    data: (data) => data.recentCheckInEvents
        .where((event) => event.type == AppEventType.checkInMissed)
        .where((event) => isSameLocalDay(event.happenedAt, DateTime.now()))
        .length,
    orElse: () => 0,
  );
});
