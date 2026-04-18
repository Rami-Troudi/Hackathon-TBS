import 'package:senior_companion/shared/models/medication_plan.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';

abstract class MedicationRepository {
  Future<List<MedicationPlan>> getPlansForSenior(String seniorId);

  Future<List<MedicationReminder>> getTodayReminders(
    String seniorId, {
    DateTime? now,
  });

  Future<MedicationReminder?> getNextPendingReminder(
    String seniorId, {
    DateTime? now,
  });

  Future<bool> markMedicationTaken(
    String seniorId, {
    required String planId,
    DateTime? now,
  });

  Future<bool> markMedicationMissed(
    String seniorId, {
    required String planId,
    DateTime? now,
  });
}
