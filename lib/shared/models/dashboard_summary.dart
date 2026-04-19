import 'package:senior_companion/shared/models/senior_global_status.dart';

/// A snapshot of the senior's current monitoring state, used by the
/// guardian dashboard to present a clear and actionable overview.
///
/// This model is intentionally flat and read-oriented — it is produced
/// by aggregating events and module states, not by direct user input.
class DashboardSummary {
  const DashboardSummary({
    required this.globalStatus,
    required this.pendingAlerts,
    required this.todayCheckIns,
    required this.missedMedications,
    required this.openIncidents,
    this.lastCheckInAt,
    this.nextScheduledReminder,
  });

  /// The derived global status of the senior at the time of this snapshot.
  ///
  /// This is the primary signal shown to guardians: OK / WATCH / ACTION_REQUIRED.
  /// It must always be explainable from the other fields in this model.
  final SeniorGlobalStatus globalStatus;

  /// Number of alerts that have not yet been acknowledged by any guardian.
  final int pendingAlerts;

  /// Number of check-ins the senior has completed today.
  final int todayCheckIns;

  /// Number of medication confirmations that were missed (not taken, not dismissed)
  /// within their scheduled windows today.
  final int missedMedications;

  /// Number of suspicious incident events that are currently unresolved.
  final int openIncidents;

  /// The timestamp of the most recent completed check-in, if any.
  final DateTime? lastCheckInAt;

  /// The timestamp of the next upcoming scheduled reminder, if any.
  final DateTime? nextScheduledReminder;

  // ── Convenience ────────────────────────────────────────────────────────────

  /// Returns true if there are no pending alerts and no open incidents.
  bool get isFullyClear => pendingAlerts == 0 && openIncidents == 0;

  /// Returns true if there is at least one item that needs guardian attention.
  bool get needsAttention => globalStatus != SeniorGlobalStatus.ok;

  // ── copyWith ───────────────────────────────────────────────────────────────

  DashboardSummary copyWith({
    SeniorGlobalStatus? globalStatus,
    int? pendingAlerts,
    int? todayCheckIns,
    int? missedMedications,
    int? openIncidents,
    DateTime? lastCheckInAt,
    DateTime? nextScheduledReminder,
  }) {
    return DashboardSummary(
      globalStatus: globalStatus ?? this.globalStatus,
      pendingAlerts: pendingAlerts ?? this.pendingAlerts,
      todayCheckIns: todayCheckIns ?? this.todayCheckIns,
      missedMedications: missedMedications ?? this.missedMedications,
      openIncidents: openIncidents ?? this.openIncidents,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      nextScheduledReminder:
          nextScheduledReminder ?? this.nextScheduledReminder,
    );
  }

  // ── Equality ───────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardSummary &&
        other.globalStatus == globalStatus &&
        other.pendingAlerts == pendingAlerts &&
        other.todayCheckIns == todayCheckIns &&
        other.missedMedications == missedMedications &&
        other.openIncidents == openIncidents &&
        other.lastCheckInAt == lastCheckInAt &&
        other.nextScheduledReminder == nextScheduledReminder;
  }

  @override
  int get hashCode => Object.hash(
        globalStatus,
        pendingAlerts,
        todayCheckIns,
        missedMedications,
        openIncidents,
        lastCheckInAt,
        nextScheduledReminder,
      );

  @override
  String toString() => 'DashboardSummary('
      'globalStatus: $globalStatus, '
      'pendingAlerts: $pendingAlerts, '
      'todayCheckIns: $todayCheckIns, '
      'missedMedications: $missedMedications, '
      'openIncidents: $openIncidents, '
      'lastCheckInAt: $lastCheckInAt, '
      'nextScheduledReminder: $nextScheduledReminder'
      ')';
}
