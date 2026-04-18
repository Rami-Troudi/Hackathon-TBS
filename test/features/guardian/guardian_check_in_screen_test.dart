import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_check_in_providers.dart';
import 'package:senior_companion/features/guardian/guardian_check_in_screen.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

PersistedEventRecord _record({
  required String id,
  required AppEventType type,
  required DateTime happenedAt,
}) {
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
  testWidgets('guardian check-in screen renders monitoring summary and history',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guardianCheckInMonitoringDataProvider.overrideWith(
            (ref) async => GuardianCheckInMonitoringData(
              seniorId: 'senior-a',
              seniorProfile: const SeniorProfile(
                id: 'senior-a',
                displayName: 'Senior A',
                age: 74,
                preferredLanguage: 'fr',
                largeTextEnabled: true,
                highContrastEnabled: false,
                linkedGuardianIds: <String>['guardian-a'],
              ),
              todayState: CheckInState(
                status: CheckInStatus.missed,
                windowLabel: 'Daily morning check-in',
                windowStart: DateTime(2026, 4, 18, 8, 0),
                windowEnd: DateTime(2026, 4, 18, 12, 0),
                missedAt: DateTime(2026, 4, 18, 12, 0),
              ),
              recentCheckInEvents: <PersistedEventRecord>[
                _record(
                  id: 'evt-1',
                  type: AppEventType.checkInMissed,
                  happenedAt: DateTime(2026, 4, 18, 12, 0),
                ),
              ],
              completedInLast7Days: 5,
              missedInLast7Days: 2,
            ),
          ),
        ],
        child: const MaterialApp(home: GuardianCheckInScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Check-in Monitoring'), findsOneWidget);
    expect(find.text('Senior A'), findsOneWidget);
    expect(find.textContaining('Last 7 days: 5 completed • 2 missed'),
        findsOneWidget);
    expect(find.textContaining('Check-in missed'), findsOneWidget);
  });
}
