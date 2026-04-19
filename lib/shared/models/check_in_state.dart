enum CheckInStatus {
  pending,
  completed,
  missed,
}

class CheckInState {
  const CheckInState({
    required this.status,
    required this.windowLabel,
    required this.windowStart,
    required this.windowEnd,
    this.completedAt,
    this.missedAt,
  });

  final CheckInStatus status;
  final String windowLabel;
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime? completedAt;
  final DateTime? missedAt;

  bool get isPending => status == CheckInStatus.pending;
  bool get isCompleted => status == CheckInStatus.completed;
  bool get isMissed => status == CheckInStatus.missed;
}
