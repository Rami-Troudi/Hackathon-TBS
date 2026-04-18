import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

abstract class GuardianAlertRepository {
  Future<List<GuardianAlert>> fetchAlertsForSenior(
    String seniorId, {
    DateTime? now,
    AlertSensitivity alertSensitivity = AlertSensitivity.normal,
  });

  Future<void> acknowledgeAlert(String alertId);
  Future<void> resolveAlert(String alertId);
}
