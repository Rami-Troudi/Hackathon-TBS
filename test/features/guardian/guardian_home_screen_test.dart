import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/features/guardian/guardian_home_screen.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/daily_summary.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

GuardianHomeData _buildGuardianHomeData() {
  return GuardianHomeData(
    activeSeniorId: 'senior-1',
    seniorProfile: const SeniorProfile(
      id: 'senior-1',
      displayName: 'Senior Demo',
      age: 75,
      preferredLanguage: 'en',
      largeTextEnabled: true,
      highContrastEnabled: false,
      linkedGuardianIds: <String>['guardian-1'],
    ),
    guardianProfile: const GuardianProfile(
      id: 'guardian-1',
      displayName: 'Guardian Demo',
      relationshipLabel: 'Daughter',
      pushAlertNotificationsEnabled: true,
      dailySummaryEnabled: true,
      linkedSeniorIds: <String>['senior-1'],
    ),
    dashboardSummary: const DashboardSummary(
      globalStatus: SeniorGlobalStatus.watch,
      pendingAlerts: 1,
      todayCheckIns: 1,
      missedMedications: 1,
      openIncidents: 0,
    ),
    pendingActiveAlerts: 1,
    recentImportantEvents: const [],
    topAlerts: <GuardianAlert>[
      GuardianAlert(
        id: 'alert-1',
        seniorId: 'senior-1',
        title: 'Missed medication',
        explanation: 'One medication reminder was missed today.',
        happenedAt: DateTime.parse('2026-04-18T10:00:00Z'),
        severity: GuardianAlertSeverity.warning,
        state: GuardianAlertState.active,
        relatedEventType: AppEventType.medicationMissed,
        destination: GuardianMonitoringDestination.medication,
      ),
    ],
    checkInState: CheckInState(
      status: CheckInStatus.completed,
      windowLabel: 'Daily morning check-in',
      windowStart: DateTime(2026, 4, 18, 8),
      windowEnd: DateTime(2026, 4, 18, 12),
      completedAt: DateTime(2026, 4, 18, 8, 30),
    ),
    todayMedicationTaken: 2,
    todayMedicationMissed: 1,
    todayMedicationPending: 0,
    incidentState: const IncidentFlowState(
      status: IncidentFlowStatus.clear,
      openSuspectedIncidents: 0,
      openConfirmedIncidents: 0,
    ),
    hydrationState: const HydrationState(
      slots: <HydrationSlotState>[],
      dailyGoalCompletions: 3,
    ),
    nutritionState: const NutritionState(
      slots: <MealSlotState>[],
    ),
    safeZoneStatus: const SafeZoneStatus(
      location: null,
      activeZone: null,
      lastTransitionAt: null,
    ),
    dailySummary: DailySummary(
      audience: DailySummaryAudience.guardian,
      headline: 'Stable day overall.',
      whatWentWell: const <String>['Check-in completed'],
      needsAttention: const <String>['Missed one medication reminder'],
      notableEvents: const <String>['10:00 • medication missed'],
      generatedAt: DateTime.parse('2026-04-18T12:00:00Z'),
    ),
    settings: GuardianSettingsPreferences.defaults(),
  );
}

Widget _buildApp(GoRouter router) {
  return ProviderScope(
    overrides: [
      guardianHomeDataProvider
          .overrideWith((ref) async => _buildGuardianHomeData()),
      connectivityStateProvider.overrideWith(
        (ref) => Stream.value(AppConnectivityState.online),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

GoRouter _buildRouter() {
  Widget destination(String path) => Scaffold(
        body: Center(
          child: Text('Destination: $path'),
        ),
      );

  return GoRouter(
    initialLocation: AppRoutes.guardianHome,
    routes: [
      GoRoute(
        path: AppRoutes.guardianHome,
        builder: (_, __) => const GuardianHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianAlerts,
        builder: (_, __) => destination(AppRoutes.guardianAlerts),
      ),
      GoRoute(
        path: AppRoutes.guardianTimeline,
        builder: (_, __) => destination(AppRoutes.guardianTimeline),
      ),
      GoRoute(
        path: AppRoutes.guardianProfile,
        builder: (_, __) => destination(AppRoutes.guardianProfile),
      ),
      GoRoute(
        path: AppRoutes.guardianCheckIns,
        builder: (_, __) => destination(AppRoutes.guardianCheckIns),
      ),
      GoRoute(
        path: AppRoutes.guardianInsights,
        builder: (_, __) => destination(AppRoutes.guardianInsights),
      ),
    ],
  );
}

void main() {
  testWidgets('guardian quick actions navigate to key routes', (tester) async {
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alerts').first);
    await tester.pumpAndSettle();
    expect(find.text('Destination: /guardian/alerts'), findsOneWidget);

    router.go(AppRoutes.guardianHome);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timeline').first);
    await tester.pumpAndSettle();
    expect(find.text('Destination: /guardian/timeline'), findsOneWidget);

    router.go(AppRoutes.guardianHome);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senior').first);
    await tester.pumpAndSettle();
    expect(find.text('Destination: /guardian/profile'), findsOneWidget);
  });

  testWidgets('guardian monitoring cards navigate to module routes',
      (tester) async {
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check-ins'));
    await tester.pumpAndSettle();
    expect(find.text('Destination: /guardian/check-ins'), findsOneWidget);

    router.go(AppRoutes.guardianHome);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('AI insights'), 300);
    await tester.tap(find.text('AI insights'));
    await tester.pumpAndSettle();
    expect(find.text('Destination: /guardian/insights'), findsOneWidget);
  });
}
