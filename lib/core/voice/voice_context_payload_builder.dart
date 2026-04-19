import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';

class VoiceContextPayloadBuilder {
  const VoiceContextPayloadBuilder({
    required this.contextBuilder,
  });

  final AiContextBuilder contextBuilder;

  Future<Map<String, dynamic>> buildSeniorPayload() async {
    final context = await contextBuilder.buildSeniorContext();
    return <String, dynamic>{
      'role': 'senior',
      'seniorId': context.seniorId,
      'profile': <String, dynamic>{
        'displayName': context.profile?.displayName,
        'preferredLanguage': context.profile?.preferredLanguage,
      },
      'status': context.dashboardSummary.globalStatus.name,
      'summary': context.summary.headline,
      'today': <String, dynamic>{
        'checkIn': _checkInLabel(context.checkInState),
        'nextMedication': _reminderLabel(context.nextReminder),
        'hydration':
            '${context.hydrationState.completedCount}/${context.hydrationState.dailyGoalCompletions}',
        'nutrition':
            '${context.nutritionState.completedCount}/${context.nutritionState.slots.length}',
        'safeZone': context.safeZoneStatus.zoneLabel,
      },
      'activeAlerts':
          context.activeAlerts.take(5).map(_alertLabel).toList(growable: false),
      'recentEvents':
          context.recentEvents.take(8).map(_eventLabel).toList(growable: false),
      'generatedAt': context.generatedAt.toIso8601String(),
      'guardrails': const <String>[
        'Do not diagnose.',
        'Do not invent events.',
        'Use only the provided local app context.',
        'Keep senior-facing responses short, calm, and respectful.',
      ],
    };
  }

  String _checkInLabel(CheckInState state) {
    return switch (state.status) {
      CheckInStatus.completed => 'completed',
      CheckInStatus.pending => 'pending',
      CheckInStatus.missed => 'missed',
    };
  }

  String _reminderLabel(MedicationReminder? reminder) {
    if (reminder == null) return 'none pending';
    return '${reminder.plan.medicationName} at ${reminder.slotLabel}';
  }

  String _alertLabel(GuardianAlert alert) {
    return '${alert.severity.name}: ${alert.title}';
  }

  String _eventLabel(PersistedEventRecord event) {
    return '${event.type.name} at ${event.happenedAt.toIso8601String()}';
  }
}
