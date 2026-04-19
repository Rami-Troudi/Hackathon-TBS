import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/ai/ai_fallback_service.dart';
import 'package:senior_companion/core/ai/ai_prompt_builder.dart';
import 'package:senior_companion/core/ai/ai_request.dart';
import 'package:senior_companion/core/ai/alert_explanation_service.dart';
import 'package:senior_companion/core/ai/status_explanation_service.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/assistant_message.dart';
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
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

void main() {
  test('prompt builder includes grounded context and question', () {
    const builder = AiPromptBuilder();
    final context = SeniorAiContext(
      seniorId: 'senior-a',
      profile: const SeniorProfile(
        id: 'senior-a',
        displayName: 'Senior A',
        age: 77,
        preferredLanguage: 'fr',
        largeTextEnabled: true,
        highContrastEnabled: false,
        linkedGuardianIds: <String>['guardian-a'],
      ),
      settings: SeniorSettingsPreferences.defaults(),
      summary: DailySummary(
        audience: DailySummaryAudience.senior,
        headline: 'You are on track today.',
        whatWentWell: const <String>['Check-in completed 1 time(s).'],
        needsAttention: const <String>['Hydration reminder was missed.'],
        notableEvents: const <String>['10:00 • Hydration missed'],
        generatedAt: DateTime.parse('2026-04-19T10:00:00Z'),
      ),
      dashboardSummary: const DashboardSummary(
        globalStatus: SeniorGlobalStatus.watch,
        pendingAlerts: 1,
        todayCheckIns: 1,
        missedMedications: 0,
        openIncidents: 0,
      ),
      checkInState: CheckInState(
        status: CheckInStatus.completed,
        windowLabel: 'Morning',
        windowStart: DateTime(2026, 4, 19, 8),
        windowEnd: DateTime(2026, 4, 19, 12),
        completedAt: DateTime(2026, 4, 19, 9),
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
      recentEvents: <PersistedEventRecord>[
        PersistedEventRecord(
          id: 'evt-1',
          seniorId: 'senior-a',
          type: AppEventType.hydrationMissed,
          happenedAt: DateTime.parse('2026-04-19T10:00:00Z'),
          createdAt: DateTime.parse('2026-04-19T10:00:00Z'),
          source: 'test',
          severity: EventSeverity.warning,
          payload: const <String, dynamic>{'slotLabel': 'Morning hydration'},
        ),
      ],
      generatedAt: DateTime.parse('2026-04-19T10:05:00Z'),
    );

    final prompt = builder.buildSeniorPrompt(
      context: context,
      request: AiRequest(
        audience: AssistantAudience.senior,
        userMessage: 'What should I do now?',
        history: <AssistantMessage>[],
        requestedAt: DateTime.utc(2026, 4, 19, 10, 5),
      ),
    );

    expect(prompt, contains('Global status: Watch'));
    expect(prompt, contains('What should I do now?'));
    expect(prompt, contains('Hydration missed'));
  });

  test('fallback guardian response is grounded for medication weekly question',
      () {
    const fallback = AiFallbackService(
      statusExplanationService: StatusExplanationService(),
      alertExplanationService: AlertExplanationService(),
    );

    final context = GuardianAiContext(
      seniorId: 'senior-a',
      seniorProfile: const SeniorProfile(
        id: 'senior-a',
        displayName: 'Senior A',
        age: 77,
        preferredLanguage: 'fr',
        largeTextEnabled: true,
        highContrastEnabled: false,
        linkedGuardianIds: <String>['guardian-a'],
      ),
      guardianProfile: const GuardianProfile(
        id: 'guardian-a',
        displayName: 'Guardian A',
        relationshipLabel: 'Daughter',
        pushAlertNotificationsEnabled: true,
        dailySummaryEnabled: true,
        linkedSeniorIds: <String>['senior-a'],
      ),
      settings: GuardianSettingsPreferences.defaults(),
      summary: DailySummary(
        audience: DailySummaryAudience.guardian,
        headline: 'Watch state: follow-up is recommended today.',
        whatWentWell: const <String>['Check-ins completed: 1'],
        needsAttention: const <String>['Missed medication confirmations: 1'],
        notableEvents: const <String>['09:00 • Medication missed'],
        generatedAt: DateTime.parse('2026-04-19T11:00:00Z'),
      ),
      dashboardSummary: const DashboardSummary(
        globalStatus: SeniorGlobalStatus.watch,
        pendingAlerts: 2,
        todayCheckIns: 1,
        missedMedications: 1,
        openIncidents: 0,
      ),
      checkInState: CheckInState(
        status: CheckInStatus.completed,
        windowLabel: 'Morning',
        windowStart: DateTime(2026, 4, 19, 8),
        windowEnd: DateTime(2026, 4, 19, 12),
        completedAt: DateTime(2026, 4, 19, 9),
      ),
      medicationReminders: <MedicationReminder>[
        MedicationReminder(
          id: 'r1',
          plan: const MedicationPlan(
            id: 'p1',
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
      ],
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
      activeAlerts: <GuardianAlert>[
        GuardianAlert(
          id: 'a1',
          seniorId: 'senior-a',
          title: 'Medication missed today',
          explanation: 'At least one medication was marked as missed today.',
          happenedAt: DateTime.parse('2026-04-19T09:00:00Z'),
          severity: GuardianAlertSeverity.warning,
          state: GuardianAlertState.active,
          relatedEventType: AppEventType.medicationMissed,
          destination: GuardianMonitoringDestination.medication,
        ),
      ],
      recentEvents: const <PersistedEventRecord>[],
      weeklyEvents: <PersistedEventRecord>[
        PersistedEventRecord(
          id: 'evt-med-missed',
          seniorId: 'senior-a',
          type: AppEventType.medicationMissed,
          happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
          createdAt: DateTime.parse('2026-04-18T09:00:00Z'),
          source: 'test',
          severity: EventSeverity.warning,
          payload: const <String, dynamic>{},
        ),
      ],
      generatedAt: DateTime.parse('2026-04-19T11:00:00Z'),
    );

    final response = fallback.buildGuardianResponse(
      context: context,
      userMessage: 'Summarize medication adherence this week.',
    );

    expect(response.answerText, contains('Adherence snapshot'));
    expect(response.referencedFacts.any((line) => line.contains('7d')), isTrue);
  });
}
