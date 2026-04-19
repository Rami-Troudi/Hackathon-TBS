import 'package:senior_companion/shared/models/incident_flow_state.dart';

abstract class IncidentRepository {
  Future<IncidentFlowState> getCurrentState(String seniorId);

  Future<void> reportSuspiciousIncident(
    String seniorId, {
    DateTime? now,
    double confidenceScore,
  });

  Future<void> confirmIncident(
    String seniorId, {
    DateTime? now,
  });

  Future<void> dismissIncident(
    String seniorId, {
    DateTime? now,
  });

  Future<void> triggerEmergency(
    String seniorId, {
    DateTime? now,
  });

  Future<void> requestImmediateHelp(
    String seniorId, {
    DateTime? now,
  });
}
