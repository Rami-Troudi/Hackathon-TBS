import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/check_in_repository.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';

const _kCheckInWindowLabel = 'Daily morning check-in';

class LocalCheckInRepository implements CheckInRepository {
  const LocalCheckInRepository({
    required this.eventRepository,
    required this.eventRecorder,
  });

  final EventRepository eventRepository;
  final AppEventRecorder eventRecorder;

  @override
  Future<CheckInState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedWindow = true,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final window = _windowFor(reference);

    if (reconcileMissedWindow) {
      await _reconcileMissedWindowIfNeeded(
        seniorId,
        reference: reference,
        window: window,
      );
    }

    final todayEvents =
        await _todayCheckInEvents(seniorId, reference: reference);
    final completedEvent = _latestEventOfType(
      todayEvents,
      AppEventType.checkInCompleted,
    );
    if (completedEvent != null) {
      return CheckInState(
        status: CheckInStatus.completed,
        windowLabel: _kCheckInWindowLabel,
        windowStart: window.start,
        windowEnd: window.end,
        completedAt: completedEvent.happenedAt.toLocal(),
      );
    }

    final missedEvent = _latestEventOfType(
      todayEvents,
      AppEventType.checkInMissed,
    );
    if (missedEvent != null || reference.isAfter(window.end)) {
      return CheckInState(
        status: CheckInStatus.missed,
        windowLabel: _kCheckInWindowLabel,
        windowStart: window.start,
        windowEnd: window.end,
        missedAt: (missedEvent?.happenedAt ?? window.end.toUtc()).toLocal(),
      );
    }

    return CheckInState(
      status: CheckInStatus.pending,
      windowLabel: _kCheckInWindowLabel,
      windowStart: window.start,
      windowEnd: window.end,
    );
  }

  @override
  Future<bool> markCheckInCompleted(
    String seniorId, {
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final todayEvents =
        await _todayCheckInEvents(seniorId, reference: reference);
    final alreadyCompleted = todayEvents.any(
      (event) => event.type == AppEventType.checkInCompleted,
    );
    if (alreadyCompleted) return false;

    await eventRecorder.publishAndPersist(
      CheckInCompletedEvent(
        seniorId: seniorId,
        happenedAt: reference.toUtc(),
      ),
      source: 'senior.check_in',
    );
    return true;
  }

  @override
  Future<void> markNeedHelp(
    String seniorId, {
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    await markCheckInCompleted(seniorId, now: reference);

    final todayEvents = await _todayCheckInEvents(
      seniorId,
      reference: reference,
      includeIncidentEvents: true,
    );
    final hasConfirmed = todayEvents.any(
      (event) => event.type == AppEventType.incidentConfirmed,
    );
    final hasEmergency = todayEvents.any(
      (event) => event.type == AppEventType.emergencyTriggered,
    );

    if (!hasConfirmed) {
      await eventRecorder.publishAndPersist(
        IncidentConfirmedEvent(
          seniorId: seniorId,
          happenedAt: reference.toUtc(),
        ),
        source: 'senior.check_in',
      );
    }

    if (!hasEmergency) {
      await eventRecorder.publishAndPersist(
        EmergencyTriggeredEvent(
          seniorId: seniorId,
          happenedAt: reference.toUtc(),
        ),
        source: 'senior.check_in',
      );
    }
  }

  @override
  Future<List<PersistedEventRecord>> fetchRecentCheckIns(
    String seniorId, {
    int limit = 10,
  }) {
    return eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      types: const <AppEventType>{
        AppEventType.checkInCompleted,
        AppEventType.checkInMissed,
      },
      limit: limit,
    );
  }

  Future<void> _reconcileMissedWindowIfNeeded(
    String seniorId, {
    required DateTime reference,
    required _CheckInWindow window,
  }) async {
    if (reference.isBefore(window.end)) return;

    final todayEvents =
        await _todayCheckInEvents(seniorId, reference: reference);
    final hasCompleted = todayEvents.any(
      (event) => event.type == AppEventType.checkInCompleted,
    );
    final hasMissed = todayEvents.any(
      (event) => event.type == AppEventType.checkInMissed,
    );
    if (hasCompleted || hasMissed) return;

    await eventRecorder.publishAndPersist(
      CheckInMissedEvent(
        seniorId: seniorId,
        happenedAt: window.end.toUtc(),
        windowLabel: _kCheckInWindowLabel,
      ),
      source: 'senior.check_in.reconcile',
    );
  }

  Future<List<PersistedEventRecord>> _todayCheckInEvents(
    String seniorId, {
    required DateTime reference,
    bool includeIncidentEvents = false,
  }) async {
    final types = <AppEventType>{
      AppEventType.checkInCompleted,
      AppEventType.checkInMissed,
    };
    if (includeIncidentEvents) {
      types.addAll(const <AppEventType>{
        AppEventType.incidentConfirmed,
        AppEventType.emergencyTriggered,
      });
    }

    final events = await eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      types: types,
      limit: 40,
    );
    return events
        .where((event) => _isSameLocalDay(event.happenedAt, reference))
        .toList(growable: false);
  }

  PersistedEventRecord? _latestEventOfType(
    Iterable<PersistedEventRecord> events,
    AppEventType type,
  ) {
    for (final event in events) {
      if (event.type == type) return event;
    }
    return null;
  }

  bool _isSameLocalDay(DateTime timestamp, DateTime reference) {
    final local = timestamp.toLocal();
    return local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
  }

  _CheckInWindow _windowFor(DateTime reference) {
    return _CheckInWindow(
      start: DateTime(
        reference.year,
        reference.month,
        reference.day,
        8,
      ),
      end: DateTime(
        reference.year,
        reference.month,
        reference.day,
        12,
      ),
    );
  }
}

class _CheckInWindow {
  const _CheckInWindow({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
