import 'package:senior_companion/core/repositories/demo_seed_repository.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';

class AppInitializer {
  AppInitializer({
    required this.logger,
    required this.storageService,
    required this.hiveInitializer,
    required this.demoSeedRepository,
    required this.notificationService,
    required this.permissionService,
  });

  final AppLogger logger;
  final StorageService storageService;
  final HiveInitializer hiveInitializer;
  final DemoSeedRepository demoSeedRepository;
  final NotificationService notificationService;
  final PermissionService permissionService;

  Future<void> initialize() async {
    logger.info('Initializing storage service');
    await storageService.initialize();

    logger.info('Initializing Hive structured storage');
    await hiveInitializer.initialize();

    logger.info('Seeding local demo data if needed');
    await demoSeedRepository.seedIfNeeded();

    logger.info('Initializing local notification service');
    await notificationService.initialize();

    await _requestStartupPermissionsIfNeeded();
  }

  Future<void> _requestStartupPermissionsIfNeeded() async {
    final alreadyRequested =
        storageService.getBool(StorageKeys.startupPermissionsRequested) ??
            false;
    if (alreadyRequested) return;

    logger.info('Requesting startup notification and location permissions');
    await permissionService.requestNotificationPermission();
    await permissionService.requestLocationPermission();
    await storageService.setBool(StorageKeys.startupPermissionsRequested, true);
  }
}
