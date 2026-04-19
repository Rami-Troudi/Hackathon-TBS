import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/ai/ai_request.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/assistant_message.dart';
import 'package:senior_companion/shared/models/assistant_role.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class AiPromptBuilder {
  const AiPromptBuilder();

  String buildSeniorPrompt({
    required SeniorAiContext context,
    required AiRequest request,
  }) {
    final seniorName = context.profile?.displayName ?? 'Senior';
    final history = _historyBlock(request.history);
    final recentEvents = _eventLines(context.recentEvents, limit: 8).join('\n');
    final reminderFacts = _seniorReminderFacts(context).join('\n');
    return '''
You are the Senior Companion in-app assistant for "$seniorName".
Rules:
- Use short, calm, simple language.
- No diagnosis. No medical claims.
- No invented events or reminders.
- Ground every answer in provided app data.
- Suggest only in-app actions.

Context snapshot:
- Global status: ${context.dashboardSummary.globalStatus.label}
- Status details: ${context.dashboardSummary.globalStatus.description}
- Daily summary headline: ${context.summary.headline}
- Needs attention: ${context.summary.needsAttention.join('; ')}
- Positive points: ${context.summary.whatWentWell.join('; ')}
- Routine facts:
$reminderFacts
- Safe-zone: ${context.safeZoneStatus.zoneLabel}
- Active alerts count: ${context.activeAlerts.length}
- Recent events:
$recentEvents

Conversation history (latest at end):
$history

User question:
${request.userMessage}

Respond in 3-6 concise sentences. Keep tone reassuring and practical.
''';
  }

  String buildGuardianPrompt({
    required GuardianAiContext context,
    required AiRequest request,
  }) {
    final seniorName = context.seniorProfile?.displayName ?? 'linked senior';
    final guardianName = context.guardianProfile?.displayName ?? 'guardian';
    final history = _historyBlock(request.history);
    final recentEvents =
        _eventLines(context.recentEvents, limit: 10).join('\n');
    final weeklySignals = _weeklySignals(context);
    return '''
You are the Guardian Insights in-app assistant for $guardianName monitoring $seniorName.
Rules:
- Be concise, factual, and actionable.
- No diagnosis. No invented events.
- Explain why status/alerts exist using given data only.
- Keep recommendations practical and product-aware.

Context snapshot:
- Global status: ${context.dashboardSummary.globalStatus.label}
- Status details: ${context.dashboardSummary.globalStatus.description}
- Daily summary headline: ${context.summary.headline}
- Needs attention: ${context.summary.needsAttention.join('; ')}
- Active alerts: ${context.activeAlerts.length}
- Check-ins today: ${context.dashboardSummary.todayCheckIns}
- Missed medications today: ${context.dashboardSummary.missedMedications}
- Open incidents: ${context.dashboardSummary.openIncidents}
- Hydration today: ${context.hydrationState.completedCount}/${context.hydrationState.dailyGoalCompletions}, missed ${context.hydrationState.missedCount}
- Meals today: ${context.nutritionState.completedCount}/${context.nutritionState.slots.length}, missed ${context.nutritionState.missedCount}
- Safe-zone: ${context.safeZoneStatus.zoneLabel}
- Weekly signals:
$weeklySignals
- Recent events:
$recentEvents

Conversation history (latest at end):
$history

User question:
${request.userMessage}

Respond in 4-8 concise sentences with explicit rationale and next checks.
''';
  }

  List<String> _seniorReminderFacts(SeniorAiContext context) {
    final facts = <String>[
      '- Check-in status: ${context.checkInState.status.name}',
      '- Medication reminders: total ${context.medicationReminders.length}',
      '- Pending medication reminders: ${context.medicationReminders.where((r) => r.status.name == 'pending').length}',
      '- Hydration completed/missed: ${context.hydrationState.completedCount}/${context.hydrationState.missedCount}',
      '- Meals completed/missed: ${context.nutritionState.completedCount}/${context.nutritionState.missedCount}',
    ];
    final next = context.nextReminder;
    if (next != null) {
      facts.add(
          '- Next medication: ${next.plan.medicationName} at ${next.slotLabel}');
    }
    return facts;
  }

  String _weeklySignals(GuardianAiContext context) {
    final sevenDaysAgo =
        context.generatedAt.toLocal().subtract(const Duration(days: 7));
    final weekly = context.weeklyEvents
        .where((event) => event.happenedAt.toLocal().isAfter(sevenDaysAgo))
        .toList(growable: false);
    final medicationTaken = weekly
        .where((event) => event.type.timelineLabel == 'Medication taken')
        .length;
    final medicationMissed = weekly
        .where((event) => event.type.timelineLabel == 'Medication missed')
        .length;
    final hydrationCompleted = weekly
        .where((event) => event.type.timelineLabel == 'Hydration completed')
        .length;
    final hydrationMissed = weekly
        .where((event) => event.type.timelineLabel == 'Hydration missed')
        .length;
    final mealCompleted = weekly
        .where((event) => event.type.timelineLabel == 'Meal completed')
        .length;
    final mealMissed = weekly
        .where((event) => event.type.timelineLabel == 'Meal missed')
        .length;
    return '- Medication taken/missed: $medicationTaken/$medicationMissed\n'
        '- Hydration completed/missed: $hydrationCompleted/$hydrationMissed\n'
        '- Meals completed/missed: $mealCompleted/$mealMissed';
  }

  String _historyBlock(List<AssistantMessage> history) {
    if (history.isEmpty) return '- (no previous messages)';
    final recent =
        history.length > 8 ? history.sublist(history.length - 8) : history;
    return recent
        .map(
          (message) =>
              '- ${message.role == AssistantRole.user ? 'User' : 'Assistant'}: ${message.text}',
        )
        .join('\n');
  }

  List<String> _eventLines(
    List<PersistedEventRecord> events, {
    required int limit,
  }) {
    return events.take(limit).map((event) {
      final local = event.happenedAt.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '- $hh:$mm ${event.type.timelineLabel}';
    }).toList(growable: false);
  }
}
