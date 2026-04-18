import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/core/storage/storage_service.dart';

class AppInitializer {
  AppInitializer({
    required this.logger,
    required this.storageService,
    required this.notificationService,
  });

  final AppLogger logger;
  final StorageService storageService;
  final NotificationService notificationService;

  Future<void> initialize() async {
    logger.info('Initializing storage service');
    await storageService.initialize();

    logger.info('Initializing local notification service');
    await notificationService.initialize();
  }
}
