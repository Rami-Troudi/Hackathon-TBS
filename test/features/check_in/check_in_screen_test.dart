import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/check_in_repository.dart';
import 'package:senior_companion/features/check_in/check_in_providers.dart';
import 'package:senior_companion/features/check_in/check_in_screen.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';

class _FakeCheckInRepository implements CheckInRepository {
  int markOkayCalls = 0;
  int markNeedHelpCalls = 0;

  @override
  Future<List<PersistedEventRecord>> fetchRecentCheckIns(
    String seniorId, {
    int limit = 10,
  }) async =>
      const <PersistedEventRecord>[];

  @override
  Future<CheckInState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedWindow = true,
  }) async =>
      CheckInState(
        status: CheckInStatus.pending,
        windowLabel: 'Daily morning check-in',
        windowStart: DateTime(2026, 4, 18, 8, 0),
        windowEnd: DateTime(2026, 4, 18, 12, 0),
      );

  @override
  Future<bool> markCheckInCompleted(
    String seniorId, {
    DateTime? now,
  }) async {
    markOkayCalls += 1;
    return true;
  }

  @override
  Future<void> markNeedHelp(
    String seniorId, {
    DateTime? now,
  }) async {
    markNeedHelpCalls += 1;
  }
}

void main() {
  testWidgets('check-in screen sends okay and help actions to repository',
      (tester) async {
    final repository = _FakeCheckInRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkInRepositoryProvider.overrideWithValue(repository),
          checkInDataProvider.overrideWith(
            (ref) async => CheckInData(
              seniorId: 'senior-a',
              checkInState: CheckInState(
                status: CheckInStatus.pending,
                windowLabel: 'Daily morning check-in',
                windowStart: DateTime(2026, 4, 18, 8, 0),
                windowEnd: DateTime(2026, 4, 18, 12, 0),
              ),
              recentCheckIns: const <PersistedEventRecord>[],
            ),
          ),
        ],
        child: const MaterialApp(
          home: CheckInScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('I\'m okay'));
    await tester.pump();
    await tester.tap(find.text('I need help'));
    await tester.pump();

    expect(repository.markOkayCalls, 1);
    expect(repository.markNeedHelpCalls, 1);
  });
}
