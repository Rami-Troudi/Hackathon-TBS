import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_timeline_providers.dart';
import 'package:senior_companion/shared/models/guardian_timeline_filter.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

PersistedEventRecord _record({
  required String id,
  required AppEventType type,
}) {
  final happenedAt = DateTime.parse('2026-04-18T08:00:00Z');
  return PersistedEventRecord(
    id: id,
    seniorId: 'senior-a',
    type: type,
    happenedAt: happenedAt,
    createdAt: happenedAt,
    source: 'test',
    severity: EventSeverity.info,
    payload: const <String, dynamic>{},
  );
}

void main() {
  test('guardian timeline filter provider returns events by selected type',
      () async {
    final data = GuardianTimelineData(
      seniorId: 'senior-a',
      seniorProfile: const SeniorProfile(
        id: 'senior-a',
        displayName: 'Senior A',
        age: 75,
        preferredLanguage: 'fr',
        largeTextEnabled: true,
        highContrastEnabled: false,
        linkedGuardianIds: <String>['guardian-a'],
      ),
      events: <PersistedEventRecord>[
        _record(id: 'evt-1', type: AppEventType.checkInCompleted),
        _record(id: 'evt-2', type: AppEventType.medicationMissed),
        _record(id: 'evt-3', type: AppEventType.incidentConfirmed),
        _record(id: 'evt-4', type: AppEventType.emergencyTriggered),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        guardianTimelineDataProvider.overrideWith((ref) async => data),
      ],
    );
    addTearDown(container.dispose);

    await container.read(guardianTimelineDataProvider.future);

    final initial = container.read(guardianFilteredTimelineProvider);
    expect(initial.valueOrNull, hasLength(4));

    container.read(guardianTimelineFilterProvider.notifier).state =
        GuardianTimelineFilter.medication;
    final medication = container.read(guardianFilteredTimelineProvider);
    expect(medication.valueOrNull, hasLength(1));
    expect(
      medication.valueOrNull?.single.type,
      AppEventType.medicationMissed,
    );

    container.read(guardianTimelineFilterProvider.notifier).state =
        GuardianTimelineFilter.incidents;
    final incidents = container.read(guardianFilteredTimelineProvider);
    expect(incidents.valueOrNull, hasLength(1));
    expect(
      incidents.valueOrNull?.single.type,
      AppEventType.incidentConfirmed,
    );
  });
}
