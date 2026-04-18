import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/notification_level.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class AppEventMapper {
  const AppEventMapper();

  PersistedEventRecord toPersistedRecord(
    AppEvent event, {
    String source = 'runtime',
    DateTime? createdAt,
    String? id,
  }) {
    return PersistedEventRecord(
      id: id ?? PersistedEventRecord.nextId(now: createdAt),
      seniorId: event.seniorId,
      type: event.type,
      happenedAt: event.happenedAt.toUtc(),
      createdAt: (createdAt ?? DateTime.now().toUtc()).toUtc(),
      source: source,
      severity: _severityFor(event),
      payload: _payloadFor(event),
    );
  }

  EventSeverity _severityFor(AppEvent event) => switch (event) {
        EmergencyTriggeredEvent() => EventSeverity.critical,
        IncidentConfirmedEvent() => EventSeverity.critical,
        IncidentSuspectedEvent() => EventSeverity.warning,
        CheckInMissedEvent() => EventSeverity.warning,
        MedicationMissedEvent() => EventSeverity.warning,
        GuardianAlertGeneratedEvent(:final alertLevel) =>
          _severityForNotificationLevel(alertLevel),
        SeniorStatusChangedEvent(:final newStatus) => switch (newStatus) {
            SeniorGlobalStatus.actionRequired => EventSeverity.critical,
            SeniorGlobalStatus.watch => EventSeverity.warning,
            SeniorGlobalStatus.ok => EventSeverity.info,
          },
        _ => EventSeverity.info,
      };

  EventSeverity _severityForNotificationLevel(NotificationLevel level) {
    return switch (level) {
      NotificationLevel.critical => EventSeverity.critical,
      NotificationLevel.warning => EventSeverity.warning,
      NotificationLevel.info => EventSeverity.info,
    };
  }

  Map<String, dynamic> _payloadFor(AppEvent event) => switch (event) {
        CheckInCompletedEvent() => const <String, dynamic>{},
        CheckInMissedEvent(:final windowLabel) => <String, dynamic>{
            'windowLabel': windowLabel
          },
        MedicationTakenEvent(:final medicationName) => <String, dynamic>{
            'medicationName': medicationName
          },
        MedicationMissedEvent(:final medicationName) => <String, dynamic>{
            'medicationName': medicationName
          },
        IncidentSuspectedEvent(:final confidenceScore) => <String, dynamic>{
            'confidenceScore': confidenceScore
          },
        IncidentConfirmedEvent() => const <String, dynamic>{},
        IncidentDismissedEvent() => const <String, dynamic>{},
        EmergencyTriggeredEvent() => const <String, dynamic>{},
        SeniorStatusChangedEvent(:final newStatus) => <String, dynamic>{
            'newStatus': newStatus.name
          },
        GuardianAlertGeneratedEvent(:final alertLevel) => <String, dynamic>{
            'alertLevel': alertLevel.name
          },
      };
}
