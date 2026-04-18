import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/repositories/local/local_check_in_repository.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
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
  test('markCheckInCompleted records one completion per day', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-checkin-complete');
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
    final checkInRepository = LocalCheckInRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    final createdFirst = await checkInRepository.markCheckInCompleted(
      'senior-a',
      now: DateTime(2026, 4, 18, 9, 0),
    );
    final createdSecond = await checkInRepository.markCheckInCompleted(
      'senior-a',
      now: DateTime(2026, 4, 18, 9, 30),
    );
    final state = await checkInRepository.getTodayState(
      'senior-a',
      now: DateTime(2026, 4, 18, 10, 0),
      reconcileMissedWindow: true,
    );

    expect(createdFirst, isTrue);
    expect(createdSecond, isFalse);
    expect(state.status, CheckInStatus.completed);
    expect(state.completedAt, isNotNull);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('reconcileMissedWindow creates missed check-in when window is passed',
      () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-checkin-reconcile');
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
    final checkInRepository = LocalCheckInRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    final state = await checkInRepository.getTodayState(
      'senior-a',
      now: DateTime(2026, 4, 18, 13, 0),
      reconcileMissedWindow: true,
    );
    final events = await checkInRepository.fetchRecentCheckIns('senior-a');

    expect(state.status, CheckInStatus.missed);
    expect(
      events.any((event) => event.type == AppEventType.checkInMissed),
      isTrue,
    );

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('markNeedHelp emits confirmed and emergency events once per day',
      () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-checkin-help-request');
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
    final checkInRepository = LocalCheckInRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    await checkInRepository.markNeedHelp(
      'senior-a',
      now: DateTime(2026, 4, 18, 10, 0),
    );
    await checkInRepository.markNeedHelp(
      'senior-a',
      now: DateTime(2026, 4, 18, 10, 30),
    );

    final timeline = await eventRepository.fetchTimelineForSenior('senior-a');
    final confirmedCount = timeline
        .where((event) => event.type == AppEventType.incidentConfirmed)
        .length;
    final emergencyCount = timeline
        .where((event) => event.type == AppEventType.emergencyTriggered)
        .length;

    expect(confirmedCount, 1);
    expect(emergencyCount, 1);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
