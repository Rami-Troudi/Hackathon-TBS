import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';

enum TimelineOrder { newestFirst, oldestFirst }

abstract class EventRepository {
  Future<PersistedEventRecord> addAppEvent(
    AppEvent event, {
    String source,
  });

  Future<void> addEventRecord(PersistedEventRecord record);
  Future<void> addEventRecords(Iterable<PersistedEventRecord> records);

  Future<List<PersistedEventRecord>> fetchTimelineForSenior(
    String seniorId, {
    TimelineOrder order,
    Set<AppEventType>? types,
    int? limit,
  });

  Future<List<PersistedEventRecord>> fetchRecentEventsForSenior(
    String seniorId, {
    int limit,
  });

  Future<List<PersistedEventRecord>> fetchEventsByTypeForSenior(
    String seniorId,
    AppEventType type, {
    TimelineOrder order,
    int? limit,
  });

  Future<List<PersistedEventRecord>> fetchEventsForGuardian(
    String guardianId, {
    TimelineOrder order,
    Set<AppEventType>? types,
    int? limit,
  });

  Future<List<PersistedEventRecord>> fetchAll({
    TimelineOrder order,
    int? limit,
  });

  Future<void> clearEventHistory({String? seniorId});
}
