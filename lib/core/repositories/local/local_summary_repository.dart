import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/summary_repository.dart';
import 'package:senior_companion/shared/models/daily_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class LocalSummaryRepository implements SummaryRepository {
  const LocalSummaryRepository({
    required this.eventRepository,
    required this.statusEngine,
  });

  final EventRepository eventRepository;
  final SeniorStatusEngine statusEngine;

  @override
  Future<DailySummary> buildSeniorDailySummary(
    String seniorId, {
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final timeline = await eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.oldestFirst,
      limit: 300,
    );
    final todayEvents = _todayEvents(timeline, reference);
    final evaluation = statusEngine.evaluate(timeline, now: reference);
    final counters = _EventCounters.from(todayEvents);

    final headline = switch (evaluation.status) {
      SeniorGlobalStatus.ok => 'You are on track today.',
      SeniorGlobalStatus.watch => 'A few daily routines still need attention.',
      SeniorGlobalStatus.actionRequired =>
        'Please reach out to your guardian for support.',
    };

    final positives = <String>[
      if (counters.checkInsCompleted > 0)
        'Check-in completed ${counters.checkInsCompleted} time(s).',
      if (counters.medicationTaken > 0)
        'Medication confirmed ${counters.medicationTaken} time(s).',
      if (counters.hydrationCompleted > 0)
        'Hydration completed ${counters.hydrationCompleted} time(s).',
      if (counters.mealsCompleted > 0)
        'Meals completed ${counters.mealsCompleted} time(s).',
      if (counters.safeZoneEntered > 0) 'Returned to a safe zone today.',
    ];
    final concerns = <String>[
      if (counters.checkInsMissed > 0) 'A check-in was missed.',
      if (counters.medicationMissed > 0) 'Medication was missed.',
      if (counters.hydrationMissed > 0) 'Hydration reminder was missed.',
      if (counters.mealsMissed > 0) 'A meal was missed.',
      if (counters.safeZoneExited > counters.safeZoneEntered)
        'Currently outside defined safe zones.',
      if (counters.emergencyTriggered > 0) 'Emergency flow was triggered.',
    ];

    return DailySummary(
      audience: DailySummaryAudience.senior,
      headline: headline,
      whatWentWell: positives.isEmpty
          ? const <String>['No completed routine recorded yet today.']
          : positives,
      needsAttention: concerns.isEmpty
          ? const <String>['No urgent concerns identified right now.']
          : concerns,
      notableEvents: _notableEventLines(todayEvents, limit: 6),
      generatedAt: reference.toUtc(),
    );
  }

  @override
  Future<DailySummary> buildGuardianDailySummary(
    String seniorId, {
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final timeline = await eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.oldestFirst,
      limit: 300,
    );
    final todayEvents = _todayEvents(timeline, reference);
    final evaluation = statusEngine.evaluate(timeline, now: reference);
    final counters = _EventCounters.from(todayEvents);

    final headline = switch (evaluation.status) {
      SeniorGlobalStatus.ok => 'Stable day with no major warning signs.',
      SeniorGlobalStatus.watch =>
        'Watch state: follow-up is recommended today.',
      SeniorGlobalStatus.actionRequired =>
        'Action required: unresolved high-priority signals detected.',
    };

    final positives = <String>[
      'Check-ins completed: ${counters.checkInsCompleted}',
      'Medication taken: ${counters.medicationTaken}',
      'Hydration completed: ${counters.hydrationCompleted}',
      'Meals completed: ${counters.mealsCompleted}',
    ];

    final concerns = <String>[
      if (counters.checkInsMissed > 0)
        'Missed check-ins: ${counters.checkInsMissed}',
      if (counters.medicationMissed > 0)
        'Missed medication confirmations: ${counters.medicationMissed}',
      if (counters.hydrationMissed > 0)
        'Missed hydration slots: ${counters.hydrationMissed}',
      if (counters.mealsMissed > 0) 'Missed meals: ${counters.mealsMissed}',
      if (counters.safeZoneExited > counters.safeZoneEntered)
        'Senior is currently outside safe zones.',
      if (counters.emergencyTriggered > 0)
        'Emergency escalations today: ${counters.emergencyTriggered}',
    ];

    return DailySummary(
      audience: DailySummaryAudience.guardian,
      headline: headline,
      whatWentWell: positives,
      needsAttention: concerns.isEmpty
          ? const <String>[
              'No additional concerns beyond current status rules.'
            ]
          : concerns,
      notableEvents: _notableEventLines(todayEvents, limit: 10),
      generatedAt: reference.toUtc(),
    );
  }

  List<PersistedEventRecord> _todayEvents(
    List<PersistedEventRecord> timeline,
    DateTime reference,
  ) {
    return timeline.where((event) {
      final local = event.happenedAt.toLocal();
      return local.year == reference.year &&
          local.month == reference.month &&
          local.day == reference.day;
    }).toList(growable: false);
  }

  List<String> _notableEventLines(
    List<PersistedEventRecord> events, {
    required int limit,
  }) {
    final newestFirst = events.toList(growable: false)
      ..sort((left, right) => right.happenedAt.compareTo(left.happenedAt));
    return newestFirst.take(limit).map((event) {
      final local = event.happenedAt.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$hh:$mm • ${event.type.timelineLabel}';
    }).toList(growable: false);
  }
}

class _EventCounters {
  const _EventCounters({
    required this.checkInsCompleted,
    required this.checkInsMissed,
    required this.medicationTaken,
    required this.medicationMissed,
    required this.hydrationCompleted,
    required this.hydrationMissed,
    required this.mealsCompleted,
    required this.mealsMissed,
    required this.safeZoneEntered,
    required this.safeZoneExited,
    required this.emergencyTriggered,
  });

  final int checkInsCompleted;
  final int checkInsMissed;
  final int medicationTaken;
  final int medicationMissed;
  final int hydrationCompleted;
  final int hydrationMissed;
  final int mealsCompleted;
  final int mealsMissed;
  final int safeZoneEntered;
  final int safeZoneExited;
  final int emergencyTriggered;

  factory _EventCounters.from(List<PersistedEventRecord> events) {
    var checkInsCompleted = 0;
    var checkInsMissed = 0;
    var medicationTaken = 0;
    var medicationMissed = 0;
    var hydrationCompleted = 0;
    var hydrationMissed = 0;
    var mealsCompleted = 0;
    var mealsMissed = 0;
    var safeZoneEntered = 0;
    var safeZoneExited = 0;
    var emergencyTriggered = 0;

    for (final event in events) {
      switch (event.type) {
        case AppEventType.checkInCompleted:
          checkInsCompleted += 1;
        case AppEventType.checkInMissed:
          checkInsMissed += 1;
        case AppEventType.medicationTaken:
          medicationTaken += 1;
        case AppEventType.medicationMissed:
          medicationMissed += 1;
        case AppEventType.hydrationCompleted:
          hydrationCompleted += 1;
        case AppEventType.hydrationMissed:
          hydrationMissed += 1;
        case AppEventType.mealCompleted:
          mealsCompleted += 1;
        case AppEventType.mealMissed:
          mealsMissed += 1;
        case AppEventType.safeZoneEntered:
          safeZoneEntered += 1;
        case AppEventType.safeZoneExited:
          safeZoneExited += 1;
        case AppEventType.emergencyTriggered:
          emergencyTriggered += 1;
        case AppEventType.incidentSuspected:
        case AppEventType.incidentConfirmed:
        case AppEventType.incidentDismissed:
        case AppEventType.seniorStatusChanged:
        case AppEventType.guardianAlertGenerated:
          break;
      }
    }

    return _EventCounters(
      checkInsCompleted: checkInsCompleted,
      checkInsMissed: checkInsMissed,
      medicationTaken: medicationTaken,
      medicationMissed: medicationMissed,
      hydrationCompleted: hydrationCompleted,
      hydrationMissed: hydrationMissed,
      mealsCompleted: mealsCompleted,
      mealsMissed: mealsMissed,
      safeZoneEntered: safeZoneEntered,
      safeZoneExited: safeZoneExited,
      emergencyTriggered: emergencyTriggered,
    );
  }
}
