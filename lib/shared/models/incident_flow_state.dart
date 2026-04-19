enum IncidentFlowStatus {
  clear,
  suspected,
  confirmed,
  emergency,
}

class IncidentFlowState {
  const IncidentFlowState({
    required this.status,
    required this.openSuspectedIncidents,
    required this.openConfirmedIncidents,
    this.lastEventAt,
  });

  final IncidentFlowStatus status;
  final int openSuspectedIncidents;
  final int openConfirmedIncidents;
  final DateTime? lastEventAt;

  bool get hasOpenIncident =>
      openSuspectedIncidents > 0 || openConfirmedIncidents > 0;
}
