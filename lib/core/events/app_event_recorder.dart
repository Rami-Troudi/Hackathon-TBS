import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';

typedef AppEventSideEffect = Future<void> Function(
  AppEvent event,
  PersistedEventRecord record,
  String source,
);

class AppEventRecorder {
  const AppEventRecorder({
    required this.eventBus,
    required this.eventRepository,
    this.afterPersist,
  });

  final AppEventBus eventBus;
  final EventRepository eventRepository;
  final AppEventSideEffect? afterPersist;

  Future<PersistedEventRecord> publishAndPersist(
    AppEvent event, {
    String source = 'runtime',
  }) async {
    eventBus.publish(event);
    final record = await eventRepository.addAppEvent(
      event,
      source: source,
    );
    await afterPersist?.call(event, record, source);
    return record;
  }

  Future<PersistedEventRecord> persistOnly(
    AppEvent event, {
    String source = 'runtime',
  }) {
    return eventRepository.addAppEvent(
      event,
      source: source,
    );
  }
}
