import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_incident_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
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
  test('requestImmediateHelp emits confirmed and emergency events', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-incident-immediate-help');
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
    final repository = LocalIncidentRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
      statusEngine: const SeniorStatusEngine(),
    );

    await repository.requestImmediateHelp(
      'senior-a',
      now: DateTime(2026, 4, 18, 11, 0),
    );

    final state = await repository.getCurrentState('senior-a');
    final timeline = await eventRepository.fetchTimelineForSenior('senior-a');
    final confirmed = timeline
        .where((event) => event.type == AppEventType.incidentConfirmed)
        .length;
    final emergency = timeline
        .where((event) => event.type == AppEventType.emergencyTriggered)
        .length;

    expect(confirmed, 1);
    expect(emergency, 1);
    expect(state.status, IncidentFlowStatus.emergency);
    expect(state.openConfirmedIncidents, 1);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('dismissIncident clears a suspected incident state', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-incident-dismiss');
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
    final repository = LocalIncidentRepository(
      eventRepository: eventRepository,
      eventRecorder: AppEventRecorder(
        eventBus: AppEventBus(),
        eventRepository: eventRepository,
      ),
      statusEngine: const SeniorStatusEngine(),
    );

    await repository.reportSuspiciousIncident(
      'senior-a',
      now: DateTime(2026, 4, 18, 10, 0),
    );
    final beforeDismiss = await repository.getCurrentState('senior-a');

    await repository.dismissIncident(
      'senior-a',
      now: DateTime(2026, 4, 18, 10, 5),
    );
    final afterDismiss = await repository.getCurrentState('senior-a');

    expect(beforeDismiss.status, IncidentFlowStatus.suspected);
    expect(afterDismiss.status, IncidentFlowStatus.clear);
    expect(afterDismiss.hasOpenIncident, isFalse);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
