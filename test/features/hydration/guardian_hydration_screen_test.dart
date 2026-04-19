import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/hydration/guardian_hydration_screen.dart';
import 'package:senior_companion/features/hydration/hydration_providers.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

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
  testWidgets('guardian hydration screen renders daily monitoring data',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guardianHydrationMonitoringDataProvider.overrideWith(
            (ref) async => GuardianHydrationMonitoringData(
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
              todayState: HydrationState(
                slots: <HydrationSlotState>[
                  HydrationSlotState(
                    id: 'hydration-morning',
                    label: 'Morning hydration',
                    scheduledAt: DateTime(2026, 4, 18, 9, 0),
                    status: HydrationSlotStatus.completed,
                    resolvedAt: DateTime(2026, 4, 18, 9, 10),
                  ),
                ],
                dailyGoalCompletions: 3,
              ),
              completedLast7Days: 8,
              missedLast7Days: 2,
              recentEvents: <PersistedEventRecord>[
                _record(
                  id: 'evt-1',
                  type: AppEventType.hydrationCompleted,
                  happenedAt: DateTime(2026, 4, 18, 9, 10),
                  payload: const <String, dynamic>{
                    'slotLabel': 'Morning hydration',
                  },
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: GuardianHydrationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hydration monitoring'), findsOneWidget);
    expect(find.text('Senior A'), findsOneWidget);
    expect(find.textContaining('Last 7 days: 8 completed • 2 missed'),
        findsOneWidget);
    expect(find.textContaining('Hydration completed'), findsOneWidget);
  });
}
