import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class GuardianAssistantMessage {
  const GuardianAssistantMessage({
    required this.id,
    required this.text,
    required this.fromGuardian,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool fromGuardian;
  final DateTime createdAt;
}

class GuardianInsightsState {
  const GuardianInsightsState({
    required this.messages,
    required this.isBusy,
    this.errorMessage,
  });

  final List<GuardianAssistantMessage> messages;
  final bool isBusy;
  final String? errorMessage;

  GuardianInsightsState copyWith({
    List<GuardianAssistantMessage>? messages,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GuardianInsightsState(
      messages: messages ?? this.messages,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory GuardianInsightsState.initial() {
    final now = DateTime.now();
    return GuardianInsightsState(
      messages: <GuardianAssistantMessage>[
        GuardianAssistantMessage(
          id: 'assistant-${now.microsecondsSinceEpoch}',
          text:
              'I can explain alerts, status, medication, hydration, nutrition, incidents, and location using current local data.',
          fromGuardian: false,
          createdAt: now,
        ),
      ],
      isBusy: false,
    );
  }
}

class GuardianInsightsController extends StateNotifier<GuardianInsightsState> {
  GuardianInsightsController({required this.ref})
      : super(GuardianInsightsState.initial());

  final Ref ref;

  Future<void> ask(String question) async {
    final normalized = question.trim();
    if (normalized.isEmpty || state.isBusy) return;

    final now = DateTime.now();
    final userMessage = GuardianAssistantMessage(
      id: 'guardian-${now.microsecondsSinceEpoch}',
      text: normalized,
      fromGuardian: true,
      createdAt: now,
    );

    state = state.copyWith(
      isBusy: true,
      clearError: true,
      messages: [...state.messages, userMessage],
    );

    try {
      final context =
          await ref.read(aiContextBuilderProvider).buildGuardianContext();
      final answer = _buildAnswer(question: normalized, context: context);
      final assistantMessage = GuardianAssistantMessage(
        id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
        text: answer,
        fromGuardian: false,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        isBusy: false,
        messages: [...state.messages, assistantMessage],
      );
    } catch (error) {
      final fallback = GuardianAssistantMessage(
        id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
        text:
            'I could not process that question right now. Local guidance: open Alerts, Daily Summary, and Timeline for deterministic details.',
        fromGuardian: false,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        isBusy: false,
        messages: [...state.messages, fallback],
        errorMessage: '$error',
      );
    }
  }

  String _buildAnswer({
    required String question,
    required GuardianAiContext context,
  }) {
    final lower = question.toLowerCase();

    if (lower.contains('changed') || lower.contains('today')) {
      final recent = context.recentEvents.take(3).toList(growable: false);
      if (recent.isEmpty) {
        return 'No major event changes were recorded today. ${context.summary.headline}';
      }
      final changes = recent.map((event) => _eventLine(event)).join(' ');
      return 'Recent changes: $changes';
    }

    if (lower.contains('attention') || lower.contains('urgent')) {
      final active = context.activeAlerts;
      final critical = active
          .where((alert) => alert.severity == GuardianAlertSeverity.critical)
          .length;
      if (active.isEmpty) {
        return 'There are no active alerts right now. ${context.dashboardSummary.globalStatus.description}';
      }
      return 'Needs attention now: ${active.length} active alert(s), including $critical critical. Start with: ${active.first.title}.';
    }

    if (lower.contains('medication')) {
      final reminders = context.medicationReminders;
      final pending = reminders.where((item) => item.isPending).length;
      final missed = reminders
          .where((item) => item.status == MedicationReminderStatus.missed)
          .length;
      final taken = reminders
          .where((item) => item.status == MedicationReminderStatus.taken)
          .length;
      return 'Medication today: taken $taken, pending $pending, missed $missed.';
    }

    if (lower.contains('hydration')) {
      return 'Hydration today: completed ${context.hydrationState.completedCount}, pending ${context.hydrationState.pendingCount}, missed ${context.hydrationState.missedCount}.';
    }

    if (lower.contains('meal') || lower.contains('nutrition')) {
      return 'Meals today: completed ${context.nutritionState.completedCount}, pending ${context.nutritionState.pendingCount}, missed ${context.nutritionState.missedCount}.';
    }

    if (lower.contains('incident')) {
      return 'Incident status: ${context.incidentState.status.name}. Open suspected: ${context.incidentState.openSuspectedIncidents}, confirmed: ${context.incidentState.openConfirmedIncidents}.';
    }

    if (lower.contains('location') || lower.contains('safe zone')) {
      final location = context.safeZoneStatus.location?.label;
      final zone = context.safeZoneStatus.zoneLabel;
      return context.safeZoneStatus.isInsideSafeZone
          ? 'Location is currently inside safe zone: $zone${location == null ? '' : ' ($location)'}.'
          : 'Location is currently outside configured safe zones${location == null ? '' : ' ($location)'}.';
    }

    if (lower.contains('summary') || lower.contains('recap')) {
      final needsAttention = context.summary.needsAttention;
      final topAttention = needsAttention.isEmpty
          ? 'No urgent attention points.'
          : 'Top attention: ${needsAttention.first}.';
      return '${context.summary.headline} $topAttention';
    }

    final defaultAttention = context.summary.needsAttention.isEmpty
        ? 'No urgent issues were flagged.'
        : context.summary.needsAttention.first;
    return 'Current status: ${context.dashboardSummary.globalStatus.label}. ${context.summary.headline} Next focus: $defaultAttention';
  }

  String _eventLine(PersistedEventRecord event) {
    final at = event.happenedAt.toLocal();
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${event.type.timelineLabel} at $hh:$mm.';
  }
}

final guardianInsightsControllerProvider =
    StateNotifierProvider<GuardianInsightsController, GuardianInsightsState>(
  (ref) => GuardianInsightsController(ref: ref),
);
