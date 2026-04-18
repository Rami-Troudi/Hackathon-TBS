import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/hydration_repository.dart';
import 'package:senior_companion/features/hydration/hydration_providers.dart';
import 'package:senior_companion/features/hydration/hydration_screen.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';

class _FakeHydrationRepository implements HydrationRepository {
  int markCompletedCalls = 0;
  int markMissedCalls = 0;

  @override
  Future<List<PersistedEventRecord>> fetchRecentHydrationEvents(
    String seniorId, {
    int limit = 20,
  }) async =>
      const <PersistedEventRecord>[];

  @override
  Future<HydrationState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedSlots = true,
  }) async =>
      const HydrationState(
        slots: <HydrationSlotState>[],
        dailyGoalCompletions: 3,
      );

  @override
  Future<bool> markHydrationCompleted(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) async {
    markCompletedCalls += 1;
    return true;
  }

  @override
  Future<bool> markHydrationMissed(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) async {
    markMissedCalls += 1;
    return true;
  }
}

void main() {
  testWidgets('senior hydration screen sends done action to repository',
      (tester) async {
    final repository = _FakeHydrationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hydrationRepositoryProvider.overrideWithValue(repository),
          seniorHydrationDataProvider.overrideWith(
            (ref) async => SeniorHydrationData(
              seniorId: 'senior-a',
              state: HydrationState(
                slots: <HydrationSlotState>[
                  HydrationSlotState(
                    id: 'hydration-morning',
                    label: 'Morning hydration',
                    scheduledAt: DateTime(2026, 4, 18, 9, 0),
                    status: HydrationSlotStatus.pending,
                  ),
                ],
                dailyGoalCompletions: 3,
              ),
              recentEvents: const <PersistedEventRecord>[],
            ),
          ),
        ],
        child: const MaterialApp(home: HydrationScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(repository.markCompletedCalls, 1);
  });
}
