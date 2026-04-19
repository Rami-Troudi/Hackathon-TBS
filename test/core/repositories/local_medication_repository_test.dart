import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_medication_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class _FakeProfileRepository implements ProfileRepository {
  static const _seniors = <SeniorProfile>[
    SeniorProfile(
      id: 'senior-a',
      displayName: 'Senior A',
      age: 74,
      preferredLanguage: 'fr',
      largeTextEnabled: true,
      highContrastEnabled: false,
      linkedGuardianIds: <String>['guardian-a'],
    ),
  ];

  @override
  Future<void> clearAllProfiles() async {}

  @override
  Future<List<GuardianProfile>> getGuardianProfiles() async =>
      const <GuardianProfile>[];

  @override
  Future<GuardianProfile?> getGuardianProfileById(String id) async => null;

  @override
  Future<List<GuardianProfile>> getLinkedGuardians(String seniorId) async =>
      const <GuardianProfile>[];

  @override
  Future<List<SeniorProfile>> getLinkedSeniors(String guardianId) async =>
      _seniors;

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async => _seniors;

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async {
    for (final senior in _seniors) {
      if (senior.id == id) return senior;
    }
    return null;
  }

  @override
  Future<void> saveGuardianProfiles(List<GuardianProfile> profiles) async {}

  @override
  Future<void> saveProfileLinks(List<ProfileLink> links) async {}

  @override
  Future<void> saveSeniorProfiles(List<SeniorProfile> profiles) async {}
}

void main() {
  test('getPlansForSenior seeds default plans once', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-medication-seed');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async => Hive.init(tempDir.path),
    );
    await initializer.initialize();

    final eventRepository = LocalEventRepository(
      hiveInitializer: initializer,
      eventMapper: const AppEventMapper(),
      profileRepository: _FakeProfileRepository(),
    );
    final repository = LocalMedicationRepository(
      hiveInitializer: initializer,
      profileRepository: _FakeProfileRepository(),
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    final firstRead = await repository.getPlansForSenior('senior-a');
    final secondRead = await repository.getPlansForSenior('senior-a');

    expect(firstRead, hasLength(2));
    expect(secondRead, hasLength(2));
    expect(firstRead.map((plan) => plan.id).toSet().length, 2);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('markMedicationTaken records event and updates reminder state',
      () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-medication-taken');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async => Hive.init(tempDir.path),
    );
    await initializer.initialize();

    final eventRepository = LocalEventRepository(
      hiveInitializer: initializer,
      eventMapper: const AppEventMapper(),
      profileRepository: _FakeProfileRepository(),
    );
    final repository = LocalMedicationRepository(
      hiveInitializer: initializer,
      profileRepository: _FakeProfileRepository(),
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    final plans = await repository.getPlansForSenior('senior-a');
    final takenFirst = await repository.markMedicationTaken(
      'senior-a',
      planId: plans.first.id,
      now: DateTime(2026, 4, 18, 8, 30),
    );
    final takenSecond = await repository.markMedicationTaken(
      'senior-a',
      planId: plans.first.id,
      now: DateTime(2026, 4, 18, 8, 45),
    );
    final reminders = await repository.getTodayReminders(
      'senior-a',
      now: DateTime(2026, 4, 18, 9, 0),
    );
    final firstReminder = reminders.firstWhere(
      (reminder) => reminder.plan.id == plans.first.id,
    );
    final takenEvents = await eventRepository.fetchEventsByTypeForSenior(
      'senior-a',
      AppEventType.medicationTaken,
    );

    expect(takenFirst, isTrue);
    expect(takenSecond, isFalse);
    expect(firstReminder.status, MedicationReminderStatus.taken);
    expect(takenEvents, hasLength(1));

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('markMedicationMissed records one missed event per day', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-medication-missed');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async => Hive.init(tempDir.path),
    );
    await initializer.initialize();

    final eventRepository = LocalEventRepository(
      hiveInitializer: initializer,
      eventMapper: const AppEventMapper(),
      profileRepository: _FakeProfileRepository(),
    );
    final repository = LocalMedicationRepository(
      hiveInitializer: initializer,
      profileRepository: _FakeProfileRepository(),
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    final plans = await repository.getPlansForSenior('senior-a');
    final missedFirst = await repository.markMedicationMissed(
      'senior-a',
      planId: plans.first.id,
      now: DateTime(2026, 4, 18, 9, 0),
    );
    final missedSecond = await repository.markMedicationMissed(
      'senior-a',
      planId: plans.first.id,
      now: DateTime(2026, 4, 18, 11, 0),
    );

    final missedEvents = await eventRepository.fetchEventsByTypeForSenior(
      'senior-a',
      AppEventType.medicationMissed,
    );

    expect(missedFirst, isTrue);
    expect(missedSecond, isFalse);
    expect(missedEvents, hasLength(1));

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
