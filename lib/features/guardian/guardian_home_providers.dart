import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/daily_summary.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class GuardianHomeData {
  const GuardianHomeData({
    required this.activeSeniorId,
    required this.seniorProfile,
    required this.guardianProfile,
    required this.dashboardSummary,
    required this.pendingActiveAlerts,
    required this.recentImportantEvents,
    required this.topAlerts,
    required this.checkInState,
    required this.todayMedicationTaken,
    required this.todayMedicationMissed,
    required this.todayMedicationPending,
    required this.incidentState,
    required this.hydrationState,
    required this.nutritionState,
    required this.safeZoneStatus,
    required this.dailySummary,
    required this.settings,
  });

  final String? activeSeniorId;
  final SeniorProfile? seniorProfile;
  final GuardianProfile? guardianProfile;
  final DashboardSummary dashboardSummary;
  final int pendingActiveAlerts;
  final List<PersistedEventRecord> recentImportantEvents;
  final List<GuardianAlert> topAlerts;
  final CheckInState checkInState;
  final int todayMedicationTaken;
  final int todayMedicationMissed;
  final int todayMedicationPending;
  final IncidentFlowState incidentState;
  final HydrationState hydrationState;
  final NutritionState nutritionState;
  final SafeZoneStatus safeZoneStatus;
  final DailySummary dailySummary;
  final GuardianSettingsPreferences settings;
}

final guardianHomeDataProvider =
    FutureProvider.autoDispose<GuardianHomeData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final appSessionRepository = ref.watch(appSessionRepositoryProvider);
  final dashboardRepository = ref.watch(dashboardRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final guardianAlertRepository = ref.watch(guardianAlertRepositoryProvider);
  final checkInRepository = ref.watch(checkInRepositoryProvider);
  final medicationRepository = ref.watch(medicationRepositoryProvider);
  final incidentRepository = ref.watch(incidentRepositoryProvider);
  final hydrationRepository = ref.watch(hydrationRepositoryProvider);
  final nutritionRepository = ref.watch(nutritionRepositoryProvider);
  final safeZoneRepository = ref.watch(safeZoneRepositoryProvider);
  final summaryRepository = ref.watch(summaryRepositoryProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);

  final activeSeniorId = await activeSeniorResolver.resolveActiveSeniorId();
  final now = DateTime.now();
  if (activeSeniorId == null) {
    return GuardianHomeData(
      activeSeniorId: null,
      seniorProfile: null,
      guardianProfile: null,
      dashboardSummary: const DashboardSummary(
        globalStatus: SeniorGlobalStatus.ok,
        pendingAlerts: 0,
        todayCheckIns: 0,
        missedMedications: 0,
        openIncidents: 0,
      ),
      pendingActiveAlerts: 0,
      recentImportantEvents: const <PersistedEventRecord>[],
      topAlerts: const <GuardianAlert>[],
      checkInState: CheckInState(
        status: CheckInStatus.pending,
        windowLabel: 'Daily morning check-in',
        windowStart: DateTime(now.year, now.month, now.day, 8),
        windowEnd: DateTime(now.year, now.month, now.day, 12),
      ),
      todayMedicationTaken: 0,
      todayMedicationMissed: 0,
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
      nutritionState: const NutritionState(slots: <MealSlotState>[]),
      safeZoneStatus: const SafeZoneStatus(
        location: null,
        activeZone: null,
        lastTransitionAt: null,
      ),
      dailySummary: DailySummary(
        audience: DailySummaryAudience.guardian,
        headline: 'No linked senior selected.',
        whatWentWell: <String>[],
        needsAttention: <String>[],
        notableEvents: <String>[],
        generatedAt: now.toUtc(),
      ),
      settings: GuardianSettingsPreferences.defaults(),
    );
  }

  final session = await appSessionRepository.getSession();
  final seniorProfile =
      await profileRepository.getSeniorProfileById(activeSeniorId);
  final guardianProfile = session != null &&
          session.activeRole == AppRole.guardian
      ? await profileRepository.getGuardianProfileById(session.activeProfileId)
      : null;
  final settings = guardianProfile == null
      ? GuardianSettingsPreferences.defaults()
      : await settingsRepository.getGuardianSettings(guardianProfile.id);

  final summary = await dashboardRepository.fetchDashboardSummary(
    seniorId: activeSeniorId,
  );
  final alerts = await guardianAlertRepository.fetchAlertsForSenior(
    activeSeniorId,
    alertSensitivity: settings.alertSensitivity,
  );
  final checkInState = await checkInRepository.getTodayState(
    activeSeniorId,
    reconcileMissedWindow: true,
  );
  final reminders =
      await medicationRepository.getTodayReminders(activeSeniorId);
  final incidentState =
      await incidentRepository.getCurrentState(activeSeniorId);
  final hydrationState = await hydrationRepository.getTodayState(
    activeSeniorId,
    reconcileMissedSlots: true,
  );
  final nutritionState = await nutritionRepository.getTodayState(
    activeSeniorId,
    reconcileMissedMeals: true,
  );
  await safeZoneRepository.seedDefaultZonesIfNeeded(activeSeniorId);
  final safeZoneStatus =
      await safeZoneRepository.getCurrentStatus(activeSeniorId);
  final dailySummary =
      await summaryRepository.buildGuardianDailySummary(activeSeniorId);
  final recentEvents = await eventRepository.fetchTimelineForSenior(
    activeSeniorId,
    order: TimelineOrder.newestFirst,
    limit: 40,
  );

  final importantEvents = recentEvents
      .where(
        (event) =>
            event.severity != EventSeverity.info ||
            _isImportantType(event.type),
      )
      .take(8)
      .toList(growable: false);
  final activeAlertCount =
      alerts.where((alert) => alert.state == GuardianAlertState.active).length;

  return GuardianHomeData(
    activeSeniorId: activeSeniorId,
    seniorProfile: seniorProfile,
    guardianProfile: guardianProfile,
    dashboardSummary: summary,
    pendingActiveAlerts: activeAlertCount,
    recentImportantEvents: importantEvents,
    topAlerts: alerts.take(3).toList(growable: false),
    checkInState: checkInState,
    todayMedicationTaken: reminders
        .where((reminder) => reminder.status == MedicationReminderStatus.taken)
        .length,
    todayMedicationMissed: reminders
        .where((reminder) => reminder.status == MedicationReminderStatus.missed)
        .length,
    todayMedicationPending: reminders
        .where(
            (reminder) => reminder.status == MedicationReminderStatus.pending)
        .length,
    incidentState: incidentState,
    hydrationState: hydrationState,
    nutritionState: nutritionState,
    safeZoneStatus: safeZoneStatus,
    dailySummary: dailySummary,
    settings: settings,
  );
});

bool _isImportantType(AppEventType type) => switch (type) {
      AppEventType.checkInMissed ||
      AppEventType.medicationMissed ||
      AppEventType.hydrationMissed ||
      AppEventType.mealMissed ||
      AppEventType.safeZoneExited ||
      AppEventType.incidentSuspected ||
      AppEventType.incidentConfirmed ||
      AppEventType.incidentDismissed ||
      AppEventType.emergencyTriggered =>
        true,
      _ => false,
    };
