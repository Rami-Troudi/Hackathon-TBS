import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class GuardianIncidentMonitoringData {
  const GuardianIncidentMonitoringData({
    required this.seniorId,
    required this.seniorProfile,
    required this.currentState,
    required this.recentIncidentEvents,
    required this.suspectedCountLast7Days,
    required this.confirmedCountLast7Days,
    required this.dismissedCountLast7Days,
    required this.emergencyCountLast7Days,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final IncidentFlowState currentState;
  final List<PersistedEventRecord> recentIncidentEvents;
  final int suspectedCountLast7Days;
  final int confirmedCountLast7Days;
  final int dismissedCountLast7Days;
  final int emergencyCountLast7Days;
}

final guardianIncidentMonitoringDataProvider =
    FutureProvider.autoDispose<GuardianIncidentMonitoringData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final incidentRepository = ref.watch(incidentRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);

  final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const GuardianIncidentMonitoringData(
      seniorId: null,
      seniorProfile: null,
      currentState: IncidentFlowState(
        status: IncidentFlowStatus.clear,
        openSuspectedIncidents: 0,
        openConfirmedIncidents: 0,
      ),
      recentIncidentEvents: <PersistedEventRecord>[],
      suspectedCountLast7Days: 0,
      confirmedCountLast7Days: 0,
      dismissedCountLast7Days: 0,
      emergencyCountLast7Days: 0,
    );
  }

  final profile = await profileRepository.getSeniorProfileById(seniorId);
  final flowState = await incidentRepository.getCurrentState(seniorId);
  final recentEvents = await eventRepository.fetchTimelineForSenior(
    seniorId,
    order: TimelineOrder.newestFirst,
    types: const <AppEventType>{
      AppEventType.incidentSuspected,
      AppEventType.incidentConfirmed,
      AppEventType.incidentDismissed,
      AppEventType.emergencyTriggered,
    },
    limit: 60,
  );

  final sevenDaysAgo =
      DateTime.now().toLocal().subtract(const Duration(days: 7));
  final trendEvents = recentEvents.where(
    (event) => event.happenedAt.toLocal().isAfter(sevenDaysAgo),
  );

  final suspected = trendEvents
      .where((event) => event.type == AppEventType.incidentSuspected)
      .length;
  final confirmed = trendEvents
      .where((event) => event.type == AppEventType.incidentConfirmed)
      .length;
  final dismissed = trendEvents
      .where((event) => event.type == AppEventType.incidentDismissed)
      .length;
  final emergency = trendEvents
      .where((event) => event.type == AppEventType.emergencyTriggered)
      .length;

  return GuardianIncidentMonitoringData(
    seniorId: seniorId,
    seniorProfile: profile,
    currentState: flowState,
    recentIncidentEvents: recentEvents,
    suspectedCountLast7Days: suspected,
    confirmedCountLast7Days: confirmed,
    dismissedCountLast7Days: dismissed,
    emergencyCountLast7Days: emergency,
  );
});
