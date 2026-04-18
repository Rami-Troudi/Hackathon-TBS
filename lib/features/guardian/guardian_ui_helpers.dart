import 'package:flutter/material.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';

String formatLocalTime(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String formatLocalDay(DateTime timestamp) {
  final local = timestamp.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mm-$dd';
}

String formatEventDetail(PersistedEventRecord event) => switch (event.type) {
      AppEventType.checkInMissed =>
        event.payload['windowLabel'] as String? ?? 'Check-in window was missed',
      AppEventType.medicationTaken ||
      AppEventType.medicationMissed =>
        event.payload['medicationName'] as String? ?? 'Medication update',
      AppEventType.hydrationCompleted ||
      AppEventType.hydrationMissed =>
        event.payload['slotLabel'] as String? ?? 'Hydration update',
      AppEventType.mealCompleted ||
      AppEventType.mealMissed =>
        event.payload['mealLabel'] as String? ?? 'Meal update',
      AppEventType.safeZoneEntered ||
      AppEventType.safeZoneExited =>
        event.payload['zoneName'] as String? ?? 'Safe-zone update',
      AppEventType.incidentSuspected => _incidentConfidenceLabel(event),
      AppEventType.seniorStatusChanged =>
        event.payload['newStatus'] as String? ?? 'Status changed',
      AppEventType.guardianAlertGenerated =>
        event.payload['alertLevel'] as String? ?? 'Guardian alert generated',
      _ => event.type.timelineLabel,
    };

IconData iconForEventType(AppEventType type) => switch (type) {
      AppEventType.checkInCompleted => Icons.check_circle_outline,
      AppEventType.checkInMissed => Icons.schedule_outlined,
      AppEventType.medicationTaken => Icons.medication_outlined,
      AppEventType.medicationMissed => Icons.medication_liquid_outlined,
      AppEventType.hydrationCompleted => Icons.local_drink_outlined,
      AppEventType.hydrationMissed => Icons.no_drinks_outlined,
      AppEventType.mealCompleted => Icons.restaurant_outlined,
      AppEventType.mealMissed => Icons.free_breakfast_outlined,
      AppEventType.incidentSuspected => Icons.report_gmailerrorred_outlined,
      AppEventType.incidentConfirmed => Icons.gpp_maybe_outlined,
      AppEventType.incidentDismissed => Icons.verified_outlined,
      AppEventType.emergencyTriggered => Icons.warning_amber_outlined,
      AppEventType.safeZoneEntered => Icons.home_outlined,
      AppEventType.safeZoneExited => Icons.directions_walk_outlined,
      AppEventType.seniorStatusChanged => Icons.monitor_heart_outlined,
      AppEventType.guardianAlertGenerated =>
        Icons.notifications_active_outlined,
    };

bool isSameLocalDay(DateTime timestamp, DateTime reference) {
  final local = timestamp.toLocal();
  return local.year == reference.year &&
      local.month == reference.month &&
      local.day == reference.day;
}

String _incidentConfidenceLabel(PersistedEventRecord event) {
  final confidence = event.payload['confidenceScore'];
  if (confidence is! num) return 'Suspicious pattern detected';
  final percent = (confidence * 100).round();
  return 'Confidence: $percent%';
}
