import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/medication_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_box_names.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/medication_plan.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';

class LocalMedicationRepository implements MedicationRepository {
  const LocalMedicationRepository({
    required this.hiveInitializer,
    required this.profileRepository,
    required this.eventRepository,
    required this.eventRecorder,
  });

  final HiveInitializer hiveInitializer;
  final ProfileRepository profileRepository;
  final EventRepository eventRepository;
  final AppEventRecorder eventRecorder;

  @override
  Future<List<MedicationPlan>> getPlansForSenior(String seniorId) async {
    var plans = _readPlansForSenior(seniorId);
    if (plans.isEmpty) {
      await _seedDefaultPlansForSenior(seniorId);
      plans = _readPlansForSenior(seniorId);
    }
    return plans.where((plan) => plan.isActive).toList(growable: false);
  }

  @override
  Future<List<MedicationReminder>> getTodayReminders(
    String seniorId, {
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final plans = await getPlansForSenior(seniorId);
    final todayEvents = await _todayMedicationEvents(seniorId, reference);
    final latestEventByMedication = <String, PersistedEventRecord>{};
    for (final event in todayEvents) {
      final medicationName = event.payload['medicationName'] as String?;
      if (medicationName == null) continue;
      latestEventByMedication[medicationName] ??= event;
    }

    final reminders = <MedicationReminder>[];
    for (final plan in plans) {
      for (final slot in plan.scheduledTimes) {
        final scheduledAt = _scheduledDateTime(reference, slot);
        final latestEvent = latestEventByMedication[plan.medicationName];
        final status = switch (latestEvent?.type) {
          AppEventType.medicationTaken => MedicationReminderStatus.taken,
          AppEventType.medicationMissed => MedicationReminderStatus.missed,
          _ => MedicationReminderStatus.pending,
        };
        reminders.add(
          MedicationReminder(
            id: '${plan.id}::$slot',
            plan: plan,
            slotLabel: slot,
            scheduledAt: scheduledAt,
            status: status,
            resolvedAt: latestEvent?.happenedAt.toLocal(),
          ),
        );
      }
    }

    reminders
        .sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return reminders;
  }

  @override
  Future<MedicationReminder?> getNextPendingReminder(
    String seniorId, {
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final reminders = await getTodayReminders(
      seniorId,
      now: reference,
    );
    final pending = reminders.where((item) => item.isPending).toList();
    if (pending.isEmpty) return null;

    pending
        .sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    for (final reminder in pending) {
      if (!reminder.scheduledAt.isBefore(reference)) {
        return reminder;
      }
    }
    return pending.first;
  }

  @override
  Future<bool> markMedicationTaken(
    String seniorId, {
    required String planId,
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final plan = _findPlanById(planId);
    if (plan == null || plan.seniorId != seniorId) {
      throw StateError('Medication plan not found for senior: $planId');
    }

    final alreadyTaken = await _hasMedicationEventToday(
      seniorId,
      medicationName: plan.medicationName,
      type: AppEventType.medicationTaken,
      reference: reference,
    );
    if (alreadyTaken) return false;

    await eventRecorder.publishAndPersist(
      MedicationTakenEvent(
        seniorId: seniorId,
        happenedAt: reference.toUtc(),
        medicationName: plan.medicationName,
      ),
      source: 'senior.medication',
    );
    return true;
  }

  @override
  Future<bool> markMedicationMissed(
    String seniorId, {
    required String planId,
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final plan = _findPlanById(planId);
    if (plan == null || plan.seniorId != seniorId) {
      throw StateError('Medication plan not found for senior: $planId');
    }

    final alreadyMissed = await _hasMedicationEventToday(
      seniorId,
      medicationName: plan.medicationName,
      type: AppEventType.medicationMissed,
      reference: reference,
    );
    if (alreadyMissed) return false;

    await eventRecorder.publishAndPersist(
      MedicationMissedEvent(
        seniorId: seniorId,
        happenedAt: reference.toUtc(),
        medicationName: plan.medicationName,
      ),
      source: 'senior.medication',
    );
    return true;
  }

  List<MedicationPlan> _readPlansForSenior(String seniorId) {
    return _box.values
        .map((entry) =>
            MedicationPlan.fromJson(Map<String, dynamic>.from(entry)))
        .where((plan) => plan.seniorId == seniorId)
        .toList(growable: false);
  }

  MedicationPlan? _findPlanById(String planId) {
    final value = _box.get(planId);
    if (value == null) return null;
    return MedicationPlan.fromJson(Map<String, dynamic>.from(value));
  }

  Future<void> _seedDefaultPlansForSenior(String seniorId) async {
    final profile = await profileRepository.getSeniorProfileById(seniorId);
    if (profile == null) return;

    final plans = <MedicationPlan>[
      MedicationPlan(
        id: '$seniorId-plan-morning-heart',
        seniorId: seniorId,
        medicationName: 'Cardio Protect',
        dosageLabel: '1 tablet',
        scheduledTimes: const <String>['08:00'],
        isActive: true,
        note: 'Take after breakfast',
      ),
      MedicationPlan(
        id: '$seniorId-plan-evening-vitamin',
        seniorId: seniorId,
        medicationName: 'Vitamin D',
        dosageLabel: '1 capsule',
        scheduledTimes: const <String>['19:00'],
        isActive: true,
        note: profile.preferredLanguage == 'ar'
            ? 'خذها بعد العشاء'
            : 'Take after dinner',
      ),
    ];

    for (final plan in plans) {
      await _box.put(plan.id, plan.toJson());
    }
  }

  Future<List<PersistedEventRecord>> _todayMedicationEvents(
    String seniorId,
    DateTime reference,
  ) async {
    final events = await eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      types: const <AppEventType>{
        AppEventType.medicationTaken,
        AppEventType.medicationMissed,
      },
      limit: 100,
    );
    return events
        .where((event) => _isSameLocalDay(event.happenedAt, reference))
        .toList(growable: false);
  }

  Future<bool> _hasMedicationEventToday(
    String seniorId, {
    required String medicationName,
    required AppEventType type,
    required DateTime reference,
  }) async {
    final events = await _todayMedicationEvents(seniorId, reference);
    return events.any(
      (event) =>
          event.type == type &&
          event.payload['medicationName'] == medicationName,
    );
  }

  DateTime _scheduledDateTime(DateTime reference, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts.first);
    final minute = int.parse(parts.last);
    return DateTime(
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    );
  }

  bool _isSameLocalDay(DateTime timestamp, DateTime reference) {
    final local = timestamp.toLocal();
    return local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
  }

  Box<Map> get _box => hiveInitializer.box(HiveBoxNames.medicationPlans);
}
