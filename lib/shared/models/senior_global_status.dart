import 'package:senior_companion/shared/models/notification_level.dart';

/// The three possible global states of a senior's monitoring status.
///
/// This is the core status model exposed to guardians on their dashboard.
/// It must remain explainable — never derived from an opaque model.
enum SeniorGlobalStatus {
  /// Everything looks fine. All expected events completed.
  ok,

  /// One or more signals need attention. No immediate action required yet.
  watch,

  /// Immediate action is required. An unresolved incident, emergency, or
  /// repeated critical misses have been detected.
  actionRequired,
}

extension SeniorGlobalStatusX on SeniorGlobalStatus {
  /// Human-readable short label suitable for dashboard display.
  String get label => switch (this) {
        SeniorGlobalStatus.ok => 'All good',
        SeniorGlobalStatus.watch => 'Watch',
        SeniorGlobalStatus.actionRequired => 'Action Required',
      };

  /// One-line explanation of what this status means for the guardian.
  String get description => switch (this) {
        SeniorGlobalStatus.ok =>
          'Everything looks fine. No action needed right now.',
        SeniorGlobalStatus.watch =>
          'Some events need attention. Keep an eye on the situation.',
        SeniorGlobalStatus.actionRequired =>
          'Immediate attention is needed. Please check on your loved one.',
      };

  /// Maps each status to an appropriate notification urgency level.
  NotificationLevel get notificationLevel => switch (this) {
        SeniorGlobalStatus.ok => NotificationLevel.info,
        SeniorGlobalStatus.watch => NotificationLevel.warning,
        SeniorGlobalStatus.actionRequired => NotificationLevel.critical,
      };

  /// Whether this status requires the guardian to take action immediately.
  bool get requiresImmediateAction => this == SeniorGlobalStatus.actionRequired;

  /// Whether this status is at a normal / no-concern level.
  bool get isNormal => this == SeniorGlobalStatus.ok;
}