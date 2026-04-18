import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class SeniorStatusEvaluation {
  const SeniorStatusEvaluation({
    required this.status,
    required this.reasons,
    required this.pendingAlerts,
    required this.todayCheckIns,
    required this.missedMedications,
    required this.missedCheckIns,
    required this.openIncidents,
    required this.openConfirmedIncidents,
    required this.openSuspectedIncidents,
    required this.lastCheckInAt,
  });

  final SeniorGlobalStatus status;
  final List<String> reasons;
  final int pendingAlerts;
  final int todayCheckIns;
  final int missedMedications;
  final int missedCheckIns;
  final int openIncidents;
  final int openConfirmedIncidents;
  final int openSuspectedIncidents;
  final DateTime? lastCheckInAt;
}

class SeniorStatusEngine {
  const SeniorStatusEngine();

  /// Deterministic status rules (evaluated in this order):
  /// 1. Any emergency event -> actionRequired.
  /// 2. Any unresolved confirmed incident -> actionRequired.
  /// 3. Any unresolved suspected incident -> watch (if not already actionRequired).
  /// 4. Three or more missed routine signals today (check-ins + medication) ->
  ///    actionRequired.
  /// 5. One or two missed routine signals today -> watch.
  /// 6. Otherwise -> ok.
  ///
  /// Incident state is derived from event sequence:
  /// - suspected increments suspected-open count
  /// - confirmed moves one suspected incident (if present) into confirmed-open
  /// - dismissed closes one confirmed-open first, otherwise one suspected-open
  ///
  /// This keeps the logic explainable and suitable for local-first prototypes.
  SeniorStatusEvaluation evaluate(
    Iterable<PersistedEventRecord> events, {
    DateTime? now,
  }) {
    final ordered = events.toList()
      ..sort((left, right) => left.happenedAt.compareTo(right.happenedAt));
    final referenceTime = (now ?? DateTime.now()).toLocal();
    DateTime? lastCheckInAt;
    var todayCheckIns = 0;
    var todayMissedMedications = 0;
    var todayMissedCheckIns = 0;
    var openSuspectedIncidents = 0;
    var openConfirmedIncidents = 0;
    var emergencyEvents = 0;

    for (final event in ordered) {
      switch (event.type) {
        case AppEventType.checkInCompleted:
          if (_isSameLocalDay(event.happenedAt, referenceTime)) {
            todayCheckIns += 1;
          }
          if (lastCheckInAt == null ||
              event.happenedAt.isAfter(lastCheckInAt)) {
            lastCheckInAt = event.happenedAt;
          }
        case AppEventType.checkInMissed:
          if (_isSameLocalDay(event.happenedAt, referenceTime)) {
            todayMissedCheckIns += 1;
          }
        case AppEventType.medicationTaken:
          break;
        case AppEventType.medicationMissed:
          if (_isSameLocalDay(event.happenedAt, referenceTime)) {
            todayMissedMedications += 1;
          }
        case AppEventType.incidentSuspected:
          openSuspectedIncidents += 1;
        case AppEventType.incidentConfirmed:
          if (openSuspectedIncidents > 0) {
            openSuspectedIncidents -= 1;
          }
          openConfirmedIncidents += 1;
        case AppEventType.incidentDismissed:
          if (openConfirmedIncidents > 0) {
            openConfirmedIncidents -= 1;
          } else if (openSuspectedIncidents > 0) {
            openSuspectedIncidents -= 1;
          }
        case AppEventType.emergencyTriggered:
          emergencyEvents += 1;
        case AppEventType.seniorStatusChanged:
        case AppEventType.guardianAlertGenerated:
          break;
      }
    }

    final openIncidents = openSuspectedIncidents + openConfirmedIncidents;
    final warningSignals = todayMissedCheckIns + todayMissedMedications;
    final reasons = <String>[];

    SeniorGlobalStatus status = SeniorGlobalStatus.ok;
    if (emergencyEvents > 0) {
      status = SeniorGlobalStatus.actionRequired;
      reasons.add('Emergency event detected');
    }
    if (openConfirmedIncidents > 0) {
      status = SeniorGlobalStatus.actionRequired;
      reasons.add('Unresolved confirmed incident');
    } else if (status == SeniorGlobalStatus.ok && openSuspectedIncidents > 0) {
      status = SeniorGlobalStatus.watch;
      reasons.add('Unresolved suspected incident');
    }
    if (status != SeniorGlobalStatus.actionRequired && warningSignals >= 3) {
      status = SeniorGlobalStatus.actionRequired;
      reasons.add('Multiple missed daily signals');
    } else if (status == SeniorGlobalStatus.ok && warningSignals > 0) {
      status = SeniorGlobalStatus.watch;
      reasons.add('Missed daily routine signals');
    }
    if (status == SeniorGlobalStatus.ok) {
      reasons.add('No active incidents or missed routine signals');
    }

    return SeniorStatusEvaluation(
      status: status,
      reasons: reasons,
      pendingAlerts: emergencyEvents +
          openIncidents +
          todayMissedCheckIns +
          todayMissedMedications,
      todayCheckIns: todayCheckIns,
      missedMedications: todayMissedMedications,
      missedCheckIns: todayMissedCheckIns,
      openIncidents: openIncidents,
      openConfirmedIncidents: openConfirmedIncidents,
      openSuspectedIncidents: openSuspectedIncidents,
      lastCheckInAt: lastCheckInAt,
    );
  }

  bool _isSameLocalDay(DateTime timestamp, DateTime reference) {
    final local = timestamp.toLocal();
    return local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
  }
}
