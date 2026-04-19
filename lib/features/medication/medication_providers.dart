import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';

class MedicationData {
  const MedicationData({
    required this.seniorId,
    required this.reminders,
  });

  final String? seniorId;
  final List<MedicationReminder> reminders;
}

final medicationDataProvider =
    FutureProvider.autoDispose<MedicationData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final repository = ref.watch(medicationRepositoryProvider);
  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const MedicationData(
      seniorId: null,
      reminders: <MedicationReminder>[],
    );
  }

  final reminders = await repository.getTodayReminders(seniorId);
  return MedicationData(
    seniorId: seniorId,
    reminders: reminders,
  );
});
