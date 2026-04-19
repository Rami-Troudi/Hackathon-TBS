import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_guardian_alert_repository.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class _InMemoryStorageService implements StorageService {
  final Map<String, Object> _store = <String, Object>{};

  @override
  Future<void> initialize() async {}

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  int? getInt(String key) => _store[key] as int?;

  @override
  double? getDouble(String key) => _store[key] as double?;

  @override
  List<String>? getStringList(String key) => _store[key] as List<String>?;

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }
}

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
  test('adds resolved info alert when senior completed check-in today',
      () async {
    final repository = LocalGuardianAlertRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-checkin-completed',
          type: AppEventType.checkInCompleted,
          happenedAt: DateTime.parse('2026-04-18T08:30:00Z'),
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
      storage: _InMemoryStorageService(),
    );

    final alerts = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T10:00:00Z'),
    );

    final checkInAlert = alerts.firstWhere(
      (alert) => alert.id.startsWith('completed-check-in-'),
    );
    expect(checkInAlert.severity, GuardianAlertSeverity.info);
    expect(checkInAlert.state, GuardianAlertState.resolved);
    expect(checkInAlert.destination, GuardianMonitoringDestination.checkIns);
  });

  test('adds resolved info alerts for positive daily routine updates',
      () async {
    final repository = LocalGuardianAlertRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-medication-taken',
          type: AppEventType.medicationTaken,
          happenedAt: DateTime.parse('2026-04-18T08:30:00Z'),
          payload: const <String, dynamic>{'medicationName': 'Aspirin'},
        ),
        _record(
          id: 'evt-hydration-completed',
          type: AppEventType.hydrationCompleted,
          happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
          payload: const <String, dynamic>{'slotLabel': 'Morning hydration'},
        ),
        _record(
          id: 'evt-meal-completed',
          type: AppEventType.mealCompleted,
          happenedAt: DateTime.parse('2026-04-18T12:00:00Z'),
          payload: const <String, dynamic>{'mealLabel': 'Lunch'},
        ),
        _record(
          id: 'evt-safe-zone-entered',
          type: AppEventType.safeZoneEntered,
          happenedAt: DateTime.parse('2026-04-18T13:00:00Z'),
          payload: const <String, dynamic>{
            'zoneId': 'zone-home',
            'zoneName': 'Home',
          },
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
      storage: _InMemoryStorageService(),
    );

    final alerts = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T14:00:00Z'),
    );

    final medicationAlert = alerts.firstWhere(
      (alert) => alert.id.startsWith('completed-medication-'),
    );
    final hydrationAlert = alerts.firstWhere(
      (alert) => alert.id.startsWith('completed-hydration-'),
    );
    final mealAlert = alerts.firstWhere(
      (alert) => alert.id.startsWith('completed-meal-'),
    );
    final safeZoneAlert = alerts.firstWhere(
      (alert) => alert.id.startsWith('safe-zone-returned-'),
    );

    expect(medicationAlert.severity, GuardianAlertSeverity.info);
    expect(medicationAlert.state, GuardianAlertState.resolved);
    expect(medicationAlert.destination, GuardianMonitoringDestination.medication);

    expect(hydrationAlert.severity, GuardianAlertSeverity.info);
    expect(hydrationAlert.state, GuardianAlertState.resolved);
    expect(hydrationAlert.destination, GuardianMonitoringDestination.hydration);

    expect(mealAlert.severity, GuardianAlertSeverity.info);
    expect(mealAlert.state, GuardianAlertState.resolved);
    expect(mealAlert.destination, GuardianMonitoringDestination.nutrition);

    expect(safeZoneAlert.severity, GuardianAlertSeverity.info);
    expect(safeZoneAlert.state, GuardianAlertState.resolved);
    expect(safeZoneAlert.destination, GuardianMonitoringDestination.location);
  });

  test('derives critical alerts for open confirmed incidents and emergencies',
      () async {
    final repository = LocalGuardianAlertRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-suspected',
          type: AppEventType.incidentSuspected,
          happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
        ),
        _record(
          id: 'evt-confirmed',
          type: AppEventType.incidentConfirmed,
          happenedAt: DateTime.parse('2026-04-18T08:05:00Z'),
        ),
        _record(
          id: 'evt-emergency',
          type: AppEventType.emergencyTriggered,
          happenedAt: DateTime.parse('2026-04-18T08:07:00Z'),
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
      storage: _InMemoryStorageService(),
    );

    final alerts = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T10:00:00Z'),
    );

    final criticalActive = alerts
        .where((alert) => alert.severity == GuardianAlertSeverity.critical)
        .where((alert) => alert.state == GuardianAlertState.active)
        .toList();

    expect(
      criticalActive.any((alert) => alert.id.contains('incident-confirmed')),
      isTrue,
    );
    expect(
      criticalActive.any((alert) => alert.id.contains('emergency')),
      isTrue,
    );
  });

  test('escalates repeated missed routine signals to critical severity',
      () async {
    final repository = LocalGuardianAlertRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-checkin-missed',
          type: AppEventType.checkInMissed,
          happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          payload: const <String, dynamic>{'windowLabel': 'Morning'},
        ),
        _record(
          id: 'evt-med-missed-1',
          type: AppEventType.medicationMissed,
          happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
          payload: const <String, dynamic>{'medicationName': 'Aspirin'},
        ),
        _record(
          id: 'evt-med-missed-2',
          type: AppEventType.medicationMissed,
          happenedAt: DateTime.parse('2026-04-18T10:00:00Z'),
          payload: const <String, dynamic>{'medicationName': 'Aspirin'},
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
      storage: _InMemoryStorageService(),
    );

    final alerts = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T11:00:00Z'),
    );

    final repeated = alerts.firstWhere(
      (alert) => alert.id.startsWith('repeated-missed-routines'),
    );
    expect(repeated.severity, GuardianAlertSeverity.critical);
  });

  test('stores acknowledgement state for derived alerts', () async {
    final repository = LocalGuardianAlertRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-checkin-missed',
          type: AppEventType.checkInMissed,
          happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          payload: const <String, dynamic>{'windowLabel': 'Morning'},
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
      storage: _InMemoryStorageService(),
    );

    final first = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T09:00:00Z'),
    );
    final alert = first.firstWhere(
      (item) => item.id.startsWith('missed-check-in'),
    );

    await repository.acknowledgeAlert(alert.id);

    final second = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T09:00:00Z'),
    );
    final acknowledged = second.firstWhere((item) => item.id == alert.id);
    expect(acknowledged.state, GuardianAlertState.acknowledged);
  });

  test('applies guardian alert sensitivity to routine escalation', () async {
    final repository = LocalGuardianAlertRepository(
      eventRepository: _FakeEventRepository(<PersistedEventRecord>[
        _record(
          id: 'evt-checkin-missed',
          type: AppEventType.checkInMissed,
          happenedAt: DateTime.parse('2026-04-18T08:00:00Z'),
          payload: const <String, dynamic>{'windowLabel': 'Morning'},
        ),
        _record(
          id: 'evt-medication-missed',
          type: AppEventType.medicationMissed,
          happenedAt: DateTime.parse('2026-04-18T09:00:00Z'),
          payload: const <String, dynamic>{'medicationName': 'Aspirin'},
        ),
      ]),
      statusEngine: const SeniorStatusEngine(),
      storage: _InMemoryStorageService(),
    );

    final lowSensitivity = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T11:00:00Z'),
      alertSensitivity: AlertSensitivity.low,
    );
    expect(
      lowSensitivity.any(
        (alert) => alert.id.startsWith('repeated-missed-routines'),
      ),
      isFalse,
    );

    final highSensitivity = await repository.fetchAlertsForSenior(
      'senior-a',
      now: DateTime.parse('2026-04-18T11:00:00Z'),
      alertSensitivity: AlertSensitivity.high,
    );
    final repeated = highSensitivity.firstWhere(
      (alert) => alert.id.startsWith('repeated-missed-routines'),
    );
    expect(repeated.severity, GuardianAlertSeverity.critical);
  });
}
