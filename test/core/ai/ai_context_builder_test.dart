import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
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

class _FakeSessionRepository implements AppSessionRepository {
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
        startedAt: DateTime.parse('2026-04-19T08:00:00Z'),
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
  static const senior = SeniorProfile(
    id: 'senior-a',
    displayName: 'Senior A',
    age: 76,
    preferredLanguage: 'fr',
    largeTextEnabled: true,
    highContrastEnabled: false,
    linkedGuardianIds: <String>['guardian-a'],
  );

  static const guardian = GuardianProfile(
    id: 'guardian-a',
    displayName: 'Guardian A',
    relationshipLabel: 'Daughter',
    pushAlertNotificationsEnabled: true,
    dailySummaryEnabled: true,
    linkedSeniorIds: <String>['senior-a'],
  );

  @override
  Future<void> clearAllProfiles() async {}

  @override
  Future<List<GuardianProfile>> getGuardianProfiles() async =>
      const <GuardianProfile>[guardian];

  @override
  Future<GuardianProfile?> getGuardianProfileById(String id) async =>
      id == guardian.id ? guardian : null;

  @override
  Future<List<GuardianProfile>> getLinkedGuardians(String seniorId) async =>
      const <GuardianProfile>[guardian];

  @override
  Future<List<SeniorProfile>> getLinkedSeniors(String guardianId) async =>
      const <SeniorProfile>[senior];

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async =>
      const <SeniorProfile>[senior];

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async =>
      id == senior.id ? senior : null;

  @override
  Future<void> saveGuardianProfiles(List<GuardianProfile> profiles) async {}

  @override
  Future<void> saveProfileLinks(List<ProfileLink> links) async {}

  @override
  Future<void> saveSeniorProfiles(List<SeniorProfile> profiles) async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<GuardianSettingsPreferences> getGuardianSettings(
    String guardianId,
  ) async =>
      GuardianSettingsPreferences.defaults();

  @override
  Future<SeniorSettingsPreferences> getSeniorSettings(String seniorId) async =>
      SeniorSettingsPreferences.defaults();

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

class _FakeSummaryRepository implements SummaryRepository {
  @override
  Future<DailySummary> buildGuardianDailySummary(
    String seniorId, {
    DateTime? now,
  }) async =>
      DailySummary(
        audience: DailySummaryAudience.guardian,
        headline: 'Watch state: follow-up is recommended today.',
        whatWentWell: const <String>['Check-ins completed: 1'],
        needsAttention: const <String>['Missed medication confirmations: 1'],
        notableEvents: const <String>['09:00 • Medication missed'],
        generatedAt: (now ?? DateTime.now()).toUtc(),
      );

  @override
  Future<DailySummary> buildSeniorDailySummary(
    String seniorId, {
    DateTime? now,
  }) async =>
      DailySummary(
        audience: DailySummaryAudience.senior,
        headline: 'You are on track today.',
        whatWentWell: const <String>['Check-in completed 1 time(s).'],
        needsAttention: const <String>['Hydration reminder was missed.'],
        notableEvents: const <String>['10:00 • Hydration missed'],
        generatedAt: (now ?? DateTime.now()).toUtc(),
      );
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> fetchDashboardSummary({String? seniorId}) async =>
      const DashboardSummary(
        globalStatus: SeniorGlobalStatus.watch,
        pendingAlerts: 2,
        todayCheckIns: 1,
        missedMedications: 1,
        openIncidents: 0,
      );
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
        windowLabel: 'Morning',
        windowStart: DateTime(2026, 4, 19, 8),
        windowEnd: DateTime(2026, 4, 19, 12),
        completedAt: DateTime(2026, 4, 19, 9),
      );

  @override
  Future<bool> markCheckInCompleted(String seniorId, {DateTime? now}) async =>
      true;

  @override
  Future<void> markNeedHelp(String seniorId, {DateTime? now}) async {}
}

class _FakeMedicationRepository implements MedicationRepository {
  @override
  Future<MedicationReminder?> getNextPendingReminder(
    String seniorId, {
    DateTime? now,
  }) async =>
      MedicationReminder(
        id: 'r-next',
        plan: const MedicationPlan(
          id: 'plan-a',
          seniorId: 'senior-a',
          medicationName: 'A',
          dosageLabel: '1',
          scheduledTimes: <String>['18:00'],
          isActive: true,
        ),
        slotLabel: '18:00',
        scheduledAt: DateTime(2026, 4, 19, 18),
        status: MedicationReminderStatus.pending,
      );

  @override
  Future<List<MedicationPlan>> getPlansForSenior(String seniorId) async =>
      const <MedicationPlan>[];

  @override
  Future<List<MedicationReminder>> getTodayReminders(
    String seniorId, {
    DateTime? now,
  }) async =>
      <MedicationReminder>[
        MedicationReminder(
          id: 'r1',
          plan: const MedicationPlan(
            id: 'plan-a',
            seniorId: 'senior-a',
            medicationName: 'A',
            dosageLabel: '1',
            scheduledTimes: <String>['09:00'],
            isActive: true,
          ),
          slotLabel: '09:00',
          scheduledAt: DateTime(2026, 4, 19, 9),
          status: MedicationReminderStatus.missed,
        ),
      ];

  @override
  Future<bool> markMedicationMissed(
    String seniorId, {
    required String planId,
    DateTime? now,
  }) async =>
      true;

  @override
  Future<bool> markMedicationTaken(
    String seniorId, {
    required String planId,
    DateTime? now,
  }) async =>
      true;
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
            id: 'h1',
            label: 'Morning hydration',
            scheduledAt: DateTime(2026, 4, 19, 10),
            status: HydrationSlotStatus.missed,
          ),
        ],
        dailyGoalCompletions: 3,
      );

  @override
  Future<bool> markHydrationCompleted(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) async =>
      true;

  @override
  Future<bool> markHydrationMissed(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) async =>
      true;
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
            id: 'm1',
            mealLabel: 'Lunch',
            scheduledAt: DateTime(2026, 4, 19, 13),
            status: MealSlotStatus.pending,
          ),
        ],
      );

  @override
  Future<bool> markMealCompleted(
    String seniorId, {
    required String mealId,
    DateTime? now,
  }) async =>
      true;

  @override
  Future<bool> markMealMissed(
    String seniorId, {
    required String mealId,
    DateTime? now,
  }) async =>
      true;
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
      const SafeZoneStatus(
        location: null,
        activeZone: null,
        lastTransitionAt: null,
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
  }) async =>
      const SafeZoneStatus(
        location: null,
        activeZone: null,
        lastTransitionAt: null,
      );
}

class _FakeIncidentRepository implements IncidentRepository {
  @override
  Future<void> confirmIncident(String seniorId, {DateTime? now}) async {}

  @override
  Future<void> dismissIncident(String seniorId, {DateTime? now}) async {}

  @override
  Future<IncidentFlowState> getCurrentState(String seniorId) async =>
      const IncidentFlowState(
        status: IncidentFlowStatus.clear,
        openSuspectedIncidents: 0,
        openConfirmedIncidents: 0,
      );

  @override
  Future<void> reportSuspiciousIncident(
    String seniorId, {
    DateTime? now,
    double confidenceScore = 0.75,
  }) async {}

  @override
  Future<void> requestImmediateHelp(String seniorId, {DateTime? now}) async {}

  @override
  Future<void> triggerEmergency(String seniorId, {DateTime? now}) async {}
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
          title: 'Medication missed today',
          explanation: 'Medication was marked as missed.',
          happenedAt: DateTime.parse('2026-04-19T09:00:00Z'),
          severity: GuardianAlertSeverity.warning,
          state: GuardianAlertState.active,
          relatedEventType: AppEventType.medicationMissed,
          destination: GuardianMonitoringDestination.medication,
        ),
      ];

  @override
  Future<void> resolveAlert(String alertId) async {}
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
  }) async =>
      <PersistedEventRecord>[
        PersistedEventRecord(
          id: 'evt-1',
          seniorId: seniorId,
          type: AppEventType.medicationMissed,
          happenedAt: DateTime.parse('2026-04-19T09:00:00Z'),
          createdAt: DateTime.parse('2026-04-19T09:00:00Z'),
          source: 'test',
          severity: EventSeverity.warning,
          payload: const <String, dynamic>{},
        ),
      ];

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
          seniorId: seniorId,
          type: AppEventType.medicationMissed,
          happenedAt: DateTime.parse('2026-04-19T09:00:00Z'),
          createdAt: DateTime.parse('2026-04-19T09:00:00Z'),
          source: 'test',
          severity: EventSeverity.warning,
          payload: const <String, dynamic>{},
        ),
      ];
}

void main() {
  test('context builder gathers grounded senior and guardian context',
      () async {
    final sessionRepo = _FakeSessionRepository();
    final profileRepo = _FakeProfileRepository();
    final builder = AiContextBuilder(
      activeSeniorResolver: ActiveSeniorResolver(
        appSessionRepository: sessionRepo,
        profileRepository: profileRepo,
      ),
      appSessionRepository: sessionRepo,
      profileRepository: profileRepo,
      settingsRepository: _FakeSettingsRepository(),
      summaryRepository: _FakeSummaryRepository(),
      dashboardRepository: _FakeDashboardRepository(),
      checkInRepository: _FakeCheckInRepository(),
      medicationRepository: _FakeMedicationRepository(),
      hydrationRepository: _FakeHydrationRepository(),
      nutritionRepository: _FakeNutritionRepository(),
      safeZoneRepository: _FakeSafeZoneRepository(),
      incidentRepository: _FakeIncidentRepository(),
      guardianAlertRepository: _FakeAlertRepository(),
      eventRepository: _FakeEventRepository(),
    );

    final seniorContext = await builder.buildSeniorContext(
      now: DateTime.parse('2026-04-19T11:00:00Z'),
    );
    final guardianContext = await builder.buildGuardianContext(
      now: DateTime.parse('2026-04-19T11:00:00Z'),
    );

    expect(seniorContext.seniorId, 'senior-a');
    expect(seniorContext.summary.headline, isNotEmpty);
    expect(seniorContext.activeAlerts, isNotEmpty);
    expect(guardianContext.seniorId, 'senior-a');
    expect(guardianContext.guardianProfile?.id, 'guardian-a');
    expect(guardianContext.weeklyEvents, isNotEmpty);
  });
}
