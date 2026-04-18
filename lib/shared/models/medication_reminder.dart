import 'package:senior_companion/shared/models/medication_plan.dart';

enum MedicationReminderStatus {
  pending,
  taken,
  missed,
}

class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.plan,
    required this.slotLabel,
    required this.scheduledAt,
    required this.status,
    this.resolvedAt,
  });

  final String id;
  final MedicationPlan plan;
  final String slotLabel;
  final DateTime scheduledAt;
  final MedicationReminderStatus status;
  final DateTime? resolvedAt;

  bool get isPending => status == MedicationReminderStatus.pending;
}
