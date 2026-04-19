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
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/daily_summary.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class SeniorAiContext {
  const SeniorAiContext({
    required this.seniorId,
    required this.profile,
    required this.settings,
    required this.summary,
    required this.dashboardSummary,
    required this.checkInState,
    required this.medicationReminders,
    required this.nextReminder,
    required this.hydrationState,
    required this.nutritionState,
    required this.safeZoneStatus,
    required this.activeAlerts,
    required this.recentEvents,
    required this.generatedAt,
  });

  final String? seniorId;
  final SeniorProfile? profile;
  final SeniorSettingsPreferences settings;
  final DailySummary summary;
  final DashboardSummary dashboardSummary;
  final CheckInState checkInState;
  final List<MedicationReminder> medicationReminders;
  final MedicationReminder? nextReminder;
  final HydrationState hydrationState;
  final NutritionState nutritionState;
  final SafeZoneStatus safeZoneStatus;
  final List<GuardianAlert> activeAlerts;
  final List<PersistedEventRecord> recentEvents;
  final DateTime generatedAt;
}

class GuardianAiContext {
  const GuardianAiContext({
    required this.seniorId,
    required this.seniorProfile,
    required this.guardianProfile,
    required this.settings,
    required this.summary,
    required this.dashboardSummary,
    required this.checkInState,
    required this.medicationReminders,
    required this.incidentState,
    required this.hydrationState,
    required this.nutritionState,
    required this.safeZoneStatus,
    required this.activeAlerts,
    required this.recentEvents,
    required this.weeklyEvents,
    required this.generatedAt,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final GuardianProfile? guardianProfile;
  final GuardianSettingsPreferences settings;
  final DailySummary summary;
  final DashboardSummary dashboardSummary;
  final CheckInState checkInState;
  final List<MedicationReminder> medicationReminders;
  final IncidentFlowState incidentState;
  final HydrationState hydrationState;
  final NutritionState nutritionState;
  final SafeZoneStatus safeZoneStatus;
  final List<GuardianAlert> activeAlerts;
  final List<PersistedEventRecord> recentEvents;
  final List<PersistedEventRecord> weeklyEvents;
  final DateTime generatedAt;
}

class AiContextBuilder {
  const AiContextBuilder({
    required this.activeSeniorResolver,
    required this.appSessionRepository,
    required this.profileRepository,
    required this.settingsRepository,
    required this.summaryRepository,
    required this.dashboardRepository,
    required this.checkInRepository,
    required this.medicationRepository,
    required this.hydrationRepository,
    required this.nutritionRepository,
    required this.safeZoneRepository,
    required this.incidentRepository,
    required this.guardianAlertRepository,
    required this.eventRepository,
  });

  final ActiveSeniorResolver activeSeniorResolver;
  final AppSessionRepository appSessionRepository;
  final ProfileRepository profileRepository;
  final SettingsRepository settingsRepository;
  final SummaryRepository summaryRepository;
  final DashboardRepository dashboardRepository;
  final CheckInRepository checkInRepository;
  final MedicationRepository medicationRepository;
  final HydrationRepository hydrationRepository;
  final NutritionRepository nutritionRepository;
  final SafeZoneRepository safeZoneRepository;
  final IncidentRepository incidentRepository;
  final GuardianAlertRepository guardianAlertRepository;
  final EventRepository eventRepository;

  Future<SeniorAiContext> buildSeniorContext({DateTime? now}) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
    if (seniorId == null) {
      return _emptySeniorContext(reference);
    }

    await safeZoneRepository.seedDefaultZonesIfNeeded(seniorId);
    final profile = await profileRepository.getSeniorProfileById(seniorId);
    final settings = await settingsRepository.getSeniorSettings(seniorId);
    final summary = await summaryRepository.buildSeniorDailySummary(
      seniorId,
      now: reference,
    );
    final dashboardSummary =
        await dashboardRepository.fetchDashboardSummary(seniorId: seniorId);
    final checkInState = await checkInRepository.getTodayState(
      seniorId,
      now: reference,
      reconcileMissedWindow: true,
    );
    final reminders = await medicationRepository.getTodayReminders(
      seniorId,
      now: reference,
    );
    final nextReminder = await medicationRepository.getNextPendingReminder(
      seniorId,
      now: reference,
    );
    final hydrationState = await hydrationRepository.getTodayState(
      seniorId,
      now: reference,
      reconcileMissedSlots: true,
    );
    final nutritionState = await nutritionRepository.getTodayState(
      seniorId,
      now: reference,
      reconcileMissedMeals: true,
    );
    final safeZoneStatus = await safeZoneRepository.getCurrentStatus(seniorId);
    final alerts = await guardianAlertRepository.fetchAlertsForSenior(seniorId);
    final activeAlerts =
        alerts.where((alert) => alert.isActive).toList(growable: false);
    final recentEvents = await eventRepository.fetchRecentEventsForSenior(
      seniorId,
      limit: 20,
    );

    return SeniorAiContext(
      seniorId: seniorId,
      profile: profile,
      settings: settings,
      summary: summary,
      dashboardSummary: dashboardSummary,
      checkInState: checkInState,
      medicationReminders: reminders,
      nextReminder: nextReminder,
      hydrationState: hydrationState,
      nutritionState: nutritionState,
      safeZoneStatus: safeZoneStatus,
      activeAlerts: activeAlerts,
      recentEvents: recentEvents,
      generatedAt: reference.toUtc(),
    );
  }

  Future<GuardianAiContext> buildGuardianContext({DateTime? now}) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
    if (seniorId == null) {
      return _emptyGuardianContext(reference);
    }

    await safeZoneRepository.seedDefaultZonesIfNeeded(seniorId);
    final session = await appSessionRepository.getSession();
    final seniorProfile =
        await profileRepository.getSeniorProfileById(seniorId);
    final guardianProfile =
        session != null && session.activeRole == AppRole.guardian
            ? await profileRepository
                .getGuardianProfileById(session.activeProfileId)
            : null;
    final settings = guardianProfile == null
        ? GuardianSettingsPreferences.defaults()
        : await settingsRepository.getGuardianSettings(guardianProfile.id);
    final summary = await summaryRepository.buildGuardianDailySummary(
      seniorId,
      now: reference,
    );
    final dashboardSummary =
        await dashboardRepository.fetchDashboardSummary(seniorId: seniorId);
    final checkInState = await checkInRepository.getTodayState(
      seniorId,
      now: reference,
      reconcileMissedWindow: true,
    );
    final reminders = await medicationRepository.getTodayReminders(
      seniorId,
      now: reference,
    );
    final incidentState = await incidentRepository.getCurrentState(seniorId);
    final hydrationState = await hydrationRepository.getTodayState(
      seniorId,
      now: reference,
      reconcileMissedSlots: true,
    );
    final nutritionState = await nutritionRepository.getTodayState(
      seniorId,
      now: reference,
      reconcileMissedMeals: true,
    );
    final safeZoneStatus = await safeZoneRepository.getCurrentStatus(seniorId);
    final alerts = await guardianAlertRepository.fetchAlertsForSenior(
      seniorId,
      now: reference,
      alertSensitivity: settings.alertSensitivity,
    );
    final activeAlerts =
        alerts.where((alert) => alert.isActive).toList(growable: false);
    final recentEvents = await eventRepository.fetchRecentEventsForSenior(
      seniorId,
      limit: 30,
    );
    final weeklyEvents = await eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      limit: 300,
      types: const <AppEventType>{
        AppEventType.checkInCompleted,
        AppEventType.checkInMissed,
        AppEventType.medicationTaken,
        AppEventType.medicationMissed,
        AppEventType.hydrationCompleted,
        AppEventType.hydrationMissed,
        AppEventType.mealCompleted,
        AppEventType.mealMissed,
        AppEventType.incidentSuspected,
        AppEventType.incidentConfirmed,
        AppEventType.incidentDismissed,
        AppEventType.emergencyTriggered,
        AppEventType.safeZoneEntered,
        AppEventType.safeZoneExited,
      },
    );

    return GuardianAiContext(
      seniorId: seniorId,
      seniorProfile: seniorProfile,
      guardianProfile: guardianProfile,
      settings: settings,
      summary: summary,
      dashboardSummary: dashboardSummary,
      checkInState: checkInState,
      medicationReminders: reminders,
      incidentState: incidentState,
      hydrationState: hydrationState,
      nutritionState: nutritionState,
      safeZoneStatus: safeZoneStatus,
      activeAlerts: activeAlerts,
      recentEvents: recentEvents,
      weeklyEvents: weeklyEvents,
      generatedAt: reference.toUtc(),
    );
  }

  SeniorAiContext _emptySeniorContext(DateTime reference) {
    return SeniorAiContext(
      seniorId: null,
      profile: null,
      settings: SeniorSettingsPreferences.defaults(),
      summary: DailySummary(
        audience: DailySummaryAudience.senior,
        headline: 'No active senior profile is selected.',
        whatWentWell: const <String>[],
        needsAttention: const <String>[],
        notableEvents: const <String>[],
        generatedAt: reference.toUtc(),
      ),
      dashboardSummary: const DashboardSummary(
        globalStatus: SeniorGlobalStatus.ok,
        pendingAlerts: 0,
        todayCheckIns: 0,
        missedMedications: 0,
        openIncidents: 0,
      ),
      checkInState: CheckInState(
        status: CheckInStatus.pending,
        windowLabel: 'Daily morning check-in',
        windowStart:
            DateTime(reference.year, reference.month, reference.day, 8),
        windowEnd: DateTime(reference.year, reference.month, reference.day, 12),
      ),
      medicationReminders: const <MedicationReminder>[],
      nextReminder: null,
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
      activeAlerts: const <GuardianAlert>[],
      recentEvents: const <PersistedEventRecord>[],
      generatedAt: reference.toUtc(),
    );
  }

  GuardianAiContext _emptyGuardianContext(DateTime reference) {
    return GuardianAiContext(
      seniorId: null,
      seniorProfile: null,
      guardianProfile: null,
      settings: GuardianSettingsPreferences.defaults(),
      summary: DailySummary(
        audience: DailySummaryAudience.guardian,
        headline: 'No linked senior selected.',
        whatWentWell: const <String>[],
        needsAttention: const <String>[],
        notableEvents: const <String>[],
        generatedAt: reference.toUtc(),
      ),
      dashboardSummary: const DashboardSummary(
        globalStatus: SeniorGlobalStatus.ok,
        pendingAlerts: 0,
        todayCheckIns: 0,
        missedMedications: 0,
        openIncidents: 0,
      ),
      checkInState: CheckInState(
        status: CheckInStatus.pending,
        windowLabel: 'Daily morning check-in',
        windowStart:
            DateTime(reference.year, reference.month, reference.day, 8),
        windowEnd: DateTime(reference.year, reference.month, reference.day, 12),
      ),
      medicationReminders: const <MedicationReminder>[],
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
      activeAlerts: const <GuardianAlert>[],
      recentEvents: const <PersistedEventRecord>[],
      weeklyEvents: const <PersistedEventRecord>[],
      generatedAt: reference.toUtc(),
    );
  }
}
