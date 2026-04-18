import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_box_names.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';

class LocalEventRepository implements EventRepository {
  const LocalEventRepository({
    required this.hiveInitializer,
    required this.eventMapper,
    required this.profileRepository,
  });

  final HiveInitializer hiveInitializer;
  final AppEventMapper eventMapper;
  final ProfileRepository profileRepository;

  @override
  Future<PersistedEventRecord> addAppEvent(
    AppEvent event, {
    String source = 'runtime',
  }) async {
    final record = eventMapper.toPersistedRecord(
      event,
      source: source,
    );
    await addEventRecord(record);
    return record;
  }

  @override
  Future<void> addEventRecord(PersistedEventRecord record) async {
    await _box.put(record.id, record.toJson());
  }

  @override
  Future<void> addEventRecords(Iterable<PersistedEventRecord> records) async {
    for (final record in records) {
      await _box.put(record.id, record.toJson());
    }
  }

  @override
  Future<List<PersistedEventRecord>> fetchTimelineForSenior(
    String seniorId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) async {
    final filtered = _records.where((event) => event.seniorId == seniorId);
    return _sortedAndLimited(
      types == null
          ? filtered
          : filtered.where((event) => types.contains(event.type)),
      order: order,
      limit: limit,
    );
  }

  @override
  Future<List<PersistedEventRecord>> fetchRecentEventsForSenior(
    String seniorId, {
    int limit = 20,
  }) {
    return fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      limit: limit,
    );
  }

  @override
  Future<List<PersistedEventRecord>> fetchEventsByTypeForSenior(
    String seniorId,
    AppEventType type, {
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) {
    return fetchTimelineForSenior(
      seniorId,
      order: order,
      types: <AppEventType>{type},
      limit: limit,
    );
  }

  @override
  Future<List<PersistedEventRecord>> fetchEventsForGuardian(
    String guardianId, {
    TimelineOrder order = TimelineOrder.newestFirst,
    Set<AppEventType>? types,
    int? limit,
  }) async {
    final linkedSeniors = await profileRepository.getLinkedSeniors(guardianId);
    if (linkedSeniors.isEmpty) return const <PersistedEventRecord>[];
    final seniorIds = linkedSeniors.map((profile) => profile.id).toSet();
    final filtered =
        _records.where((event) => seniorIds.contains(event.seniorId));
    return _sortedAndLimited(
      types == null
          ? filtered
          : filtered.where((event) => types.contains(event.type)),
      order: order,
      limit: limit,
    );
  }

  @override
  Future<List<PersistedEventRecord>> fetchAll({
    TimelineOrder order = TimelineOrder.newestFirst,
    int? limit,
  }) async {
    return _sortedAndLimited(_records, order: order, limit: limit);
  }

  @override
  Future<void> clearEventHistory({String? seniorId}) async {
    if (seniorId == null) {
      await _box.clear();
      return;
    }

    final keysToDelete = _records
        .where((event) => event.seniorId == seniorId)
        .map((event) => event.id)
        .toList(growable: false);
    if (keysToDelete.isEmpty) return;
    await _box.deleteAll(keysToDelete);
  }

  Iterable<PersistedEventRecord> get _records => _box.values.map(
        (entry) => PersistedEventRecord.fromJson(
          Map<String, dynamic>.from(entry),
        ),
      );

  Future<List<PersistedEventRecord>> _sortedAndLimited(
    Iterable<PersistedEventRecord> records, {
    required TimelineOrder order,
    int? limit,
  }) async {
    final items = records.toList()
      ..sort((left, right) {
        final happenedAt = left.happenedAt.compareTo(right.happenedAt);
        if (happenedAt != 0) {
          return order == TimelineOrder.newestFirst ? -happenedAt : happenedAt;
        }
        final createdAt = left.createdAt.compareTo(right.createdAt);
        if (createdAt != 0) {
          return order == TimelineOrder.newestFirst ? -createdAt : createdAt;
        }
        final idCompare = left.id.compareTo(right.id);
        return order == TimelineOrder.newestFirst ? -idCompare : idCompare;
      });

    if (limit == null || limit >= items.length) {
      return items;
    }
    return items.take(limit).toList(growable: false);
  }

  Box<Map> get _box => hiveInitializer.box(HiveBoxNames.eventRecords);
}
