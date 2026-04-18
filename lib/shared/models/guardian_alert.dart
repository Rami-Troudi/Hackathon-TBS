import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';

enum GuardianAlertSeverity {
  info,
  warning,
  critical,
}

enum GuardianMonitoringDestination {
  timeline,
  checkIns,
  medication,
  incidents,
}

class GuardianAlert {
  const GuardianAlert({
    required this.id,
    required this.seniorId,
    required this.title,
    required this.explanation,
    required this.happenedAt,
    required this.severity,
    required this.state,
    required this.relatedEventType,
    this.relatedEventId,
    required this.destination,
  });

  final String id;
  final String seniorId;
  final String title;
  final String explanation;
  final DateTime happenedAt;
  final GuardianAlertSeverity severity;
  final GuardianAlertState state;
  final AppEventType relatedEventType;
  final String? relatedEventId;
  final GuardianMonitoringDestination destination;

  bool get isActive => state == GuardianAlertState.active;

  GuardianAlert copyWith({
    String? id,
    String? seniorId,
    String? title,
    String? explanation,
    DateTime? happenedAt,
    GuardianAlertSeverity? severity,
    GuardianAlertState? state,
    AppEventType? relatedEventType,
    String? relatedEventId,
    GuardianMonitoringDestination? destination,
  }) {
    return GuardianAlert(
      id: id ?? this.id,
      seniorId: seniorId ?? this.seniorId,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      happenedAt: happenedAt ?? this.happenedAt,
      severity: severity ?? this.severity,
      state: state ?? this.state,
      relatedEventType: relatedEventType ?? this.relatedEventType,
      relatedEventId: relatedEventId ?? this.relatedEventId,
      destination: destination ?? this.destination,
    );
  }
}

extension GuardianAlertSeverityX on GuardianAlertSeverity {
  String get label => switch (this) {
        GuardianAlertSeverity.info => 'Info',
        GuardianAlertSeverity.warning => 'Warning',
        GuardianAlertSeverity.critical => 'Critical',
      };
}

extension GuardianAlertStateX on GuardianAlertState {
  String get label => switch (this) {
        GuardianAlertState.active => 'Active',
        GuardianAlertState.acknowledged => 'Acknowledged',
        GuardianAlertState.resolved => 'Resolved',
      };
}
