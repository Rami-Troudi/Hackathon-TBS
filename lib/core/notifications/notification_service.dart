import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/shared/models/notification_level.dart';

/// Maximum notification ID before the counter wraps back to zero.
/// Stays well within Android's int limit while avoiding ID exhaustion.
const _kMaxNotificationId = 9999;

abstract class NotificationService {
  Future<void> initialize();
  Future<AppPermissionStatus> requestPermission();
  Future<void> showInfo({required String title, required String body});
  Future<void> showWarning({required String title, required String body});
  Future<void> showCritical({required String title, required String body});
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    required this.logger,
    required this.permissionService,
  });

  final AppLogger logger;
  final PermissionService permissionService;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Monotonically increasing counter used as notification ID.
  /// Wraps at [_kMaxNotificationId] to avoid unbounded growth.
  int _notificationIdCounter = 0;

  /// Returns the next available notification ID and advances the counter.
  int _nextId() {
    final id = _notificationIdCounter;
    _notificationIdCounter = (_notificationIdCounter + 1) % _kMaxNotificationId;
    return id;
  }

  @override
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    logger.info('LocalNotificationService: initialized');
  }

  @override
  Future<AppPermissionStatus> requestPermission() {
    return permissionService.requestNotificationPermission();
  }

  @override
  Future<void> showInfo({required String title, required String body}) {
    return _show(
      level: NotificationLevel.info,
      title: title,
      body: body,
    );
  }

  @override
  Future<void> showWarning({required String title, required String body}) {
    return _show(
      level: NotificationLevel.warning,
      title: title,
      body: body,
    );
  }

  @override
  Future<void> showCritical({required String title, required String body}) {
    return _show(
      level: NotificationLevel.critical,
      title: title,
      body: body,
    );
  }

  Future<void> _show({
    required NotificationLevel level,
    required String title,
    required String body,
  }) async {
    final permissionStatus = await permissionService.notificationStatus();
    if (permissionStatus != AppPermissionStatus.granted) {
      logger.warn(
        'LocalNotificationService: notification skipped — '
        'permission is ${permissionStatus.name}',
      );
      return;
    }

    final importance = switch (level) {
      NotificationLevel.info => Importance.defaultImportance,
      NotificationLevel.warning => Importance.high,
      NotificationLevel.critical => Importance.max,
    };

    final priority = switch (level) {
      NotificationLevel.info => Priority.defaultPriority,
      NotificationLevel.warning => Priority.high,
      NotificationLevel.critical => Priority.max,
    };

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'senior_companion_${level.name}',
        'Senior Companion ${level.name} notifications',
        channelDescription:
            'Local ${level.name} notifications for the Senior Companion prototype',
        importance: importance,
        priority: priority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final id = _nextId();
    logger.debug(
      'LocalNotificationService: showing ${level.name} notification '
      'id=$id title="$title"',
    );

    await _plugin.show(id, title, body, details);
  }
}
