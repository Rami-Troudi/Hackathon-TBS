import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/incident_repository.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';

class LocalIncidentRepository implements IncidentRepository {
  const LocalIncidentRepository({
    required this.eventRepository,
    required this.eventRecorder,
    required this.statusEngine,
  });

  final EventRepository eventRepository;
  final AppEventRecorder eventRecorder;
  final SeniorStatusEngine statusEngine;

  @override
  Future<IncidentFlowState> getCurrentState(String seniorId) async {
    final timeline = await eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.oldestFirst,
    );
    final evaluation = statusEngine.evaluate(timeline);
    final incidentEvents = timeline.where(
      (event) => switch (event.type) {
        AppEventType.incidentSuspected ||
        AppEventType.incidentConfirmed ||
        AppEventType.incidentDismissed ||
        AppEventType.emergencyTriggered =>
          true,
        _ => false,
      },
    );
    final latestIncidentEvent =
        incidentEvents.isEmpty ? null : incidentEvents.last;

    final status = switch (latestIncidentEvent?.type) {
      AppEventType.emergencyTriggered => IncidentFlowStatus.emergency,
      AppEventType.incidentConfirmed => IncidentFlowStatus.confirmed,
      AppEventType.incidentSuspected => IncidentFlowStatus.suspected,
      AppEventType.incidentDismissed => IncidentFlowStatus.clear,
      _ => evaluation.openConfirmedIncidents > 0
          ? IncidentFlowStatus.confirmed
          : evaluation.openSuspectedIncidents > 0
              ? IncidentFlowStatus.suspected
              : IncidentFlowStatus.clear,
    };

    return IncidentFlowState(
      status: status,
      openSuspectedIncidents: evaluation.openSuspectedIncidents,
      openConfirmedIncidents: evaluation.openConfirmedIncidents,
      lastEventAt: latestIncidentEvent?.happenedAt.toLocal(),
    );
  }

  @override
  Future<void> reportSuspiciousIncident(
    String seniorId, {
    DateTime? now,
    double confidenceScore = 0.75,
  }) async {
    final happenedAt = (now ?? DateTime.now()).toUtc();
    await eventRecorder.publishAndPersist(
      IncidentSuspectedEvent(
        seniorId: seniorId,
        happenedAt: happenedAt,
        confidenceScore: confidenceScore,
      ),
      source: 'senior.incident',
    );
  }

  @override
  Future<void> confirmIncident(
    String seniorId, {
    DateTime? now,
  }) async {
    final happenedAt = (now ?? DateTime.now()).toUtc();
    await eventRecorder.publishAndPersist(
      IncidentConfirmedEvent(
        seniorId: seniorId,
        happenedAt: happenedAt,
      ),
      source: 'senior.incident.request_help',
    );
  }

  @override
  Future<void> dismissIncident(
    String seniorId, {
    DateTime? now,
  }) async {
    final happenedAt = (now ?? DateTime.now()).toUtc();
    await eventRecorder.publishAndPersist(
      IncidentDismissedEvent(
        seniorId: seniorId,
        happenedAt: happenedAt,
      ),
      source: 'senior.incident',
    );
  }

  @override
  Future<void> triggerEmergency(
    String seniorId, {
    DateTime? now,
  }) async {
    final happenedAt = (now ?? DateTime.now()).toUtc();
    await eventRecorder.publishAndPersist(
      EmergencyTriggeredEvent(
        seniorId: seniorId,
        happenedAt: happenedAt,
      ),
      source: 'senior.incident',
    );
  }

  @override
  Future<void> requestImmediateHelp(
    String seniorId, {
    DateTime? now,
  }) async {
    final happenedAt = (now ?? DateTime.now()).toUtc();
    await eventRecorder.publishAndPersist(
      IncidentConfirmedEvent(
        seniorId: seniorId,
        happenedAt: happenedAt,
      ),
      source: 'senior.incident',
    );
    await eventRecorder.publishAndPersist(
      EmergencyTriggeredEvent(
        seniorId: seniorId,
        happenedAt: happenedAt,
      ),
      source: 'senior.incident',
    );
  }
}
