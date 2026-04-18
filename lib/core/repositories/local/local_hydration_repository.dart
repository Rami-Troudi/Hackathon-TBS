import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/hydration_repository.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';

const _kHydrationGrace = Duration(hours: 1);

class LocalHydrationRepository implements HydrationRepository {
  const LocalHydrationRepository({
    required this.eventRepository,
    required this.eventRecorder,
  });

  final EventRepository eventRepository;
  final AppEventRecorder eventRecorder;

  @override
  Future<HydrationState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedSlots = true,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final slots = _slotsFor(reference);
    final todayEvents = await _todayHydrationEvents(
      seniorId,
      reference: reference,
    );

    if (reconcileMissedSlots) {
      await _reconcileMissedSlotsIfNeeded(
        seniorId,
        reference: reference,
        slots: slots,
        todayEvents: todayEvents,
      );
    }

    final refreshedEvents = await _todayHydrationEvents(
      seniorId,
      reference: reference,
    );
    final latestBySlot = <String, PersistedEventRecord>{};
    for (final event in refreshedEvents) {
      final slotLabel = event.payload['slotLabel'] as String?;
      if (slotLabel == null) continue;
      latestBySlot[slotLabel] ??= event;
    }

    final states = slots.map((slot) {
      final latest = latestBySlot[slot.label];
      final status = switch (latest?.type) {
        AppEventType.hydrationCompleted => HydrationSlotStatus.completed,
        AppEventType.hydrationMissed => HydrationSlotStatus.missed,
        _ => HydrationSlotStatus.pending,
      };
      return HydrationSlotState(
        id: slot.id,
        label: slot.label,
        scheduledAt: slot.scheduledAt,
        status: status,
        resolvedAt: latest?.happenedAt.toLocal(),
      );
    }).toList(growable: false);

    return HydrationState(
      slots: states,
      dailyGoalCompletions: slots.length,
    );
  }

  @override
  Future<bool> markHydrationCompleted(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final slot = _findSlot(slotId, reference);
    if (slot == null) {
      throw StateError('Unknown hydration slot: $slotId');
    }

    final completed = await _hasHydrationEventToday(
      seniorId,
      slotLabel: slot.label,
      types: const <AppEventType>{AppEventType.hydrationCompleted},
      reference: reference,
    );
    if (completed) return false;

    await eventRecorder.publishAndPersist(
      HydrationCompletedEvent(
        seniorId: seniorId,
        happenedAt: reference.toUtc(),
        slotLabel: slot.label,
      ),
      source: 'senior.hydration',
    );
    return true;
  }

  @override
  Future<bool> markHydrationMissed(
    String seniorId, {
    required String slotId,
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final slot = _findSlot(slotId, reference);
    if (slot == null) {
      throw StateError('Unknown hydration slot: $slotId');
    }

    final existing = await _hasHydrationEventToday(
      seniorId,
      slotLabel: slot.label,
      types: const <AppEventType>{
        AppEventType.hydrationCompleted,
        AppEventType.hydrationMissed,
      },
      reference: reference,
    );
    if (existing) return false;

    await eventRecorder.publishAndPersist(
      HydrationMissedEvent(
        seniorId: seniorId,
        happenedAt: reference.toUtc(),
        slotLabel: slot.label,
      ),
      source: 'senior.hydration',
    );
    return true;
  }

  @override
  Future<List<PersistedEventRecord>> fetchRecentHydrationEvents(
    String seniorId, {
    int limit = 20,
  }) {
    return eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      types: const <AppEventType>{
        AppEventType.hydrationCompleted,
        AppEventType.hydrationMissed,
      },
      limit: limit,
    );
  }

  Future<void> _reconcileMissedSlotsIfNeeded(
    String seniorId, {
    required DateTime reference,
    required List<_HydrationSlotDef> slots,
    required List<PersistedEventRecord> todayEvents,
  }) async {
    final existing = <String>{
      for (final event in todayEvents)
        if (event.payload['slotLabel'] is String)
          event.payload['slotLabel'] as String,
    };
    for (final slot in slots) {
      if (existing.contains(slot.label)) continue;
      if (reference.isBefore(slot.scheduledAt.add(_kHydrationGrace))) continue;
      await eventRecorder.publishAndPersist(
        HydrationMissedEvent(
          seniorId: seniorId,
          happenedAt: slot.scheduledAt.add(_kHydrationGrace).toUtc(),
          slotLabel: slot.label,
        ),
        source: 'senior.hydration.reconcile',
      );
    }
  }

  Future<List<PersistedEventRecord>> _todayHydrationEvents(
    String seniorId, {
    required DateTime reference,
  }) async {
    final events = await fetchRecentHydrationEvents(
      seniorId,
      limit: 80,
    );
    return events
        .where((event) => _isSameLocalDay(event.happenedAt, reference))
        .toList(growable: false);
  }

  Future<bool> _hasHydrationEventToday(
    String seniorId, {
    required String slotLabel,
    required Set<AppEventType> types,
    required DateTime reference,
  }) async {
    final events = await _todayHydrationEvents(
      seniorId,
      reference: reference,
    );
    return events.any(
      (event) => event.payload['slotLabel'] == slotLabel && types.contains(event.type),
    );
  }

  _HydrationSlotDef? _findSlot(String slotId, DateTime reference) {
    for (final slot in _slotsFor(reference)) {
      if (slot.id == slotId) return slot;
    }
    return null;
  }

  List<_HydrationSlotDef> _slotsFor(DateTime reference) {
    return <_HydrationSlotDef>[
      _HydrationSlotDef(
        id: 'hydration-morning',
        label: 'Morning hydration',
        scheduledAt:
            DateTime(reference.year, reference.month, reference.day, 9, 0),
      ),
      _HydrationSlotDef(
        id: 'hydration-afternoon',
        label: 'Afternoon hydration',
        scheduledAt:
            DateTime(reference.year, reference.month, reference.day, 14, 0),
      ),
      _HydrationSlotDef(
        id: 'hydration-evening',
        label: 'Evening hydration',
        scheduledAt:
            DateTime(reference.year, reference.month, reference.day, 19, 0),
      ),
    ];
  }

  bool _isSameLocalDay(DateTime timestamp, DateTime reference) {
    final local = timestamp.toLocal();
    return local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
  }
}

class _HydrationSlotDef {
  const _HydrationSlotDef({
    required this.id,
    required this.label,
    required this.scheduledAt,
  });

  final String id;
  final String label;
  final DateTime scheduledAt;
}
