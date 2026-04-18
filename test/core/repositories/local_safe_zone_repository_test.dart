import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_safe_zone_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
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
  test('simulated movement publishes safe-zone entered and exited events',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('senior-companion-safe-zone');
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
    final repository = LocalSafeZoneRepository(
      hiveInitializer: initializer,
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
    );

    await repository.seedDefaultZonesIfNeeded('senior-a');
    await repository.updateSimulatedLocation(
      'senior-a',
      latitude: 36.8065,
      longitude: 10.1815,
      label: 'Home',
      now: DateTime(2026, 4, 18, 9, 0),
    );
    final outside = await repository.updateSimulatedLocation(
      'senior-a',
      latitude: 36.8365,
      longitude: 10.2115,
      label: 'Outside safe zones',
      now: DateTime(2026, 4, 18, 10, 0),
    );

    final enteredEvents = await eventRepository.fetchEventsByTypeForSenior(
      'senior-a',
      AppEventType.safeZoneEntered,
    );
    final exitedEvents = await eventRepository.fetchEventsByTypeForSenior(
      'senior-a',
      AppEventType.safeZoneExited,
    );

    expect(enteredEvents, hasLength(1));
    expect(exitedEvents, hasLength(1));
    expect(outside.isInsideSafeZone, isFalse);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
