import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/repositories/check_in_repository.dart';
import 'package:senior_companion/core/repositories/dashboard_repository.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/guardian_alert_repository.dart';
import 'package:senior_companion/core/repositories/hydration_repository.dart';
import 'package:senior_companion/core/repositories/incident_repository.dart';
import 'package:senior_companion/core/repositories/medication_repository.dart';
import 'package:senior_companion/core/repositories/nutrition_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/repositories/safe_zone_repository.dart';
import 'package:senior_companion/core/repositories/settings_repository.dart';
import 'package:senior_companion/core/repositories/summary_repository.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/daily_summary.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/medication_plan.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/safe_zone.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class _FakeAppSessionRepository implements AppSessionRepository {
  @override
  Future<void> clearSession() async {}

  @override
  Future<void> createSession({
    required AppRole activeRole,
    required String activeProfileId,
  }) async {}

  @override
  Future<AppSession?> getSession() async => AppSession(
        activeRole: AppRole.guardian,
        activeProfileId: 'guardian-a',
        startedAt: DateTime.parse('2026-04-18T08:00:00Z'),
      );

  @override
  Future<void> saveSession(AppSession session) async {}

  @override
  Future<void> switchSessionRole({
    required AppRole activeRole,
    required String activeProfileId,
  }) async {}
}

class _FakeProfileRepository implements ProfileRepository {
  const _FakeProfileRepository();

  @override
  Future<void> clearAllProfiles() async {}

  @override
  Future<List<GuardianProfile>> getGuardianProfiles() async =>
      const <GuardianProfile>[
        GuardianProfile(
          id: 'guardian-a',
          displayName: 'Guardian A',
          relationshipLabel: 'Daughter',
          pushAlertNotificationsEnabled: true,
          dailySummaryEnabled: true,
          linkedSeniorIds: <String>['senior-a'],
        ),
      ];

  @override
  Future<GuardianProfile?> getGuardianProfileById(String id) async {
    if (id != 'guardian-a') return null;
    return const GuardianProfile(
      id: 'guardian-a',
      displayName: 'Guardian A',
      relationshipLabel: 'Daughter',
      pushAlertNotificationsEnabled: true,
      dailySummaryEnabled: true,
      linkedSeniorIds: <String>['senior-a'],
    );
  }

  @override
  Future<List<GuardianProfile>> getLinkedGuardians(String seniorId) async =>
      const <GuardianProfile>[];

  @override
  Future<List<SeniorProfile>> getLinkedSeniors(String guardianId) async =>
      const <SeniorProfile>[
        SeniorProfile(
          id: 'senior-a',
          displayName: 'Senior A',
          age: 77,
          preferredLanguage: 'fr',
          largeTextEnabled: true,
          highContrastEnabled: false,
          linkedGuardianIds: <String>['guardian-a'],
        ),
      ];

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async =>
      const <SeniorProfile>[];

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async {
    if (id != 'senior-a') return null;
    return const SeniorProfile(
      id: 'senior-a',
      displayName: 'Senior A',
      age: 77,
      preferredLanguage: 'fr',
      largeTextEnabled: true,
      highContrastEnabled: false,
      linkedGuardianIds: <String>['guardian-a'],
    );
  }

  @override
  Future<void> saveGuardianProfiles(List<GuardianProfile> profiles) async {}

  @override
  Future<void> saveProfileLinks(List<ProfileLink> links) async {}

  @override
  Future<void> saveSeniorProfiles(List<SeniorProfile> profiles) async {}
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> fetchDashboardSummary({String? seniorId}) async =>
      const DashboardSummary(
        globalStatus: SeniorGlobalStatus.watch,
        pendingAlerts: 3,
        todayCheckIns: 1,
        missedMedications: 1,
        openIncidents: 1,
      );
}

class _FakeAlertRepository implements GuardianAlertRepository {
  @override
  Future<void> acknowledgeAlert(String alertId) async {}

  @override
  Future<List<GuardianAlert>> fetchAlertsForSenior(
    String seniorId, {
    DateTime? now,
    AlertSensitivity alertSensitivity = AlertSensitivity.normal,
  }) async =>
      <GuardianAlert>[
        GuardianAlert(
          id: 'a1',
          seniorId: seniorId,
          title: 'Critical alert',
          explanation: 'Critical',
          happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
          severity: GuardianAlertSeverity.critical,
          state: GuardianAlertState.active,
          relatedEventType: AppEventType.incidentConfirmed,
          destination: GuardianMonitoringDestination.incidents,
        ),
        GuardianAlert(
          id: 'a2',
          seniorId: seniorId,
          title: 'Acknowledged alert',
          explanation: 'Acknowledged',
          happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          severity: GuardianAlertSeverity.warning,
          state: GuardianAlertState.acknowledged,
          relatedEventType: AppEventType.checkInMissed,
          destination: GuardianMonitoringDestination.checkIns,
        ),
      ];

  @override
  Future<void> resolveAlert(String alertId) async {}
}

class _FakeCheckInRepository implements CheckInRepository {
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
        status: CheckInStatus.completed,
        windowLabel: 'Daily morning check-in',
        windowStart: DateTime(2026, 4, 18, 8, 0),
        windowEnd: DateTime(2026, 4, 18, 12, 0),
        completedAt: DateTime(2026, 4, 18, 8, 30),
      );

  @override
  Future<bool> markCheckInCompleted(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markNeedHelp(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }
}

class _FakeMedicationRepository implements MedicationRepository {
  @override
  Future<MedicationReminder?> getNextPendingReminder(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<MedicationPlan>> getPlansForSenior(String seniorId) {
    throw UnimplementedError();
  }

  @override
  Future<List<MedicationReminder>> getTodayReminders(
    String seniorId, {
    DateTime? now,
  }) async =>
      <MedicationReminder>[
        MedicationReminder(
          id: 'r1',
          plan: const MedicationPlan(
            id: 'p1',
            seniorId: 'senior-a',
            medicationName: 'A',
            dosageLabel: '1',
            scheduledTimes: <String>['08:00'],
            isActive: true,
          ),
          slotLabel: '08:00',
          scheduledAt: DateTime(2026, 4, 18, 8, 0),
          status: MedicationReminderStatus.taken,
          resolvedAt: DateTime(2026, 4, 18, 8, 5),
        ),
        MedicationReminder(
          id: 'r2',
          plan: const MedicationPlan(
            id: 'p2',
            seniorId: 'senior-a',
            medicationName: 'B',
            dosageLabel: '1',
            scheduledTimes: <String>['19:00'],
            isActive: true,
          ),
          slotLabel: '19:00',
          scheduledAt: DateTime(2026, 4, 18, 19, 0),
          status: MedicationReminderStatus.missed,
          resolvedAt: DateTime(2026, 4, 18, 19, 10),
        ),
        MedicationReminder(
          id: 'r3',
          plan: const MedicationPlan(
            id: 'p3',
            seniorId: 'senior-a',
            medicationName: 'C',
            dosageLabel: '1',
            scheduledTimes: <String>['22:00'],
            isActive: true,
          ),
          slotLabel: '22:00',
          scheduledAt: DateTime(2026, 4, 18, 22, 0),
          status: MedicationReminderStatus.pending,
        ),
      ];

  @override
  Future<bool> markMedicationMissed(
    String seniorId, {
    required String planId,
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> markMedicationTaken(
    String seniorId, {
    required String planId,
    DateTime? now,
  }) {
    throw UnimplementedError();
  }
}

class _FakeIncidentRepository implements IncidentRepository {
  @override
  Future<void> confirmIncident(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> dismissIncident(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<IncidentFlowState> getCurrentState(String seniorId) async =>
      const IncidentFlowState(
        status: IncidentFlowStatus.suspected,
        openSuspectedIncidents: 1,
        openConfirmedIncidents: 0,
      );

  @override
  Future<void> reportSuspiciousIncident(
    String seniorId, {
    DateTime? now,
    double confidenceScore = 0.75,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestImmediateHelp(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> triggerEmergency(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }
}

class _FakeEventRepository implements EventRepository {
  @override
  Future<void> addEventRecord(PersistedEventRecord record) async {}

  @override
  Future<PersistedEventRecord> addAppEvent(
    AppEvent event, {
    String source = 'runtime',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addEventRecords(Iterable<PersistedEventRecord> records) async {}

  @override
  Future<void> clearEventHistory({String? seniorId}) async {}

  @override
  Future<List<PersistedEventRecord>> fetchAll({
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersistedEventRecord>> fetchEventsByTypeForSenior(
    String seniorId,
    AppEventType type, {
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersistedEventRecord>> fetchEventsForGuardian(
    String guardianId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersistedEventRecord>> fetchRecentEventsForSenior(
    String seniorId, {
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersistedEventRecord>> fetchTimelineForSenior(
    String seniorId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) async =>
      <PersistedEventRecord>[
        PersistedEventRecord(
          id: 'evt-1',
          seniorId: 'senior-a',
          type: AppEventType.medicationMissed,
          happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
          createdAt: DateTime.parse('2026-04-18T09:00:00Z'),
          source: 'test',
          severity: EventSeverity.warning,
          payload: const <String, dynamic>{'medicationName': 'A'},
        ),
      ];
}

class _FakeHydrationRepository implements HydrationRepository {
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
      HydrationState(
        slots: <HydrationSlotState>[
          HydrationSlotState(
            id: 'hydration-morning',
            label: 'Morning hydration',
            scheduledAt: DateTime(2026, 4, 18, 9, 0),
            status: HydrationSlotStatus.completed,
            resolvedAt: DateTime(2026, 4, 18, 9, 15),
          ),
        ],
        dailyGoalCompletions: 3,
      );

  @override
  Future<bool> markHydrationCompleted(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> markHydrationMissed(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) {
    throw UnimplementedError();
  }
}

class _FakeNutritionRepository implements NutritionRepository {
  @override
  Future<List<PersistedEventRecord>> fetchRecentMealEvents(
    String seniorId, {
    int limit = 20,
  }) async =>
      const <PersistedEventRecord>[];

  @override
  Future<NutritionState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedMeals = true,
  }) async =>
      NutritionState(
        slots: <MealSlotState>[
          MealSlotState(
            id: 'meal-breakfast',
            mealLabel: 'Breakfast',
            scheduledAt: DateTime(2026, 4, 18, 8, 0),
            status: MealSlotStatus.completed,
            resolvedAt: DateTime(2026, 4, 18, 8, 20),
          ),
        ],
      );

  @override
  Future<bool> markMealCompleted(
    String seniorId, {
    required String mealId,
    DateTime? now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> markMealMissed(
    String seniorId, {
    required String mealId,
    DateTime? now,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSafeZoneRepository implements SafeZoneRepository {
  @override
  Future<void> deleteSafeZone({
    required String seniorId,
    required String zoneId,
  }) async {}

  @override
  Future<List<PersistedEventRecord>> fetchRecentZoneEvents(
    String seniorId, {
    int limit = 20,
  }) async =>
      const <PersistedEventRecord>[];

  @override
  Future<SafeZoneStatus> getCurrentStatus(String seniorId) async =>
      SafeZoneStatus(
        location: SimulatedLocation(
          latitude: 36.8065,
          longitude: 10.1815,
          updatedAt: DateTime.parse('2026-04-18T10:00:00Z'),
          label: 'Home',
        ),
        activeZone: const SafeZone(
          id: 'senior-a-zone-home',
          seniorId: 'senior-a',
          name: 'Home',
          centerLatitude: 36.8065,
          centerLongitude: 10.1815,
          radiusMeters: 250,
          isActive: true,
        ),
        lastTransitionAt: DateTime.parse('2026-04-18T09:30:00Z'),
      );

  @override
  Future<List<SafeZone>> getSafeZonesForSenior(String seniorId) async =>
      const <SafeZone>[];

  @override
  Future<void> saveSafeZone(SafeZone zone) async {}

  @override
  Future<void> seedDefaultZonesIfNeeded(String seniorId) async {}

  @override
  Future<SafeZoneStatus> updateSimulatedLocation(
    String seniorId, {
    required double latitude,
    required double longitude,
    String? label,
    DateTime? now,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSummaryRepository implements SummaryRepository {
  @override
  Future<DailySummary> buildGuardianDailySummary(
    String seniorId, {
    DateTime? now,
  }) async =>
      DailySummary(
        audience: DailySummaryAudience.guardian,
        headline: 'Stable day with no major warning signs.',
        whatWentWell: const <String>['Check-ins completed: 1'],
        needsAttention: const <String>['Missed medication confirmations: 1'],
        notableEvents: const <String>['09:00 • Medication missed'],
        generatedAt: DateTime.parse('2026-04-18T10:30:00Z'),
      );

  @override
  Future<DailySummary> buildSeniorDailySummary(
    String seniorId, {
    DateTime? now,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<GuardianSettingsPreferences> getGuardianSettings(
          String guardianId) async =>
      GuardianSettingsPreferences.defaults();

  @override
  Future<SeniorSettingsPreferences> getSeniorSettings(String seniorId) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveGuardianSettings(
    String guardianId,
    GuardianSettingsPreferences preferences,
  ) async {}

  @override
  Future<void> saveSeniorSettings(
    String seniorId,
    SeniorSettingsPreferences preferences,
  ) async {}
}

void main() {
  test('guardian home provider aggregates dashboard and module snapshots',
      () async {
    final container = ProviderContainer(
      overrides: [
        appSessionRepositoryProvider
            .overrideWithValue(_FakeAppSessionRepository()),
        profileRepositoryProvider
            .overrideWithValue(const _FakeProfileRepository()),
        dashboardRepositoryProvider
            .overrideWithValue(_FakeDashboardRepository()),
        guardianAlertRepositoryProvider
            .overrideWithValue(_FakeAlertRepository()),
        checkInRepositoryProvider.overrideWithValue(_FakeCheckInRepository()),
        medicationRepositoryProvider
            .overrideWithValue(_FakeMedicationRepository()),
        incidentRepositoryProvider.overrideWithValue(_FakeIncidentRepository()),
        eventRepositoryProvider.overrideWithValue(_FakeEventRepository()),
        hydrationRepositoryProvider
            .overrideWithValue(_FakeHydrationRepository()),
        nutritionRepositoryProvider
            .overrideWithValue(_FakeNutritionRepository()),
        safeZoneRepositoryProvider.overrideWithValue(_FakeSafeZoneRepository()),
        summaryRepositoryProvider.overrideWithValue(_FakeSummaryRepository()),
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
      ],
    );
    addTearDown(container.dispose);

    final homeData = await container.read(guardianHomeDataProvider.future);

    expect(homeData.activeSeniorId, 'senior-a');
    expect(homeData.pendingActiveAlerts, 1);
    expect(homeData.todayMedicationTaken, 1);
    expect(homeData.todayMedicationMissed, 1);
    expect(homeData.todayMedicationPending, 1);
    expect(homeData.dashboardSummary.globalStatus, SeniorGlobalStatus.watch);
    expect(homeData.checkInState.status, CheckInStatus.completed);
    expect(homeData.incidentState.status, IncidentFlowStatus.suspected);
    expect(homeData.hydrationState.completedCount, 1);
    expect(homeData.nutritionState.completedCount, 1);
    expect(homeData.safeZoneStatus.isInsideSafeZone, true);
  });
}
