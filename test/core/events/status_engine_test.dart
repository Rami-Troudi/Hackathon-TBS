import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

PersistedEventRecord _record({
  required String id,
  required AppEventType type,
  required DateTime happenedAt,
  Map<String, dynamic> payload = const <String, dynamic>{},
}) {
  return PersistedEventRecord(
    id: id,
    seniorId: 'senior-a',
    type: type,
    happenedAt: happenedAt,
    createdAt: happenedAt,
    source: 'test',
    severity: EventSeverity.info,
    payload: payload,
  );
}

void main() {
  group('SeniorStatusEngine', () {
    const engine = SeniorStatusEngine();
    final now = DateTime.parse('2026-04-18T12:00:00Z');

    test('returns ok when no warning signals are present', () {
      final result = engine.evaluate(const <PersistedEventRecord>[], now: now);

      expect(result.status, SeniorGlobalStatus.ok);
      expect(result.pendingAlerts, 0);
      expect(result.openIncidents, 0);
      expect(result.reasons,
          contains('No active incidents or missed routine signals'));
    });

    test('returns watch when one routine warning is present', () {
      final result = engine.evaluate(
        <PersistedEventRecord>[
          _record(
            id: 'evt-1',
            type: AppEventType.medicationMissed,
            happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          ),
        ],
        now: now,
      );

      expect(result.status, SeniorGlobalStatus.watch);
      expect(result.missedMedications, 1);
      expect(result.pendingAlerts, 1);
      expect(result.reasons, contains('Missed daily routine signals'));
    });

    test('returns actionRequired when emergency event exists', () {
      final result = engine.evaluate(
        <PersistedEventRecord>[
          _record(
            id: 'evt-1',
            type: AppEventType.emergencyTriggered,
            happenedAt: DateTime.parse('2026-04-18T10:00:00Z'),
          ),
        ],
        now: now,
      );

      expect(result.status, SeniorGlobalStatus.actionRequired);
      expect(result.pendingAlerts, 1);
      expect(result.reasons, contains('Emergency event detected'));
    });

    test('dismissed incident de-escalates to ok when no other signals remain',
        () {
      final result = engine.evaluate(
        <PersistedEventRecord>[
          _record(
            id: 'evt-1',
            type: AppEventType.incidentSuspected,
            happenedAt: DateTime.parse('2026-04-18T07:00:00Z'),
          ),
          _record(
            id: 'evt-2',
            type: AppEventType.incidentConfirmed,
            happenedAt: DateTime.parse('2026-04-18T07:05:00Z'),
          ),
          _record(
            id: 'evt-3',
            type: AppEventType.incidentDismissed,
            happenedAt: DateTime.parse('2026-04-18T07:15:00Z'),
          ),
        ],
        now: now,
      );

      expect(result.openIncidents, 0);
      expect(result.status, SeniorGlobalStatus.ok);
    });

    test('escalates repeated missed routine signals to actionRequired', () {
      final result = engine.evaluate(
        <PersistedEventRecord>[
          _record(
            id: 'evt-1',
            type: AppEventType.medicationMissed,
            happenedAt: DateTime.parse('2026-04-18T06:00:00Z'),
          ),
          _record(
            id: 'evt-2',
            type: AppEventType.medicationMissed,
            happenedAt: DateTime.parse('2026-04-18T07:00:00Z'),
          ),
          _record(
            id: 'evt-3',
            type: AppEventType.checkInMissed,
            happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          ),
        ],
        now: now,
      );

      expect(result.status, SeniorGlobalStatus.actionRequired);
      expect(result.pendingAlerts, 3);
      expect(result.reasons, contains('Multiple missed daily signals'));
    });
  });
}
