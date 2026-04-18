import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_dashboard_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
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
    if (session == null) return;
    session = AppSession(
      activeRole: activeRole,
      activeProfileId: activeProfileId,
      startedAt: session!.startedAt,
    );
  }
}

class _FakeProfileRepository implements ProfileRepository {
  const _FakeProfileRepository();

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

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository(this.records);

  final List<PersistedEventRecord> records;

  @override
  Future<void> addEventRecord(PersistedEventRecord record) async {
    records.add(record);
  }

  @override
  Future<PersistedEventRecord> addAppEvent(
    AppEvent event, {
    String source = 'runtime',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addEventRecords(Iterable<PersistedEventRecord> records) async {
    this.records.addAll(records);
  }

  @override
  Future<void> clearEventHistory({String? seniorId}) async {
    if (seniorId == null) {
      records.clear();
      return;
    }
    records.removeWhere((record) => record.seniorId == seniorId);
  }

  @override
  Future<List<PersistedEventRecord>> fetchAll({
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) async =>
      records;

  @override
  Future<List<PersistedEventRecord>> fetchEventsByTypeForSenior(
    String seniorId,
    AppEventType type, {
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) async =>
      records
          .where((record) => record.seniorId == seniorId && record.type == type)
          .toList();

  @override
  Future<List<PersistedEventRecord>> fetchEventsForGuardian(
    String guardianId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) async =>
      const <PersistedEventRecord>[];

  @override
  Future<List<PersistedEventRecord>> fetchRecentEventsForSenior(
    String seniorId, {
    int limit = 20,
  }) async =>
      records.where((record) => record.seniorId == seniorId).toList();

  @override
  Future<List<PersistedEventRecord>> fetchTimelineForSenior(
    String seniorId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) async {
    final filtered = records.where((record) => record.seniorId == seniorId);
    return filtered.toList();
  }
}

PersistedEventRecord _record({
  required String id,
  required AppEventType type,
  required DateTime happenedAt,
}) {
  return PersistedEventRecord(
    id: id,
    seniorId: 'senior-a',
    type: type,
    happenedAt: happenedAt,
    createdAt: happenedAt,
    source: 'test',
    severity: EventSeverity.info,
    payload: const <String, dynamic>{},
  );
}

void main() {
  test('returns empty summary when no active senior context exists', () async {
    final repository = LocalDashboardRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[]),
      statusEngine: const SeniorStatusEngine(),
      activeSeniorResolver: ActiveSeniorResolver(
        appSessionRepository: _FakeSessionRepository(null),
        profileRepository: const _FakeProfileRepository(),
      ),
      logger: _NoopLogger(),
    );

    final summary = await repository.fetchDashboardSummary();
    expect(summary.globalStatus, SeniorGlobalStatus.ok);
    expect(summary.pendingAlerts, 0);
    expect(summary.todayCheckIns, 0);
  });

  test('derives dashboard summary from persisted events', () async {
    final now = DateTime.now().toUtc();
    final repository = LocalDashboardRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-1',
          type: AppEventType.checkInCompleted,
          happenedAt: now,
        ),
        _record(
          id: 'evt-2',
          type: AppEventType.medicationMissed,
          happenedAt: now,
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
      activeSeniorResolver: ActiveSeniorResolver(
        appSessionRepository: _FakeSessionRepository(
          AppSession(
            activeRole: AppRole.senior,
            activeProfileId: 'senior-a',
            startedAt: DateTime.parse('2026-04-18T10:00:00Z'),
          ),
        ),
        profileRepository: const _FakeProfileRepository(),
      ),
      logger: _NoopLogger(),
    );

    final summary = await repository.fetchDashboardSummary();
    expect(summary.globalStatus, SeniorGlobalStatus.watch);
    expect(summary.todayCheckIns, 1);
    expect(summary.missedMedications, 1);
    expect(summary.pendingAlerts, 1);
    expect(summary.lastCheckInAt, isNotNull);
  });
}
