import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/notifications/app_event_notification_dispatcher.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';

void main() {
  test('dispatches warning notification for missed check-in', () async {
    final notifications = _FakeNotificationService();
    final dispatcher = AppEventNotificationDispatcher(
      notificationService: notifications,
      logger: const _NoopLogger(),
      notificationsEnabled: () async => true,
    );
    final event = CheckInMissedEvent(
      seniorId: 'senior-a',
      happenedAt: DateTime.utc(2026, 4, 19, 12),
      windowLabel: 'Daily morning check-in',
    );

    await dispatcher.dispatch(
      event,
      _recordFor(event),
      'senior.check_in.reconcile',
    );

    expect(notifications.warningTitles, contains('Check-in missed'));
    expect(notifications.criticalTitles, isEmpty);
  });

  test('suppresses confirmed incident notification when emergency follows',
      () async {
    final notifications = _FakeNotificationService();
    final dispatcher = AppEventNotificationDispatcher(
      notificationService: notifications,
      logger: const _NoopLogger(),
      notificationsEnabled: () async => true,
    );
    final event = IncidentConfirmedEvent(
      seniorId: 'senior-a',
      happenedAt: DateTime.utc(2026, 4, 19, 10),
    );

    await dispatcher.dispatch(
      event,
      _recordFor(event),
      'senior.incident.request_help',
    );

    expect(notifications.warningTitles, isEmpty);
    expect(notifications.criticalTitles, isEmpty);
  });

  test('respects active profile notification setting', () async {
    final notifications = _FakeNotificationService();
    final dispatcher = AppEventNotificationDispatcher(
      notificationService: notifications,
      logger: const _NoopLogger(),
      notificationsEnabled: () async => false,
    );
    final event = EmergencyTriggeredEvent(
      seniorId: 'senior-a',
      happenedAt: DateTime.utc(2026, 4, 19, 10),
    );

    await dispatcher.dispatch(
      event,
      _recordFor(event),
      'senior.incident',
    );

    expect(notifications.criticalTitles, isEmpty);
  });
}

PersistedEventRecord _recordFor(AppEvent event) {
  return const AppEventMapper().toPersistedRecord(
    event,
    id: 'event-1',
    createdAt: DateTime.utc(2026, 4, 19, 10),
  );
}

class _FakeNotificationService implements NotificationService {
  final warningTitles = <String>[];
  final criticalTitles = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<AppPermissionStatus> requestPermission() async =>
      AppPermissionStatus.granted;

  @override
  Future<void> showCritical({
    required String title,
    required String body,
  }) async {
    criticalTitles.add(title);
  }

  @override
  Future<void> showInfo({
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> showWarning({
    required String title,
    required String body,
  }) async {
    warningTitles.add(title);
  }
}

class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  void debug(String message) {}

  @override
  void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {}

  @override
  void info(String message) {}

  @override
  void warn(String message) {}
}
