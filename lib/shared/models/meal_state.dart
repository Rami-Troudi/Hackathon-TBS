enum MealSlotStatus {
  pending,
  completed,
  missed,
}

class MealSlotState {
  const MealSlotState({
    required this.id,
    required this.mealLabel,
    required this.scheduledAt,
    required this.status,
    this.resolvedAt,
  });

  final String id;
  final String mealLabel;
  final DateTime scheduledAt;
  final MealSlotStatus status;
  final DateTime? resolvedAt;
}

class NutritionState {
  const NutritionState({
    required this.slots,
  });

  final List<MealSlotState> slots;

  int get completedCount =>
      slots.where((slot) => slot.status == MealSlotStatus.completed).length;
  int get missedCount =>
      slots.where((slot) => slot.status == MealSlotStatus.missed).length;
  int get pendingCount =>
      slots.where((slot) => slot.status == MealSlotStatus.pending).length;
}
