import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/nutrition_repository.dart';
import 'package:senior_companion/shared/models/meal_state.dart';

const _kMealGrace = Duration(hours: 2);

class LocalNutritionRepository implements NutritionRepository {
  const LocalNutritionRepository({
    required this.eventRepository,
    required this.eventRecorder,
  });

  final EventRepository eventRepository;
  final AppEventRecorder eventRecorder;

  @override
  Future<NutritionState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedMeals = true,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final meals = _mealsFor(reference);
    final todayEvents = await _todayMealEvents(
      seniorId,
      reference: reference,
    );

    if (reconcileMissedMeals) {
      await _reconcileMissedMealsIfNeeded(
        seniorId,
        reference: reference,
        meals: meals,
        todayEvents: todayEvents,
      );
    }

    final refreshedEvents = await _todayMealEvents(
      seniorId,
      reference: reference,
    );
    final latestByMeal = <String, PersistedEventRecord>{};
    for (final event in refreshedEvents) {
      final mealLabel = event.payload['mealLabel'] as String?;
      if (mealLabel == null) continue;
      latestByMeal[mealLabel] ??= event;
    }

    final states = meals.map((meal) {
      final latest = latestByMeal[meal.label];
      final status = switch (latest?.type) {
        AppEventType.mealCompleted => MealSlotStatus.completed,
        AppEventType.mealMissed => MealSlotStatus.missed,
        _ => MealSlotStatus.pending,
      };
      return MealSlotState(
        id: meal.id,
        mealLabel: meal.label,
        scheduledAt: meal.scheduledAt,
        status: status,
        resolvedAt: latest?.happenedAt.toLocal(),
      );
    }).toList(growable: false);

    return NutritionState(slots: states);
  }

  @override
  Future<bool> markMealCompleted(
    String seniorId, {
    required String mealId,
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final meal = _findMeal(mealId, reference);
    if (meal == null) {
      throw StateError('Unknown meal slot: $mealId');
    }
    final existing = await _hasMealEventToday(
      seniorId,
      mealLabel: meal.label,
      reference: reference,
    );
    if (existing) return false;

    await eventRecorder.publishAndPersist(
      MealCompletedEvent(
        seniorId: seniorId,
        happenedAt: reference.toUtc(),
        mealLabel: meal.label,
      ),
      source: 'senior.nutrition',
    );
    return true;
  }

  @override
  Future<bool> markMealMissed(
    String seniorId, {
    required String mealId,
    DateTime? now,
  }) async {
    final reference = (now ?? DateTime.now()).toLocal();
    final meal = _findMeal(mealId, reference);
    if (meal == null) {
      throw StateError('Unknown meal slot: $mealId');
    }
    final existing = await _hasMealEventToday(
      seniorId,
      mealLabel: meal.label,
      reference: reference,
    );
    if (existing) return false;

    await eventRecorder.publishAndPersist(
      MealMissedEvent(
        seniorId: seniorId,
        happenedAt: reference.toUtc(),
        mealLabel: meal.label,
      ),
      source: 'senior.nutrition',
    );
    return true;
  }

  @override
  Future<List<PersistedEventRecord>> fetchRecentMealEvents(
    String seniorId, {
    int limit = 20,
  }) {
    return eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      types: const <AppEventType>{
        AppEventType.mealCompleted,
        AppEventType.mealMissed,
      },
      limit: limit,
    );
  }

  Future<void> _reconcileMissedMealsIfNeeded(
    String seniorId, {
    required DateTime reference,
    required List<_MealDef> meals,
    required List<PersistedEventRecord> todayEvents,
  }) async {
    final existing = <String>{
      for (final event in todayEvents)
        if (event.payload['mealLabel'] is String)
          event.payload['mealLabel'] as String,
    };
    for (final meal in meals) {
      if (existing.contains(meal.label)) continue;
      if (reference.isBefore(meal.scheduledAt.add(_kMealGrace))) continue;
      await eventRecorder.publishAndPersist(
        MealMissedEvent(
          seniorId: seniorId,
          happenedAt: meal.scheduledAt.add(_kMealGrace).toUtc(),
          mealLabel: meal.label,
        ),
        source: 'senior.nutrition.reconcile',
      );
    }
  }

  Future<List<PersistedEventRecord>> _todayMealEvents(
    String seniorId, {
    required DateTime reference,
  }) async {
    final events = await fetchRecentMealEvents(
      seniorId,
      limit: 80,
    );
    return events
        .where((event) => _isSameLocalDay(event.happenedAt, reference))
        .toList(growable: false);
  }

  Future<bool> _hasMealEventToday(
    String seniorId, {
    required String mealLabel,
    required DateTime reference,
  }) async {
    final events = await _todayMealEvents(
      seniorId,
      reference: reference,
    );
    return events.any((event) => event.payload['mealLabel'] == mealLabel);
  }

  _MealDef? _findMeal(String mealId, DateTime reference) {
    for (final meal in _mealsFor(reference)) {
      if (meal.id == mealId) return meal;
    }
    return null;
  }

  List<_MealDef> _mealsFor(DateTime reference) {
    return <_MealDef>[
      _MealDef(
        id: 'meal-breakfast',
        label: 'Breakfast',
        scheduledAt:
            DateTime(reference.year, reference.month, reference.day, 8, 0),
      ),
      _MealDef(
        id: 'meal-lunch',
        label: 'Lunch',
        scheduledAt:
            DateTime(reference.year, reference.month, reference.day, 13, 0),
      ),
      _MealDef(
        id: 'meal-dinner',
        label: 'Dinner',
        scheduledAt:
            DateTime(reference.year, reference.month, reference.day, 19, 30),
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

class _MealDef {
  const _MealDef({
    required this.id,
    required this.label,
    required this.scheduledAt,
  });

  final String id;
  final String label;
  final DateTime scheduledAt;
}
