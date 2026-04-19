import 'package:senior_companion/shared/models/guardian_alert.dart';

class AlertExplanationService {
  const AlertExplanationService();

  String explainAlert(GuardianAlert alert) {
    final base = switch (alert.destination) {
      GuardianMonitoringDestination.checkIns =>
        'This alert is linked to check-in adherence.',
      GuardianMonitoringDestination.medication =>
        'This alert is linked to medication adherence.',
      GuardianMonitoringDestination.hydration =>
        'This alert is linked to hydration routine adherence.',
      GuardianMonitoringDestination.nutrition =>
        'This alert is linked to meal routine adherence.',
      GuardianMonitoringDestination.location =>
        'This alert is linked to safe-zone/location monitoring.',
      GuardianMonitoringDestination.incidents =>
        'This alert is linked to incident/emergency monitoring.',
      GuardianMonitoringDestination.timeline =>
        'This alert is linked to combined timeline risk signals.',
    };
    return '$base ${alert.explanation}';
  }

  List<String> summarizeActiveAlerts(List<GuardianAlert> alerts) {
    final active = alerts
        .where((alert) => alert.isActive)
        .toList(growable: false)
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    if (active.isEmpty) {
      return const <String>['No active alerts right now.'];
    }
    return active
        .take(5)
        .map((alert) => '${alert.severity.label}: ${alert.title}')
        .toList(growable: false);
  }
}
