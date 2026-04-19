import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';

abstract class HydrationRepository {
  Future<HydrationState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedSlots,
  });

  Future<bool> markHydrationCompleted(
    String seniorId, {
    required String slotId,
    DateTime? now,
  });

  Future<bool> markHydrationMissed(
    String seniorId, {
    required String slotId,
    DateTime? now,
  });

  Future<List<PersistedEventRecord>> fetchRecentHydrationEvents(
    String seniorId, {
    int limit,
  });
}
