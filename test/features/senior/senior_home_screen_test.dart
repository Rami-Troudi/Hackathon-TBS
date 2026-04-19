import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/features/senior/senior_home_screen.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/medication_plan.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

SeniorHomeData _buildSeniorHomeData({
  bool simplifiedMode = false,
}) {
  return SeniorHomeData(
    activeSeniorId: 'senior-1',
    profile: const SeniorProfile(
      id: 'senior-1',
      displayName: 'Senior Demo',
      age: 72,
      preferredLanguage: 'en',
      largeTextEnabled: true,
      highContrastEnabled: false,
      linkedGuardianIds: <String>['guardian-1'],
    ),
    summary: const DashboardSummary(
      globalStatus: SeniorGlobalStatus.watch,
      pendingAlerts: 1,
      todayCheckIns: 0,
      missedMedications: 1,
      openIncidents: 0,
    ),
    settings: SeniorSettingsPreferences.defaults().copyWith(
      languageCode: 'en',
      simplifiedModeEnabled: simplifiedMode,
    ),
    checkInState: CheckInState(
      status: CheckInStatus.pending,
      windowLabel: 'Daily morning check-in',
      windowStart: DateTime(2026, 4, 18, 8),
      windowEnd: DateTime(2026, 4, 18, 12),
    ),
    hydrationState: HydrationState(
      slots: <HydrationSlotState>[
        HydrationSlotState(
          id: 'hydration-morning',
          label: 'Morning hydration',
          scheduledAt: DateTime(2026, 4, 18, 10),
          status: HydrationSlotStatus.pending,
        ),
      ],
      dailyGoalCompletions: 3,
    ),
    nutritionState: NutritionState(
      slots: <MealSlotState>[
        MealSlotState(
          id: 'meal-lunch',
          mealLabel: 'Lunch',
          scheduledAt: DateTime(2026, 4, 18, 13),
          status: MealSlotStatus.pending,
        ),
      ],
    ),
    safeZoneStatus: const SafeZoneStatus(
      location: null,
      activeZone: null,
      lastTransitionAt: null,
    ),
    nextReminder: MedicationReminder(
      id: 'med-1',
      plan: const MedicationPlan(
        id: 'plan-1',
        seniorId: 'senior-1',
        medicationName: 'Aspirin',
        dosageLabel: '100mg',
        scheduledTimes: <String>['08:00'],
        isActive: true,
      ),
      slotLabel: 'Morning',
      scheduledAt: DateTime(2026, 4, 18, 8),
      status: MedicationReminderStatus.pending,
    ),
    recentEvents: const [],
  );
}

void main() {
  testWidgets('senior home keeps secondary actions behind More options',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seniorHomeDataProvider.overrideWith(
            (ref) async => _buildSeniorHomeData(),
          ),
          connectivityStateProvider.overrideWith(
            (ref) => Stream.value(AppConnectivityState.online),
          ),
        ],
        child: const MaterialApp(home: SeniorHomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Hydration'), findsNothing);
    expect(find.text('Meals'), findsNothing);
    expect(find.text('Daily summary'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('More options'),
      300,
    );
    expect(find.text('More options'), findsOneWidget);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Hydration'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Daily summary'), findsOneWidget);
  });

  testWidgets('senior home shows offline banner in offline mode',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seniorHomeDataProvider.overrideWith(
            (ref) async => _buildSeniorHomeData(simplifiedMode: true),
          ),
          connectivityStateProvider.overrideWith(
            (ref) => Stream.value(AppConnectivityState.offline),
          ),
        ],
        child: const MaterialApp(home: SeniorHomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Offline mode'), findsOneWidget);
    expect(
      find.text('Showing local data only until connectivity is restored.'),
      findsOneWidget,
    );
  });
}
