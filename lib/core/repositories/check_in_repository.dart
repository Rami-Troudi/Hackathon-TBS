import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';

abstract class CheckInRepository {
  Future<CheckInState> getTodayState(
    String seniorId, {
    DateTime? now,
    bool reconcileMissedWindow,
  });

  Future<bool> markCheckInCompleted(
    String seniorId, {
    DateTime? now,
  });

  Future<void> markNeedHelp(
    String seniorId, {
    DateTime? now,
  });

  Future<List<PersistedEventRecord>> fetchRecentCheckIns(
    String seniorId, {
    int limit,
  });
}
