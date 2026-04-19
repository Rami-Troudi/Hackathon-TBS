import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_hydration_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class _FakeProfileRepository implements ProfileRepository {
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
      const <SeniorProfile>[];

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async =>
      const <SeniorProfile>[];

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async => null;

  @override
  Future<void> saveGuardianProfiles(List<GuardianProfile> profiles) async {}

  @override
  Future<void> saveProfileLinks(List<ProfileLink> links) async {}

  @override
  Future<void> saveSeniorProfiles(List<SeniorProfile> profiles) async {}
}

void main() {
  test('markHydrationCompleted records a single completion per slot/day',
      () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-hydration-complete');
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
    final repository = LocalHydrationRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    final first = await repository.markHydrationCompleted(
      'senior-a',
      slotId: 'hydration-morning',
      now: DateTime(2026, 4, 18, 9, 15),
    );
    final second = await repository.markHydrationCompleted(
      'senior-a',
      slotId: 'hydration-morning',
      now: DateTime(2026, 4, 18, 9, 30),
    );
    final timeline = await eventRepository.fetchEventsByTypeForSenior(
      'senior-a',
      AppEventType.hydrationCompleted,
    );

    expect(first, isTrue);
    expect(second, isFalse);
    expect(timeline, hasLength(1));

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('reconcile marks slots as missed after grace window', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-hydration-missed');
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
    final repository = LocalHydrationRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    final state = await repository.getTodayState(
      'senior-a',
      now: DateTime(2026, 4, 18, 21, 30),
      reconcileMissedSlots: true,
    );
    final missedEvents = await eventRepository.fetchEventsByTypeForSenior(
      'senior-a',
      AppEventType.hydrationMissed,
    );

    expect(state.missedCount, 3);
    expect(missedEvents, hasLength(3));

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('can mark hydration completed after an auto-missed slot', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-hydration-late');
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
    final repository = LocalHydrationRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    await repository.getTodayState(
      'senior-a',
      now: DateTime(2026, 4, 18, 22, 0),
      reconcileMissedSlots: true,
    );
    final completed = await repository.markHydrationCompleted(
      'senior-a',
      slotId: 'hydration-morning',
      now: DateTime(2026, 4, 18, 22, 5),
    );
    final state = await repository.getTodayState(
      'senior-a',
      now: DateTime(2026, 4, 18, 22, 10),
      reconcileMissedSlots: false,
    );

    final morning =
        state.slots.firstWhere((slot) => slot.id == 'hydration-morning');
    expect(completed, isTrue);
    expect(morning.status, HydrationSlotStatus.completed);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
