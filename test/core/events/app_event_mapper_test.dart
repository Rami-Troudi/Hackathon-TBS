import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/notification_level.dart';

void main() {
  group('AppEventMapper', () {
    const mapper = AppEventMapper();

    test('maps medication missed event with payload and warning severity', () {
      final record = mapper.toPersistedRecord(
        MedicationMissedEvent(
          seniorId: 'senior-a',
          happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          medicationName: 'Aspirin',
        ),
        source: 'test',
        createdAt: DateTime.parse('2026-04-18T08:00:05Z'),
        id: 'evt-1',
      );

      expect(record.id, 'evt-1');
      expect(record.seniorId, 'senior-a');
      expect(record.type, AppEventType.medicationMissed);
      expect(record.severity, EventSeverity.warning);
      expect(record.payload['medicationName'], 'Aspirin');
      expect(record.source, 'test');
    });

    test('maps emergency event to critical severity', () {
      final record = mapper.toPersistedRecord(
        EmergencyTriggeredEvent(
          seniorId: 'senior-a',
          happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
        ),
      );

      expect(record.type, AppEventType.emergencyTriggered);
      expect(record.severity, EventSeverity.critical);
      expect(record.payload, isEmpty);
    });

    test('maps guardian alert level into persisted severity', () {
      final record = mapper.toPersistedRecord(
        GuardianAlertGeneratedEvent(
          seniorId: 'senior-a',
          happenedAt: DateTime.parse('2026-04-18T09:30:00Z'),
          alertLevel: NotificationLevel.warning,
        ),
      );

      expect(record.type, AppEventType.guardianAlertGenerated);
      expect(record.severity, EventSeverity.warning);
      expect(record.payload['alertLevel'], 'warning');
    });
  });
}
