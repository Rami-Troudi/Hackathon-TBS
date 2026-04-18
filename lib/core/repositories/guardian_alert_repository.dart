import 'package:senior_companion/shared/models/guardian_alert.dart';

abstract class GuardianAlertRepository {
  Future<List<GuardianAlert>> fetchAlertsForSenior(
    String seniorId, {
    DateTime? now,
  });

  Future<void> acknowledgeAlert(String alertId);
  Future<void> resolveAlert(String alertId);
}
