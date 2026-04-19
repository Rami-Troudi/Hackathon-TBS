import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/shared/models/medication_plan.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class GuardianMedicationMonitoringData {
  const GuardianMedicationMonitoringData({
    required this.seniorId,
    required this.seniorProfile,
    required this.plans,
    required this.todayReminders,
    required this.recentMedicationEvents,
    required this.takenToday,
    required this.missedToday,
    required this.pendingToday,
    required this.adherenceRateLast7Days,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final List<MedicationPlan> plans;
  final List<MedicationReminder> todayReminders;
  final List<PersistedEventRecord> recentMedicationEvents;
  final int takenToday;
  final int missedToday;
  final int pendingToday;
  final double adherenceRateLast7Days;
}

final guardianMedicationMonitoringDataProvider =
    FutureProvider.autoDispose<GuardianMedicationMonitoringData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final medicationRepository = ref.watch(medicationRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);

  final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const GuardianMedicationMonitoringData(
      seniorId: null,
      seniorProfile: null,
      plans: <MedicationPlan>[],
      todayReminders: <MedicationReminder>[],
      recentMedicationEvents: <PersistedEventRecord>[],
      takenToday: 0,
      missedToday: 0,
      pendingToday: 0,
      adherenceRateLast7Days: 0,
    );
  }

  final profile = await profileRepository.getSeniorProfileById(seniorId);
  final plans = await medicationRepository.getPlansForSenior(seniorId);
  final reminders = await medicationRepository.getTodayReminders(seniorId);
  final recentEvents = await eventRepository.fetchTimelineForSenior(
    seniorId,
    order: TimelineOrder.newestFirst,
    types: const <AppEventType>{
      AppEventType.medicationTaken,
      AppEventType.medicationMissed,
    },
    limit: 40,
  );

  final takenToday = reminders
      .where((reminder) => reminder.status == MedicationReminderStatus.taken)
      .length;
  final missedToday = reminders
      .where((reminder) => reminder.status == MedicationReminderStatus.missed)
      .length;
  final pendingToday = reminders
      .where((reminder) => reminder.status == MedicationReminderStatus.pending)
      .length;

  final sevenDaysAgo =
      DateTime.now().toLocal().subtract(const Duration(days: 7));
  final trendEvents = recentEvents.where(
    (event) => event.happenedAt.toLocal().isAfter(sevenDaysAgo),
  );
  final takenCount = trendEvents
      .where((event) => event.type == AppEventType.medicationTaken)
      .length;
  final missedCount = trendEvents
      .where((event) => event.type == AppEventType.medicationMissed)
      .length;
  final adherenceBase = takenCount + missedCount;
  final adherenceRate =
      adherenceBase == 0 ? 0.0 : (takenCount / adherenceBase) * 100.0;

  return GuardianMedicationMonitoringData(
    seniorId: seniorId,
    seniorProfile: profile,
    plans: plans,
    todayReminders: reminders,
    recentMedicationEvents: recentEvents,
    takenToday: takenToday,
    missedToday: missedToday,
    pendingToday: pendingToday,
    adherenceRateLast7Days: adherenceRate,
  );
});
