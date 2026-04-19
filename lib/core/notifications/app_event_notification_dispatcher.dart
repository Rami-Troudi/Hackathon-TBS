import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/shared/models/notification_level.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class AppEventNotificationDispatcher {
  const AppEventNotificationDispatcher({
    required this.notificationService,
    required this.logger,
    required this.notificationsEnabled,
  });

  final NotificationService notificationService;
  final AppLogger logger;
  final Future<bool> Function() notificationsEnabled;

  Future<void> dispatch(
    AppEvent event,
    PersistedEventRecord record,
    String source,
  ) async {
    final notification = _notificationFor(event, record, source);
    if (notification == null) return;

    final enabled = await notificationsEnabled();
    if (!enabled) {
      logger.info(
        'AppEventNotificationDispatcher: skipped ${event.type.name} '
        'because notifications are disabled for the active profile',
      );
      return;
    }

    try {
      switch (notification.level) {
        case NotificationLevel.info:
          await notificationService.showInfo(
            title: notification.title,
            body: notification.body,
          );
        case NotificationLevel.warning:
          await notificationService.showWarning(
            title: notification.title,
            body: notification.body,
          );
        case NotificationLevel.critical:
          await notificationService.showCritical(
            title: notification.title,
            body: notification.body,
          );
      }
    } catch (error, stackTrace) {
      logger.warn(
        'AppEventNotificationDispatcher: failed to show '
        '${event.type.name} notification: $error\n$stackTrace',
      );
    }
  }

  AppEventNotification? _notificationFor(
    AppEvent event,
    PersistedEventRecord record,
    String source,
  ) {
    return switch (event) {
      CheckInMissedEvent(:final windowLabel) => AppEventNotification(
          level: NotificationLevel.warning,
          title: 'Check-in missed',
          body: '$windowLabel was missed. Please confirm the senior is okay.',
        ),
      MedicationMissedEvent(:final medicationName) => AppEventNotification(
          level: NotificationLevel.warning,
          title: 'Medication missed',
          body: '$medicationName was marked as missed today.',
        ),
      HydrationMissedEvent(:final slotLabel) => AppEventNotification(
          level: NotificationLevel.warning,
          title: 'Hydration reminder missed',
          body: '$slotLabel hydration was not confirmed.',
        ),
      MealMissedEvent(:final mealLabel) => AppEventNotification(
          level: NotificationLevel.warning,
          title: 'Meal reminder missed',
          body: '$mealLabel was not confirmed.',
        ),
      IncidentSuspectedEvent() => const AppEventNotification(
          level: NotificationLevel.warning,
          title: 'Incident needs review',
          body: 'A suspicious incident signal is waiting for review.',
        ),
      IncidentConfirmedEvent() when _emergencyFollows(source) => null,
      IncidentConfirmedEvent() => const AppEventNotification(
          level: NotificationLevel.critical,
          title: 'Confirmed incident',
          body: 'An incident was confirmed and needs follow-up.',
        ),
      EmergencyTriggeredEvent() => const AppEventNotification(
          level: NotificationLevel.critical,
          title: 'Emergency request',
          body: 'Immediate family follow-up is recommended.',
        ),
      SafeZoneExitedEvent(:final zoneName) => AppEventNotification(
          level: NotificationLevel.warning,
          title: 'Outside safe zone',
          body: 'The local prototype marked the senior outside $zoneName.',
        ),
      GuardianAlertGeneratedEvent(:final alertLevel) => AppEventNotification(
          level: alertLevel,
          title: 'Guardian alert',
          body: 'A local guardian alert was generated.',
        ),
      SeniorStatusChangedEvent(:final newStatus)
          when record.severity != EventSeverity.info =>
        AppEventNotification(
          level: newStatus.notificationLevel,
          title: 'Status changed',
          body: 'Senior status is now ${newStatus.label}.',
        ),
      CheckInCompletedEvent() ||
      MedicationTakenEvent() ||
      HydrationCompletedEvent() ||
      MealCompletedEvent() ||
      IncidentDismissedEvent() ||
      SafeZoneEnteredEvent() ||
      SeniorStatusChangedEvent() =>
        null,
    };
  }

  bool _emergencyFollows(String source) {
    return source == 'senior.check_in' ||
        source == 'senior.incident.request_help';
  }
}

class AppEventNotification {
  const AppEventNotification({
    required this.level,
    required this.title,
    required this.body,
  });

  final NotificationLevel level;
  final String title;
  final String body;
}
