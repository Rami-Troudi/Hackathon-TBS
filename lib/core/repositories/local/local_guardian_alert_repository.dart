import 'dart:convert';

import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/guardian_alert_repository.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class LocalGuardianAlertRepository implements GuardianAlertRepository {
  const LocalGuardianAlertRepository({
    required this.eventRepository,
    required this.statusEngine,
    required this.storage,
  });

  final EventRepository eventRepository;
  final SeniorStatusEngine statusEngine;
  final StorageService storage;

  @override
  Future<List<GuardianAlert>> fetchAlertsForSenior(
    String seniorId, {
    DateTime? now,
    AlertSensitivity alertSensitivity = AlertSensitivity.normal,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final timeline = await eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.oldestFirst,
    );
    if (timeline.isEmpty) {
      return const <GuardianAlert>[];
    }

    final evaluation = statusEngine.evaluate(timeline, now: reference);
    final persistedStates = await _readStateMap();
    final alerts = <GuardianAlert>[];

    final incidentProjection = _projectIncidentState(timeline);
    for (final event in incidentProjection.openConfirmedEvents) {
      alerts.add(
        GuardianAlert(
          id: 'incident-confirmed-${event.id}',
          seniorId: seniorId,
          title: 'Confirmed incident still open',
          explanation:
              'An incident was confirmed and has not been dismissed yet.',
          happenedAt: event.happenedAt,
          severity: GuardianAlertSeverity.critical,
          state: GuardianAlertState.active,
          relatedEventType: event.type,
          relatedEventId: event.id,
          destination: GuardianMonitoringDestination.incidents,
        ),
      );
    }

    for (final event in incidentProjection.openSuspectedEvents) {
      alerts.add(
        GuardianAlert(
          id: 'incident-suspected-${event.id}',
          seniorId: seniorId,
          title: 'Suspicious incident under review',
          explanation:
              'A suspicious incident signal is still unresolved. Please review.',
          happenedAt: event.happenedAt,
          severity: GuardianAlertSeverity.warning,
          state: GuardianAlertState.active,
          relatedEventType: event.type,
          relatedEventId: event.id,
          destination: GuardianMonitoringDestination.incidents,
        ),
      );
    }

    for (final event in incidentProjection.activeEmergencyEvents) {
      alerts.add(
        GuardianAlert(
          id: 'emergency-${event.id}',
          seniorId: seniorId,
          title: 'Emergency alert',
          explanation:
              'Emergency escalation was triggered. Immediate follow-up is recommended.',
          happenedAt: event.happenedAt,
          severity: GuardianAlertSeverity.critical,
          state: GuardianAlertState.active,
          relatedEventType: event.type,
          relatedEventId: event.id,
          destination: GuardianMonitoringDestination.incidents,
        ),
      );
    }

    final todayMissedMedication = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.medicationMissed,
    );
    final todayMissedCheckIn = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.checkInMissed,
    );
    final todayMissedHydration = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.hydrationMissed,
    );
    final todayMissedMeal = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.mealMissed,
    );
    final todayMissedHydrationCount = _todayEventCount(
      timeline,
      reference: reference,
      type: AppEventType.hydrationMissed,
    );
    final todayMissedMealCount = _todayEventCount(
      timeline,
      reference: reference,
      type: AppEventType.mealMissed,
    );
    final todayTakenMedication = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.medicationTaken,
    );
    final todayTakenMedicationCount = _todayEventCount(
      timeline,
      reference: reference,
      type: AppEventType.medicationTaken,
    );
    final todayCompletedHydration = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.hydrationCompleted,
    );
    final todayCompletedHydrationCount = _todayEventCount(
      timeline,
      reference: reference,
      type: AppEventType.hydrationCompleted,
    );
    final todayCompletedMeal = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.mealCompleted,
    );
    final todayCompletedMealCount = _todayEventCount(
      timeline,
      reference: reference,
      type: AppEventType.mealCompleted,
    );

    final warningSignalsToday = evaluation.missedMedications +
        evaluation.missedCheckIns +
        todayMissedHydrationCount +
        todayMissedMealCount;
    final routineCriticalThreshold =
        _routineCriticalThreshold(alertSensitivity);
    final missedRoutineSeverity =
        warningSignalsToday >= routineCriticalThreshold
            ? GuardianAlertSeverity.critical
            : GuardianAlertSeverity.warning;

    if (todayMissedMedication != null) {
      alerts.add(
        GuardianAlert(
          id: 'missed-medication-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Medication missed today',
          explanation:
              'At least one medication was marked as missed today. Review adherence.',
          happenedAt: todayMissedMedication.happenedAt,
          severity: missedRoutineSeverity,
          state: GuardianAlertState.active,
          relatedEventType: todayMissedMedication.type,
          relatedEventId: todayMissedMedication.id,
          destination: GuardianMonitoringDestination.medication,
        ),
      );
    }

    if (todayMissedCheckIn != null) {
      alerts.add(
        GuardianAlert(
          id: 'missed-check-in-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Check-in missed today',
          explanation:
              'The daily check-in window was missed. Confirm the senior is okay.',
          happenedAt: todayMissedCheckIn.happenedAt,
          severity: missedRoutineSeverity,
          state: GuardianAlertState.active,
          relatedEventType: todayMissedCheckIn.type,
          relatedEventId: todayMissedCheckIn.id,
          destination: GuardianMonitoringDestination.checkIns,
        ),
      );
    }

    final todayCompletedCheckIn = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.checkInCompleted,
    );
    if (todayCompletedCheckIn != null) {
      alerts.add(
        GuardianAlert(
          id: 'completed-check-in-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Senior checked in',
          explanation:
              'The senior tapped "I\'m okay" and confirmed today\'s check-in.',
          happenedAt: todayCompletedCheckIn.happenedAt,
          severity: GuardianAlertSeverity.info,
          state: GuardianAlertState.resolved,
          relatedEventType: todayCompletedCheckIn.type,
          relatedEventId: todayCompletedCheckIn.id,
          destination: GuardianMonitoringDestination.checkIns,
        ),
      );
    }

    if (todayTakenMedication != null) {
      alerts.add(
        GuardianAlert(
          id: 'completed-medication-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Medication routine completed',
          explanation:
              'Medication doses confirmed today: $todayTakenMedicationCount.',
          happenedAt: todayTakenMedication.happenedAt,
          severity: GuardianAlertSeverity.info,
          state: GuardianAlertState.resolved,
          relatedEventType: todayTakenMedication.type,
          relatedEventId: todayTakenMedication.id,
          destination: GuardianMonitoringDestination.medication,
        ),
      );
    }

    if (todayCompletedHydration != null) {
      alerts.add(
        GuardianAlert(
          id: 'completed-hydration-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Hydration routine completed',
          explanation:
              'Hydration reminders completed today: $todayCompletedHydrationCount.',
          happenedAt: todayCompletedHydration.happenedAt,
          severity: GuardianAlertSeverity.info,
          state: GuardianAlertState.resolved,
          relatedEventType: todayCompletedHydration.type,
          relatedEventId: todayCompletedHydration.id,
          destination: GuardianMonitoringDestination.hydration,
        ),
      );
    }

    if (todayCompletedMeal != null) {
      alerts.add(
        GuardianAlert(
          id: 'completed-meal-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Nutrition routine completed',
          explanation: 'Meals confirmed today: $todayCompletedMealCount.',
          happenedAt: todayCompletedMeal.happenedAt,
          severity: GuardianAlertSeverity.info,
          state: GuardianAlertState.resolved,
          relatedEventType: todayCompletedMeal.type,
          relatedEventId: todayCompletedMeal.id,
          destination: GuardianMonitoringDestination.nutrition,
        ),
      );
    }

    if (todayMissedHydration != null) {
      final hydrationSeverity = _wellbeingSeverity(
        missedCount: todayMissedHydrationCount,
        sensitivity: alertSensitivity,
      );
      alerts.add(
        GuardianAlert(
          id: 'missed-hydration-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Hydration routine was missed',
          explanation:
              'Hydration reminders missed today: $todayMissedHydrationCount.',
          happenedAt: todayMissedHydration.happenedAt,
          severity: hydrationSeverity,
          state: GuardianAlertState.active,
          relatedEventType: todayMissedHydration.type,
          relatedEventId: todayMissedHydration.id,
          destination: GuardianMonitoringDestination.hydration,
        ),
      );
    }

    if (todayMissedMeal != null) {
      final mealSeverity = _wellbeingSeverity(
        missedCount: todayMissedMealCount,
        sensitivity: alertSensitivity,
      );
      alerts.add(
        GuardianAlert(
          id: 'missed-meal-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Meal routine was missed',
          explanation: 'Meals missed today: $todayMissedMealCount.',
          happenedAt: todayMissedMeal.happenedAt,
          severity: mealSeverity,
          state: GuardianAlertState.active,
          relatedEventType: todayMissedMeal.type,
          relatedEventId: todayMissedMeal.id,
          destination: GuardianMonitoringDestination.nutrition,
        ),
      );
    }

    final safeZoneState = _resolveSafeZoneState(timeline);
    if (safeZoneState.unresolvedExitEvent != null) {
      final exitEvent = safeZoneState.unresolvedExitEvent!;
      final outsideFor = reference.difference(exitEvent.happenedAt.toLocal());
      final severity = outsideFor >= const Duration(hours: 2)
          ? GuardianAlertSeverity.critical
          : GuardianAlertSeverity.warning;
      alerts.add(
        GuardianAlert(
          id: 'safe-zone-outside-$seniorId',
          seniorId: seniorId,
          title: severity == GuardianAlertSeverity.critical
              ? 'Outside safe zone for extended time'
              : 'Outside safe zone',
          explanation:
              'Senior is outside configured safe zones${outsideFor >= const Duration(hours: 2) ? ' for over 2 hours' : ''}.',
          happenedAt: exitEvent.happenedAt,
          severity: severity,
          state: GuardianAlertState.active,
          relatedEventType: exitEvent.type,
          relatedEventId: exitEvent.id,
          destination: GuardianMonitoringDestination.location,
        ),
      );
    }

    final todaySafeZoneEntered = _latestTodayEvent(
      timeline,
      reference: reference,
      type: AppEventType.safeZoneEntered,
    );
    if (todaySafeZoneEntered != null) {
      final zoneName = todaySafeZoneEntered.payload['zoneName'] as String?;
      alerts.add(
        GuardianAlert(
          id: 'safe-zone-returned-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Back in safe zone',
          explanation: zoneName == null || zoneName.isEmpty
              ? 'The senior returned to a configured safe zone.'
              : 'The senior returned to $zoneName.',
          happenedAt: todaySafeZoneEntered.happenedAt,
          severity: GuardianAlertSeverity.info,
          state: GuardianAlertState.resolved,
          relatedEventType: todaySafeZoneEntered.type,
          relatedEventId: todaySafeZoneEntered.id,
          destination: GuardianMonitoringDestination.location,
        ),
      );
    }

    if (warningSignalsToday >= routineCriticalThreshold) {
      alerts.add(
        GuardianAlert(
          id: 'repeated-missed-routines-${_dayKey(reference)}-$seniorId',
          seniorId: seniorId,
          title: 'Repeated missed routine signals',
          explanation:
              '$warningSignalsToday routine signals were missed today (check-ins, medication, hydration, and meals).',
          happenedAt: reference.toUtc(),
          severity: GuardianAlertSeverity.critical,
          state: GuardianAlertState.active,
          relatedEventType: AppEventType.checkInMissed,
          destination: GuardianMonitoringDestination.timeline,
        ),
      );
    }

    if (incidentProjection.latestDismissedEvent != null) {
      final dismissedEvent = incidentProjection.latestDismissedEvent!;
      alerts.add(
        GuardianAlert(
          id: 'dismissed-incident-${dismissedEvent.id}',
          seniorId: seniorId,
          title: 'Incident dismissed',
          explanation:
              'An incident was dismissed and is now marked as resolved.',
          happenedAt: dismissedEvent.happenedAt,
          severity: GuardianAlertSeverity.info,
          state: GuardianAlertState.resolved,
          relatedEventType: dismissedEvent.type,
          relatedEventId: dismissedEvent.id,
          destination: GuardianMonitoringDestination.incidents,
        ),
      );
    }

    final merged = alerts.map((alert) {
      final persisted = persistedStates[alert.id];
      if (persisted == null) return alert;
      if (alert.state == GuardianAlertState.resolved) return alert;
      return alert.copyWith(state: persisted);
    }).toList(growable: false);
    merged.sort(_sortAlerts);
    return merged;
  }

  GuardianAlertSeverity _wellbeingSeverity({
    required int missedCount,
    required AlertSensitivity sensitivity,
  }) {
    if (missedCount >= _wellbeingCriticalThreshold(sensitivity)) {
      return GuardianAlertSeverity.critical;
    }
    if (missedCount >= _wellbeingWarningThreshold(sensitivity)) {
      return GuardianAlertSeverity.warning;
    }
    return GuardianAlertSeverity.info;
  }

  int _routineCriticalThreshold(AlertSensitivity sensitivity) =>
      switch (sensitivity) {
        AlertSensitivity.low => 4,
        AlertSensitivity.normal => 3,
        AlertSensitivity.high => 2,
      };

  int _wellbeingWarningThreshold(AlertSensitivity sensitivity) =>
      switch (sensitivity) {
        AlertSensitivity.low => 3,
        AlertSensitivity.normal => 2,
        AlertSensitivity.high => 1,
      };

  int _wellbeingCriticalThreshold(AlertSensitivity sensitivity) =>
      switch (sensitivity) {
        AlertSensitivity.low => 4,
        AlertSensitivity.normal => 3,
        AlertSensitivity.high => 2,
      };

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    await _setAlertState(alertId, GuardianAlertState.acknowledged);
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    await _setAlertState(alertId, GuardianAlertState.resolved);
  }

  Future<void> _setAlertState(
    String alertId,
    GuardianAlertState state,
  ) async {
    final map = await _readStateMap();
    map[alertId] = state;
    await _writeStateMap(map);
  }

  Future<Map<String, GuardianAlertState>> _readStateMap() async {
    final raw = storage.getString(StorageKeys.guardianAlertStates);
    if (raw == null || raw.isEmpty) return <String, GuardianAlertState>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'guardian_alert_states must be a JSON object');
    }

    final output = <String, GuardianAlertState>{};
    for (final entry in decoded.entries) {
      if (entry.value is! String) continue;
      output[entry.key] = guardianAlertStateFromRaw(entry.value as String);
    }
    return output;
  }

  Future<void> _writeStateMap(Map<String, GuardianAlertState> map) async {
    final serialized = <String, String>{
      for (final entry in map.entries) entry.key: entry.value.name,
    };
    final saved = await storage.setString(
      StorageKeys.guardianAlertStates,
      jsonEncode(serialized),
    );
    if (!saved) {
      throw StateError('Failed to persist guardian alert state');
    }
  }

  PersistedEventRecord? _latestTodayEvent(
    List<PersistedEventRecord> timeline, {
    required DateTime reference,
    required AppEventType type,
  }) {
    for (final event in timeline.reversed) {
      if (event.type != type) continue;
      if (_isSameLocalDay(event.happenedAt, reference)) {
        return event;
      }
    }
    return null;
  }

  int _todayEventCount(
    List<PersistedEventRecord> timeline, {
    required DateTime reference,
    required AppEventType type,
  }) {
    var count = 0;
    for (final event in timeline) {
      if (event.type != type) continue;
      if (_isSameLocalDay(event.happenedAt, reference)) {
        count += 1;
      }
    }
    return count;
  }

  bool _isSameLocalDay(DateTime timestamp, DateTime reference) {
    final local = timestamp.toLocal();
    return local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
  }

  String _dayKey(DateTime reference) {
    final mm = reference.month.toString().padLeft(2, '0');
    final dd = reference.day.toString().padLeft(2, '0');
    return '${reference.year}-$mm-$dd';
  }

  int _sortAlerts(GuardianAlert left, GuardianAlert right) {
    final severityCompare =
        _severityRank(left.severity).compareTo(_severityRank(right.severity));
    if (severityCompare != 0) return severityCompare;

    final stateCompare =
        _stateRank(left.state).compareTo(_stateRank(right.state));
    if (stateCompare != 0) return stateCompare;

    final timeCompare = right.happenedAt.compareTo(left.happenedAt);
    if (timeCompare != 0) return timeCompare;

    return left.id.compareTo(right.id);
  }

  int _severityRank(GuardianAlertSeverity severity) => switch (severity) {
        GuardianAlertSeverity.critical => 0,
        GuardianAlertSeverity.warning => 1,
        GuardianAlertSeverity.info => 2,
      };

  int _stateRank(GuardianAlertState state) => switch (state) {
        GuardianAlertState.active => 0,
        GuardianAlertState.acknowledged => 1,
        GuardianAlertState.resolved => 2,
      };

  _IncidentProjection _projectIncidentState(
      List<PersistedEventRecord> timeline) {
    final openSuspected = <PersistedEventRecord>[];
    final openConfirmed = <PersistedEventRecord>[];
    final activeEmergencies = <PersistedEventRecord>[];
    PersistedEventRecord? latestDismissed;

    for (final event in timeline) {
      switch (event.type) {
        case AppEventType.incidentSuspected:
          openSuspected.add(event);
        case AppEventType.incidentConfirmed:
          if (openSuspected.isNotEmpty) {
            openSuspected.removeLast();
          }
          openConfirmed.add(event);
        case AppEventType.incidentDismissed:
          if (openConfirmed.isNotEmpty) {
            openConfirmed.removeLast();
          } else if (openSuspected.isNotEmpty) {
            openSuspected.removeLast();
          }
          activeEmergencies.clear();
          latestDismissed = event;
        case AppEventType.emergencyTriggered:
          activeEmergencies.add(event);
        case AppEventType.checkInCompleted:
        case AppEventType.checkInMissed:
        case AppEventType.medicationTaken:
        case AppEventType.medicationMissed:
        case AppEventType.hydrationCompleted:
        case AppEventType.hydrationMissed:
        case AppEventType.mealCompleted:
        case AppEventType.mealMissed:
        case AppEventType.seniorStatusChanged:
        case AppEventType.guardianAlertGenerated:
        case AppEventType.safeZoneEntered:
        case AppEventType.safeZoneExited:
          break;
      }
    }

    return _IncidentProjection(
      openSuspectedEvents:
          List<PersistedEventRecord>.unmodifiable(openSuspected),
      openConfirmedEvents:
          List<PersistedEventRecord>.unmodifiable(openConfirmed),
      activeEmergencyEvents:
          List<PersistedEventRecord>.unmodifiable(activeEmergencies),
      latestDismissedEvent: latestDismissed,
    );
  }
}

class _SafeZoneProjection {
  const _SafeZoneProjection({
    required this.unresolvedExitEvent,
  });

  final PersistedEventRecord? unresolvedExitEvent;
}

_SafeZoneProjection _resolveSafeZoneState(List<PersistedEventRecord> timeline) {
  PersistedEventRecord? unresolvedExitEvent;
  for (final event in timeline) {
    switch (event.type) {
      case AppEventType.safeZoneExited:
        unresolvedExitEvent = event;
      case AppEventType.safeZoneEntered:
        unresolvedExitEvent = null;
      case AppEventType.checkInCompleted:
      case AppEventType.checkInMissed:
      case AppEventType.medicationTaken:
      case AppEventType.medicationMissed:
      case AppEventType.hydrationCompleted:
      case AppEventType.hydrationMissed:
      case AppEventType.mealCompleted:
      case AppEventType.mealMissed:
      case AppEventType.incidentSuspected:
      case AppEventType.incidentConfirmed:
      case AppEventType.incidentDismissed:
      case AppEventType.emergencyTriggered:
      case AppEventType.seniorStatusChanged:
      case AppEventType.guardianAlertGenerated:
        break;
    }
  }
  return _SafeZoneProjection(unresolvedExitEvent: unresolvedExitEvent);
}

class _IncidentProjection {
  const _IncidentProjection({
    required this.openSuspectedEvents,
    required this.openConfirmedEvents,
    required this.activeEmergencyEvents,
    required this.latestDismissedEvent,
  });

  final List<PersistedEventRecord> openSuspectedEvents;
  final List<PersistedEventRecord> openConfirmedEvents;
  final List<PersistedEventRecord> activeEmergencyEvents;
  final PersistedEventRecord? latestDismissedEvent;
}
