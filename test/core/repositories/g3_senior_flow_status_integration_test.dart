import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/repositories/local/local_check_in_repository.dart';
import 'package:senior_companion/core/repositories/local/local_dashboard_repository.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_medication_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class _NoopLogger implements AppLogger {
  @override
  void debug(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message) {}

  @override
  void warn(String message) {}
}

class _FakeSessionRepository implements AppSessionRepository {
  _FakeSessionRepository(this.session);

  AppSession? session;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<void> createSession({
    required AppRole activeRole,
    required String activeProfileId,
  }) async {
    session = AppSession(
      activeRole: activeRole,
      activeProfileId: activeProfileId,
      startedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<AppSession?> getSession() async => session;

  @override
  Future<void> saveSession(AppSession session) async {
    this.session = session;
  }

  @override
  Future<void> switchSessionRole({
    required AppRole activeRole,
    required String activeProfileId,
  }) async {
    final existing = session;
    if (existing == null) return;
    session = AppSession(
      activeRole: activeRole,
      activeProfileId: activeProfileId,
      startedAt: existing.startedAt,
    );
  }
}

class _FakeProfileRepository implements ProfileRepository {
  static const _senior = SeniorProfile(
    id: 'senior-a',
    displayName: 'Senior A',
    age: 72,
    preferredLanguage: 'fr',
    largeTextEnabled: true,
    highContrastEnabled: false,
    linkedGuardianIds: <String>['guardian-a'],
  );

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
      const <SeniorProfile>[_senior];

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async =>
      const <SeniorProfile>[_senior];

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async {
    if (id == _senior.id) return _senior;
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
  test('dashboard summary changes after real senior flow actions', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-g3-dashboard-integration');
    final initializer = HiveInitializer(
      hive: Hive,
      initFunction: () async => Hive.init(tempDir.path),
    );
    await initializer.initialize();

    final profileRepository = _FakeProfileRepository();
    final eventRepository = LocalEventRepository(
      hiveInitializer: initializer,
      eventMapper: const AppEventMapper(),
      profileRepository: profileRepository,
    );
    final recorder = AppEventRecorder(
      eventBus: AppEventBus(),
      eventRepository: eventRepository,
    );

    final checkInRepository = LocalCheckInRepository(
      eventRepository: eventRepository,
      eventRecorder: recorder,
    );
    final medicationRepository = LocalMedicationRepository(
      hiveInitializer: initializer,
      profileRepository: profileRepository,
      eventRepository: eventRepository,
      eventRecorder: recorder,
    );
    final dashboardRepository = LocalDashboardRepository(
      eventRepository: eventRepository,
      statusEngine: const SeniorStatusEngine(),
      activeSeniorResolver: ActiveSeniorResolver(
        appSessionRepository: _FakeSessionRepository(
          AppSession(
            activeRole: AppRole.senior,
            activeProfileId: 'senior-a',
            startedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          ),
        ),
        profileRepository: profileRepository,
      ),
      logger: _NoopLogger(),
    );

    final initialSummary = await dashboardRepository.fetchDashboardSummary();

    await checkInRepository.markCheckInCompleted(
      'senior-a',
      now: DateTime(2026, 4, 18, 9, 0),
    );
    final plans = await medicationRepository.getPlansForSenior('senior-a');
    await medicationRepository.markMedicationMissed(
      'senior-a',
      planId: plans.first.id,
      now: DateTime(2026, 4, 18, 9, 30),
    );

    final summaryAfterActions =
        await dashboardRepository.fetchDashboardSummary();

    expect(initialSummary.globalStatus, SeniorGlobalStatus.ok);
    expect(summaryAfterActions.globalStatus, SeniorGlobalStatus.watch);
    expect(summaryAfterActions.todayCheckIns, 1);
    expect(summaryAfterActions.missedMedications, 1);
    expect(summaryAfterActions.pendingAlerts, greaterThan(0));

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
