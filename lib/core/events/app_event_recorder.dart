import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';

class AppEventRecorder {
  const AppEventRecorder({
    required this.eventBus,
    required this.eventRepository,
  });

  final AppEventBus eventBus;
  final EventRepository eventRepository;

  Future<PersistedEventRecord> publishAndPersist(
    AppEvent event, {
    String source = 'runtime',
  }) async {
    eventBus.publish(event);
    return eventRepository.addAppEvent(
      event,
      source: source,
    );
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
