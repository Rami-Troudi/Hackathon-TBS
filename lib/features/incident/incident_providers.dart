import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';

class IncidentData {
  const IncidentData({
    required this.seniorId,
    required this.flowState,
    required this.recentIncidentEvents,
  });

  final String? seniorId;
  final IncidentFlowState flowState;
  final List<PersistedEventRecord> recentIncidentEvents;
}

final incidentDataProvider =
    FutureProvider.autoDispose<IncidentData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final incidentRepository = ref.watch(incidentRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const IncidentData(
      seniorId: null,
      flowState: IncidentFlowState(
        status: IncidentFlowStatus.clear,
        openSuspectedIncidents: 0,
        openConfirmedIncidents: 0,
      ),
      recentIncidentEvents: <PersistedEventRecord>[],
    );
  }

  final flowState = await incidentRepository.getCurrentState(seniorId);
  final recent = await eventRepository.fetchTimelineForSenior(
    seniorId,
    order: TimelineOrder.newestFirst,
    types: const <AppEventType>{
      AppEventType.incidentSuspected,
      AppEventType.incidentConfirmed,
      AppEventType.incidentDismissed,
      AppEventType.emergencyTriggered,
    },
    limit: 8,
  );

  return IncidentData(
    seniorId: seniorId,
    flowState: flowState,
    recentIncidentEvents: recent,
  );
});
