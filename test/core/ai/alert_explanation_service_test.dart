import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/ai/alert_explanation_service.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';

void main() {
  test('alert explanation maps destination to grounded explanation', () {
    const service = AlertExplanationService();
    final alert = GuardianAlert(
      id: 'a1',
      seniorId: 'senior-a',
      title: 'Hydration routine was missed',
      explanation: 'Hydration reminders missed today: 2.',
      happenedAt: DateTime.parse('2026-04-19T10:00:00Z'),
      severity: GuardianAlertSeverity.warning,
      state: GuardianAlertState.active,
      relatedEventType: AppEventType.hydrationMissed,
      destination: GuardianMonitoringDestination.hydration,
    );

    final explanation = service.explainAlert(alert);

    expect(explanation, contains('hydration'));
    expect(explanation, contains('missed today'));
  });
}
