import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_summary_repository.dart';

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository(this.records);

  final List<PersistedEventRecord> records;

  @override
  Future<List<PersistedEventRecord>> fetchTimelineForSenior(
    String seniorId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) async {
    final filtered = records.where((event) => event.seniorId == seniorId).where(
          (event) => types == null || types.contains(event.type),
        );
    final sorted = filtered.toList()
      ..sort((a, b) => a.happenedAt.compareTo(b.happenedAt));
    final ordered = order == TimelineOrder.newestFirst
        ? sorted.reversed.toList(growable: false)
        : sorted;
    if (limit != null && ordered.length > limit) {
      return ordered.take(limit).toList(growable: false);
    }
    return ordered;
  }

  @override
  Future<void> addEventRecord(PersistedEventRecord record) async {}

  @override
  Future<PersistedEventRecord> addAppEvent(
    AppEvent event, {
    String source = 'runtime',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addEventRecords(Iterable<PersistedEventRecord> records) async {}

  @override
  Future<void> clearEventHistory({String? seniorId}) async {}

  @override
  Future<List<PersistedEventRecord>> fetchAll({
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersistedEventRecord>> fetchEventsByTypeForSenior(
    String seniorId,
    AppEventType type, {
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersistedEventRecord>> fetchEventsForGuardian(
    String guardianId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersistedEventRecord>> fetchRecentEventsForSenior(
    String seniorId, {
    int limit = 20,
  }) {
    throw UnimplementedError();
  }
}

PersistedEventRecord _record({
  required String id,
  required AppEventType type,
  required DateTime happenedAt,
  Map<String, dynamic> payload = const <String, dynamic>{},
}) {
  return PersistedEventRecord(
    id: id,
    seniorId: 'senior-a',
    type: type,
    happenedAt: happenedAt,
    createdAt: happenedAt,
    source: 'test',
    severity: EventSeverity.warning,
    payload: payload,
  );
}

void main() {
  test('guardian summary highlights hydration, meal, and safe-zone concerns',
      () async {
    final repository = LocalSummaryRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-checkin',
          type: AppEventType.checkInCompleted,
          happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
        ),
        _record(
          id: 'evt-hydration-missed',
          type: AppEventType.hydrationMissed,
          happenedAt: DateTime.parse('2026-04-18T12:00:00Z'),
          payload: const <String, dynamic>{'slotLabel': 'Afternoon hydration'},
        ),
        _record(
          id: 'evt-meal-missed',
          type: AppEventType.mealMissed,
          happenedAt: DateTime.parse('2026-04-18T14:00:00Z'),
          payload: const <String, dynamic>{'mealLabel': 'Lunch'},
        ),
        _record(
          id: 'evt-zone-exit',
          type: AppEventType.safeZoneExited,
          happenedAt: DateTime.parse('2026-04-18T15:00:00Z'),
          payload: const <String, dynamic>{'zoneName': 'Home'},
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
    );

    final summary = await repository.buildGuardianDailySummary(
      'senior-a',
      now: DateTime.parse('2026-04-18T18:00:00Z'),
    );

    expect(summary.headline, isNotEmpty);
    expect(
      summary.needsAttention.any((line) => line.contains('hydration')),
      isTrue,
    );
    expect(
      summary.needsAttention.any((line) => line.contains('meals')),
      isTrue,
    );
    expect(
      summary.needsAttention.any((line) => line.contains('outside safe zones')),
      isTrue,
    );
  });
}
