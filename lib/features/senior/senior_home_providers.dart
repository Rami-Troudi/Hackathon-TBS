import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';

class SeniorHomeData {
  const SeniorHomeData({
    required this.activeSeniorId,
    required this.profile,
    required this.summary,
    required this.settings,
    required this.checkInState,
    required this.hydrationState,
    required this.nutritionState,
    required this.incidentState,
    required this.safeZoneStatus,
    required this.nextReminder,
    required this.recentEvents,
  });

  final String? activeSeniorId;
  final SeniorProfile? profile;
  final DashboardSummary summary;
  final SeniorSettingsPreferences settings;
  final CheckInState checkInState;
  final HydrationState hydrationState;
  final NutritionState nutritionState;
  final IncidentFlowState incidentState;
  final SafeZoneStatus safeZoneStatus;
  final MedicationReminder? nextReminder;
  final List<PersistedEventRecord> recentEvents;
}

final seniorHomeDataProvider =
    FutureProvider.autoDispose<SeniorHomeData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final dashboardRepository = ref.watch(dashboardRepositoryProvider);
  final checkInRepository = ref.watch(checkInRepositoryProvider);
  final medicationRepository = ref.watch(medicationRepositoryProvider);
  final hydrationRepository = ref.watch(hydrationRepositoryProvider);
  final nutritionRepository = ref.watch(nutritionRepositoryProvider);
  final incidentRepository = ref.watch(incidentRepositoryProvider);
  final safeZoneRepository = ref.watch(safeZoneRepositoryProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);

  final activeSeniorId = await activeSeniorResolver.resolveActiveSeniorId();
  if (activeSeniorId == null) {
    final now = DateTime.now();
    return SeniorHomeData(
      activeSeniorId: null,
      profile: null,
      summary: const DashboardSummary(
        globalStatus: SeniorGlobalStatus.ok,
        pendingAlerts: 0,
        todayCheckIns: 0,
        missedMedications: 0,
        openIncidents: 0,
      ),
      checkInState: CheckInState(
        status: CheckInStatus.pending,
        windowLabel: 'Daily morning check-in',
        windowStart: DateTime(now.year, now.month, now.day, 8),
        windowEnd: DateTime(now.year, now.month, now.day, 12),
      ),
      settings: SeniorSettingsPreferences.defaults(),
      hydrationState: const HydrationState(
        slots: <HydrationSlotState>[],
        dailyGoalCompletions: 3,
      ),
      nutritionState: const NutritionState(slots: <MealSlotState>[]),
      incidentState: const IncidentFlowState(
        status: IncidentFlowStatus.clear,
        openSuspectedIncidents: 0,
        openConfirmedIncidents: 0,
      ),
      safeZoneStatus: const SafeZoneStatus(
        location: null,
        activeZone: null,
        lastTransitionAt: null,
      ),
      nextReminder: null,
      recentEvents: const <PersistedEventRecord>[],
    );
  }

  final profile = await profileRepository.getSeniorProfileById(activeSeniorId);
  final summary = await dashboardRepository.fetchDashboardSummary(
    seniorId: activeSeniorId,
  );
  final settings = await settingsRepository.getSeniorSettings(activeSeniorId);
  final checkInState = await checkInRepository.getTodayState(
    activeSeniorId,
    reconcileMissedWindow: true,
  );
  final hydrationState = await hydrationRepository.getTodayState(
    activeSeniorId,
    reconcileMissedSlots: true,
  );
  final nutritionState = await nutritionRepository.getTodayState(
    activeSeniorId,
    reconcileMissedMeals: true,
  );
  final incidentState = await incidentRepository.getCurrentState(activeSeniorId);
  await safeZoneRepository.seedDefaultZonesIfNeeded(activeSeniorId);
  final safeZoneStatus =
      await safeZoneRepository.getCurrentStatus(activeSeniorId);
  final nextReminder =
      await medicationRepository.getNextPendingReminder(activeSeniorId);
  final recentEvents = await eventRepository.fetchRecentEventsForSenior(
    activeSeniorId,
    limit: 5,
  );

  return SeniorHomeData(
    activeSeniorId: activeSeniorId,
    profile: profile,
    summary: summary,
    settings: settings,
    checkInState: checkInState,
    hydrationState: hydrationState,
    nutritionState: nutritionState,
    incidentState: incidentState,
    safeZoneStatus: safeZoneStatus,
    nextReminder: nextReminder,
    recentEvents: recentEvents,
  );
});
