import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({
    required this.seniors,
    required this.guardians,
  });

  final List<SeniorProfile> seniors;
  final List<GuardianProfile> guardians;

  @override
  Future<void> clearAllProfiles() async {}

  @override
  Future<List<GuardianProfile>> getGuardianProfiles() async => guardians;

  @override
  Future<GuardianProfile?> getGuardianProfileById(String id) async {
    for (final guardian in guardians) {
      if (guardian.id == id) return guardian;
    }
    return null;
  }

  @override
  Future<List<GuardianProfile>> getLinkedGuardians(String seniorId) async {
    return guardians
        .where((guardian) => guardian.linkedSeniorIds.contains(seniorId))
        .toList();
  }

  @override
  Future<List<SeniorProfile>> getLinkedSeniors(String guardianId) async {
    return seniors
        .where((senior) => senior.linkedGuardianIds.contains(guardianId))
        .toList();
  }

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async => seniors;

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async {
    for (final senior in seniors) {
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
  test(
      'LocalEventRepository persists and returns timeline in newest-first order',
      () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-events-timeline');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async => Hive.init(tempDir.path),
    );
    await initializer.initialize();

    final repository = LocalEventRepository(
      hiveInitializer: initializer,
      eventMapper: const AppEventMapper(),
      profileRepository: _FakeProfileRepository(
        seniors: const <SeniorProfile>[
          SeniorProfile(
            id: 'senior-a',
            displayName: 'Senior A',
            age: 70,
            preferredLanguage: 'fr',
            largeTextEnabled: true,
            highContrastEnabled: false,
            linkedGuardianIds: <String>['guardian-a'],
          ),
        ],
        guardians: const <GuardianProfile>[
          GuardianProfile(
            id: 'guardian-a',
            displayName: 'Guardian A',
            relationshipLabel: 'Daughter',
            pushAlertNotificationsEnabled: true,
            dailySummaryEnabled: true,
            linkedSeniorIds: <String>['senior-a'],
          ),
        ],
      ),
    );

    await repository.addAppEvent(
      CheckInCompletedEvent(
        seniorId: 'senior-a',
        happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
      ),
      source: 'test',
    );
    await repository.addAppEvent(
      MedicationMissedEvent(
        seniorId: 'senior-a',
        happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
        medicationName: 'Aspirin',
      ),
      source: 'test',
    );

    final timeline = await repository.fetchTimelineForSenior('senior-a');
    expect(timeline, hasLength(2));
    expect(timeline.first.type, AppEventType.medicationMissed);
    expect(timeline.last.type, AppEventType.checkInCompleted);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('LocalEventRepository filters by type and guardian-linked seniors',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('senior-companion-events-filter');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async => Hive.init(tempDir.path),
    );
    await initializer.initialize();

    final repository = LocalEventRepository(
      hiveInitializer: initializer,
      eventMapper: const AppEventMapper(),
      profileRepository: _FakeProfileRepository(
        seniors: const <SeniorProfile>[
          SeniorProfile(
            id: 'senior-a',
            displayName: 'Senior A',
            age: 70,
            preferredLanguage: 'fr',
            largeTextEnabled: true,
            highContrastEnabled: false,
            linkedGuardianIds: <String>['guardian-a'],
          ),
          SeniorProfile(
            id: 'senior-b',
            displayName: 'Senior B',
            age: 75,
            preferredLanguage: 'ar',
            largeTextEnabled: true,
            highContrastEnabled: true,
            linkedGuardianIds: <String>['guardian-b'],
          ),
        ],
        guardians: const <GuardianProfile>[
          GuardianProfile(
            id: 'guardian-a',
            displayName: 'Guardian A',
            relationshipLabel: 'Daughter',
            pushAlertNotificationsEnabled: true,
            dailySummaryEnabled: true,
            linkedSeniorIds: <String>['senior-a'],
          ),
          GuardianProfile(
            id: 'guardian-b',
            displayName: 'Guardian B',
            relationshipLabel: 'Son',
            pushAlertNotificationsEnabled: true,
            dailySummaryEnabled: true,
            linkedSeniorIds: <String>['senior-b'],
          ),
        ],
      ),
    );

    await repository.addAppEvent(
      MedicationMissedEvent(
        seniorId: 'senior-a',
        happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
        medicationName: 'Aspirin',
      ),
    );
    await repository.addAppEvent(
      CheckInCompletedEvent(
        seniorId: 'senior-a',
        happenedAt: DateTime.parse('2026-04-18T09:10:00Z'),
      ),
    );
    await repository.addAppEvent(
      EmergencyTriggeredEvent(
        seniorId: 'senior-b',
        happenedAt: DateTime.parse('2026-04-18T09:20:00Z'),
      ),
    );

    final seniorTypeFiltered = await repository.fetchEventsByTypeForSenior(
      'senior-a',
      AppEventType.medicationMissed,
    );
    expect(seniorTypeFiltered, hasLength(1));
    expect(seniorTypeFiltered.first.type, AppEventType.medicationMissed);

    final guardianEvents =
        await repository.fetchEventsForGuardian('guardian-a');
    expect(guardianEvents, hasLength(2));
    expect(
        guardianEvents.every((event) => event.seniorId == 'senior-a'), isTrue);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('LocalEventRepository clears history for a specific senior only',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('senior-companion-events-clear');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async => Hive.init(tempDir.path),
    );
    await initializer.initialize();

    final repository = LocalEventRepository(
      hiveInitializer: initializer,
      eventMapper: const AppEventMapper(),
      profileRepository: _FakeProfileRepository(
        seniors: const <SeniorProfile>[],
        guardians: const <GuardianProfile>[],
      ),
    );

    await repository.addAppEvent(
      CheckInCompletedEvent(
        seniorId: 'senior-a',
        happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
      ),
    );
    await repository.addAppEvent(
      CheckInCompletedEvent(
        seniorId: 'senior-b',
        happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
      ),
    );

    await repository.clearEventHistory(seniorId: 'senior-a');
    final all = await repository.fetchAll();
    expect(all, hasLength(1));
    expect(all.single.seniorId, 'senior-b');

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
