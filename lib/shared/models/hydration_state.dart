enum HydrationSlotStatus {
  pending,
  completed,
  missed,
}

class HydrationSlotState {
  const HydrationSlotState({
    required this.id,
    required this.label,
    required this.scheduledAt,
    required this.status,
    this.resolvedAt,
  });

  final String id;
  final String label;
  final DateTime scheduledAt;
  final HydrationSlotStatus status;
  final DateTime? resolvedAt;
}

class HydrationState {
  const HydrationState({
    required this.slots,
    required this.dailyGoalCompletions,
  });

  final List<HydrationSlotState> slots;
  final int dailyGoalCompletions;

  int get completedCount => slots
      .where((slot) => slot.status == HydrationSlotStatus.completed)
      .length;
  int get missedCount =>
      slots.where((slot) => slot.status == HydrationSlotStatus.missed).length;
  int get pendingCount =>
      slots.where((slot) => slot.status == HydrationSlotStatus.pending).length;

  bool get goalReached => completedCount >= dailyGoalCompletions;
}
