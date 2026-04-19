import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/ai/ai_response.dart';
import 'package:senior_companion/core/ai/alert_explanation_service.dart';
import 'package:senior_companion/core/ai/status_explanation_service.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/assistant_suggestion.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class AiFallbackService {
  const AiFallbackService({
    required this.statusExplanationService,
    required this.alertExplanationService,
  });

  final StatusExplanationService statusExplanationService;
  final AlertExplanationService alertExplanationService;

  List<AssistantSuggestion> seniorSuggestions() => const <AssistantSuggestion>[
        AssistantSuggestion(
          label: 'What should I do now?',
          prompt: 'What should I do now?',
        ),
        AssistantSuggestion(
          label: 'What reminders are left?',
          prompt: 'What reminders are left today?',
        ),
        AssistantSuggestion(
          label: 'Read my day summary',
          prompt: 'Read my day summary.',
          routeHint: '/senior/summary',
        ),
        AssistantSuggestion(
          label: 'Explain medication',
          prompt: 'Did I take my medication today?',
          routeHint: '/senior/medication',
        ),
        AssistantSuggestion(
          label: 'I feel confused',
          prompt: 'I feel confused. Please simplify what I should do now.',
        ),
        AssistantSuggestion(
          label: 'Call for help',
          prompt: 'I need help now.',
          routeHint: '/senior/incident',
        ),
      ];

  List<AssistantSuggestion> guardianSuggestions() =>
      const <AssistantSuggestion>[
        AssistantSuggestion(
          label: 'What changed today?',
          prompt: 'What changed today?',
        ),
        AssistantSuggestion(
          label: 'What needs attention?',
          prompt: 'What needs attention right now?',
        ),
        AssistantSuggestion(
          label: 'Explain active alerts',
          prompt: 'Explain the active alerts.',
          routeHint: '/guardian/alerts',
        ),
        AssistantSuggestion(
          label: 'Medication this week',
          prompt: 'Summarize medication adherence this week.',
          routeHint: '/guardian/medication',
        ),
        AssistantSuggestion(
          label: 'Hydration & meals',
          prompt: 'Summarize hydration and meals.',
        ),
        AssistantSuggestion(
          label: 'Daily recap',
          prompt: 'Give me a daily recap.',
          routeHint: '/guardian/summary',
        ),
      ];

  AiResponse buildSeniorSummaryResponse(SeniorAiContext context) {
    final name = context.profile?.displayName ?? 'there';
    return AiResponse(
      answerText:
          'Hello $name. ${context.summary.headline} I can help you with reminders and simple next steps.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
        'Summary headline: ${context.summary.headline}',
      ],
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse buildGuardianSummaryResponse(GuardianAiContext context) {
    final seniorName =
        context.seniorProfile?.displayName ?? 'your linked senior';
    return AiResponse(
      answerText:
          'Insights ready for $seniorName. ${context.summary.headline} Ask me for alert explanations, trend snapshots, or next checks.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
        'Active alerts: ${context.activeAlerts.length}',
      ],
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse buildSeniorResponse({
    required SeniorAiContext context,
    required String userMessage,
  }) {
    final question = _normalize(userMessage);
    if (question.contains('what should i do now') ||
        question.contains('que dois') ||
        question.contains('quoi faire')) {
      return _seniorNextAction(context);
    }
    if (question.contains('reminder') ||
        question.contains('rappel') ||
        question.contains('left') ||
        question.contains('reste')) {
      return _seniorRemainingReminders(context);
    }
    if (question.contains('medication') ||
        question.contains('medicine') ||
        question.contains('médicament')) {
      return _seniorMedicationState(context);
    }
    if (question.contains('am i okay') ||
        question.contains('am i ok') ||
        question.contains('je vais bien') ||
        question.contains('status')) {
      return _seniorStatus(context);
    }
    if (question.contains('summary') ||
        question.contains('happened today') ||
        question.contains('résumé') ||
        question.contains('today')) {
      return _seniorDailySummary(context);
    }
    if (question.contains('help') ||
        question.contains('confused') ||
        question.contains('perdu') ||
        question.contains('aide')) {
      return _seniorHelpGuidance(context);
    }

    return AiResponse(
      answerText:
          'I can help with your next action, remaining reminders, your status, or today\'s summary. Try one of the suggestion buttons below.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
      ],
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse buildGuardianResponse({
    required GuardianAiContext context,
    required String userMessage,
  }) {
    final question = _normalize(userMessage);
    if (question.contains('changed today') ||
        question.contains('what changed') ||
        question.contains('changé')) {
      return _guardianChangesToday(context);
    }
    if (question.contains('needs attention') ||
        question.contains('attention') ||
        question.contains('check first')) {
      return _guardianNeedsAttention(context);
    }
    if (question.contains('active alerts') ||
        question.contains('explain alert') ||
        question.contains('alertes')) {
      return _guardianAlertExplanation(context);
    }
    if (question.contains('medication') && question.contains('week')) {
      return _guardianMedicationWeek(context);
    }
    if (question.contains('hydration') ||
        question.contains('meal') ||
        question.contains('nutrition')) {
      return _guardianHydrationNutrition(context);
    }
    if (question.contains('improving') ||
        question.contains('worsening') ||
        question.contains('trend')) {
      return _guardianTrend(context);
    }
    if (question.contains('daily recap') ||
        question.contains('recap') ||
        question.contains('summary')) {
      return _guardianDailyRecap(context);
    }

    return AiResponse(
      answerText:
          'I can explain alerts, summarize today, compare recent trends, or focus on medication/hydration adherence. Choose a suggestion below.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
        'Active alerts: ${context.activeAlerts.length}',
      ],
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse _seniorNextAction(SeniorAiContext context) {
    if (context.dashboardSummary.globalStatus ==
            SeniorGlobalStatus.actionRequired ||
        context.activeAlerts
            .any((alert) => alert.severity.name == 'critical')) {
      return AiResponse(
        answerText:
            'The top priority now is safety. Please tap "I need help" so your family is alerted immediately.',
        source: AiResponseSource.fallback,
        referencedFacts: <String>[
          'Status: ${context.dashboardSummary.globalStatus.label}',
          'Active alerts: ${context.activeAlerts.length}',
        ],
        suggestions: seniorSuggestions(),
      );
    }
    if (context.checkInState.status != CheckInStatus.completed) {
      return AiResponse(
        answerText:
            'Your next step is to complete today\'s check-in by tapping "I\'m okay".',
        source: AiResponseSource.fallback,
        referencedFacts: <String>[
          'Check-in status: ${context.checkInState.status.name}',
        ],
        suggestions: seniorSuggestions(),
      );
    }
    final pendingMedication = context.medicationReminders
        .where(
            (reminder) => reminder.status == MedicationReminderStatus.pending)
        .toList(growable: false);
    if (pendingMedication.isNotEmpty) {
      final next = pendingMedication.first;
      return AiResponse(
        answerText:
            'You still have a medication reminder: ${next.plan.medicationName} at ${next.slotLabel}.',
        source: AiResponseSource.fallback,
        referencedFacts: <String>[
          'Pending medication reminders: ${pendingMedication.length}',
        ],
        suggestions: seniorSuggestions(),
      );
    }
    if (context.hydrationState.pendingCount > 0) {
      return AiResponse(
        answerText:
            'You still have hydration reminders pending. Please open hydration and mark your next glass.',
        source: AiResponseSource.fallback,
        referencedFacts: <String>[
          'Hydration pending: ${context.hydrationState.pendingCount}',
        ],
        suggestions: seniorSuggestions(),
      );
    }
    if (context.nutritionState.pendingCount > 0) {
      return AiResponse(
        answerText:
            'You still have meal reminders pending. Please confirm your next meal.',
        source: AiResponseSource.fallback,
        referencedFacts: <String>[
          'Meal reminders pending: ${context.nutritionState.pendingCount}',
        ],
        suggestions: seniorSuggestions(),
      );
    }
    return AiResponse(
      answerText:
          'You are on track for now. If needed, you can review your summary or check reminders again later.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Summary: ${context.summary.headline}',
      ],
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse _seniorRemainingReminders(SeniorAiContext context) {
    final pendingMedication = context.medicationReminders
        .where(
            (reminder) => reminder.status == MedicationReminderStatus.pending)
        .length;
    final lines = <String>[
      if (context.checkInState.status != CheckInStatus.completed)
        '- Check-in is still pending.',
      '- Pending medication reminders: $pendingMedication',
      '- Pending hydration slots: ${context.hydrationState.pendingCount}',
      '- Pending meal slots: ${context.nutritionState.pendingCount}',
    ];
    return AiResponse(
      answerText: 'Here is what is left today:\n${lines.join('\n')}',
      source: AiResponseSource.fallback,
      referencedFacts: lines
          .map((line) => line.replaceFirst('- ', ''))
          .toList(growable: false),
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse _seniorMedicationState(SeniorAiContext context) {
    final taken = context.medicationReminders
        .where((reminder) => reminder.status == MedicationReminderStatus.taken)
        .length;
    final missed = context.medicationReminders
        .where((reminder) => reminder.status == MedicationReminderStatus.missed)
        .length;
    final pending = context.medicationReminders
        .where(
            (reminder) => reminder.status == MedicationReminderStatus.pending)
        .length;
    return AiResponse(
      answerText:
          'Medication today: taken $taken, missed $missed, pending $pending.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Taken: $taken',
        'Missed: $missed',
        'Pending: $pending',
      ],
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse _seniorStatus(SeniorAiContext context) {
    final explanation = statusExplanationService.explainForSenior(
      status: context.dashboardSummary.globalStatus,
      summary: context.dashboardSummary,
      hydrationMissedToday: context.hydrationState.missedCount,
      mealsMissedToday: context.nutritionState.missedCount,
      isOutsideSafeZone: !context.safeZoneStatus.isInsideSafeZone,
    );
    return AiResponse(
      answerText: explanation,
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
        ...statusExplanationService.buildStatusReasons(
          summary: context.dashboardSummary,
          hydrationMissedToday: context.hydrationState.missedCount,
          mealsMissedToday: context.nutritionState.missedCount,
          isOutsideSafeZone: !context.safeZoneStatus.isInsideSafeZone,
        ),
      ],
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse _seniorDailySummary(SeniorAiContext context) {
    final lines = <String>[
      context.summary.headline,
      if (context.summary.whatWentWell.isNotEmpty)
        'Going well: ${context.summary.whatWentWell.first}',
      if (context.summary.needsAttention.isNotEmpty)
        'Needs attention: ${context.summary.needsAttention.first}',
    ];
    return AiResponse(
      answerText: lines.join(' '),
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Headline: ${context.summary.headline}',
        ...context.summary.notableEvents.take(3),
      ],
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse _seniorHelpGuidance(SeniorAiContext context) {
    return AiResponse(
      answerText:
          'You are not alone. If you need immediate support, tap "I need help". If not urgent, start with check-in and reminders one by one.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
      ],
      suggestions: seniorSuggestions(),
    );
  }

  AiResponse _guardianChangesToday(GuardianAiContext context) {
    final latest = context.recentEvents.take(5).map((event) {
      final local = event.happenedAt.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$hh:$mm ${event.type.timelineLabel}';
    }).join(', ');
    return AiResponse(
      answerText:
          'Today\'s key changes: $latest. Current status is ${context.dashboardSummary.globalStatus.label}.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
        'Recent events considered: ${context.recentEvents.take(5).length}',
      ],
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse _guardianNeedsAttention(GuardianAiContext context) {
    final explanation = statusExplanationService.explainForGuardian(
      status: context.dashboardSummary.globalStatus,
      summary: context.dashboardSummary,
      hydrationMissedToday: context.hydrationState.missedCount,
      mealsMissedToday: context.nutritionState.missedCount,
      isOutsideSafeZone: !context.safeZoneStatus.isInsideSafeZone,
    );
    return AiResponse(
      answerText: explanation,
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Status: ${context.dashboardSummary.globalStatus.label}',
        'Active alerts: ${context.activeAlerts.length}',
      ],
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse _guardianAlertExplanation(GuardianAiContext context) {
    if (context.activeAlerts.isEmpty) {
      return AiResponse(
        answerText: 'There are no active alerts right now.',
        source: AiResponseSource.fallback,
        referencedFacts: const <String>['Active alerts: 0'],
        suggestions: guardianSuggestions(),
      );
    }
    final top = context.activeAlerts.take(3).toList(growable: false);
    final lines = top.map(alertExplanationService.explainAlert).join(' ');
    return AiResponse(
      answerText: lines,
      source: AiResponseSource.fallback,
      referencedFacts:
          alertExplanationService.summarizeActiveAlerts(context.activeAlerts),
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse _guardianMedicationWeek(GuardianAiContext context) {
    final sevenDaysAgo =
        context.generatedAt.toLocal().subtract(const Duration(days: 7));
    final weekly = context.weeklyEvents
        .where((event) => event.happenedAt.toLocal().isAfter(sevenDaysAgo))
        .toList(growable: false);
    final taken = weekly
        .where((event) => event.type == AppEventType.medicationTaken)
        .length;
    final missed = weekly
        .where((event) => event.type == AppEventType.medicationMissed)
        .length;
    final adherence = taken + missed == 0
        ? 'No medication events recorded this week.'
        : 'Adherence snapshot: $taken taken, $missed missed.';
    return AiResponse(
      answerText: adherence,
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Medication taken (7d): $taken',
        'Medication missed (7d): $missed',
      ],
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse _guardianHydrationNutrition(GuardianAiContext context) {
    return AiResponse(
      answerText:
          'Hydration today: ${context.hydrationState.completedCount}/${context.hydrationState.dailyGoalCompletions}, missed ${context.hydrationState.missedCount}. Meals today: ${context.nutritionState.completedCount}/${context.nutritionState.slots.length}, missed ${context.nutritionState.missedCount}.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Hydration missed: ${context.hydrationState.missedCount}',
        'Meals missed: ${context.nutritionState.missedCount}',
      ],
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse _guardianTrend(GuardianAiContext context) {
    final now = context.generatedAt.toLocal();
    final currentWindowStart = now.subtract(const Duration(days: 1));
    final previousWindowStart = now.subtract(const Duration(days: 2));

    int windowScore(DateTime start, DateTime end) {
      final window = context.weeklyEvents.where((event) {
        final local = event.happenedAt.toLocal();
        return local.isAfter(start) && local.isBefore(end);
      });
      var score = 0;
      for (final event in window) {
        switch (event.type) {
          case AppEventType.medicationMissed:
          case AppEventType.checkInMissed:
          case AppEventType.hydrationMissed:
          case AppEventType.mealMissed:
          case AppEventType.safeZoneExited:
          case AppEventType.incidentSuspected:
            score += 1;
          case AppEventType.incidentConfirmed:
          case AppEventType.emergencyTriggered:
            score += 2;
          case AppEventType.checkInCompleted:
          case AppEventType.medicationTaken:
          case AppEventType.hydrationCompleted:
          case AppEventType.mealCompleted:
          case AppEventType.safeZoneEntered:
          case AppEventType.incidentDismissed:
          case AppEventType.seniorStatusChanged:
          case AppEventType.guardianAlertGenerated:
            break;
        }
      }
      return score;
    }

    final recentScore = windowScore(currentWindowStart, now);
    final previousScore = windowScore(previousWindowStart, currentWindowStart);
    final trend = recentScore < previousScore
        ? 'improving'
        : recentScore > previousScore
            ? 'worsening'
            : 'stable';

    return AiResponse(
      answerText:
          'Based on recent local events, the situation appears $trend. Risk signal score (last 24h vs previous 24h): $recentScore vs $previousScore.',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Recent window score: $recentScore',
        'Previous window score: $previousScore',
      ],
      suggestions: guardianSuggestions(),
    );
  }

  AiResponse _guardianDailyRecap(GuardianAiContext context) {
    final positives = context.summary.whatWentWell.take(2).join(' ');
    final concerns = context.summary.needsAttention.take(2).join(' ');
    return AiResponse(
      answerText:
          '${context.summary.headline} Going well: $positives Needs attention: $concerns',
      source: AiResponseSource.fallback,
      referencedFacts: <String>[
        'Headline: ${context.summary.headline}',
        ...context.summary.notableEvents.take(3),
      ],
      suggestions: guardianSuggestions(),
    );
  }

  String _normalize(String value) => value.toLowerCase().trim();
}
