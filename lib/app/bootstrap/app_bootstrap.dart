import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/app_initializer.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/config/app_config.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/logging/debug_logger.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/core/repositories/local/local_demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/local/local_profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/app_environment.dart';

class AppBootstrapData {
  const AppBootstrapData({
    required this.overrides,
    required this.logger,
  });

  final List<Override> overrides;
  final AppLogger logger;
}

class AppBootstrap {
  static Future<AppBootstrapData> bootstrap({
    required AppEnvironment environment,
  }) async {
    final logger = DebugAppLogger();
    final appConfig = AppConfig.fromEnvironment(environment);
    final storageService = SharedPreferencesStorageService();
    final hiveInitializer = HiveInitializer();
    final profileRepository =
        LocalProfileRepository(hiveInitializer: hiveInitializer);
    final demoSeedRepository = LocalDemoSeedRepository(
      profileRepository: profileRepository,
      storage: storageService,
      hiveInitializer: hiveInitializer,
    );
    final permissionService =
        PermissionHandlerPermissionService(logger: logger);
    final connectivityStateService = LocalConnectivityStateService(
      storage: storageService,
      logger: logger,
    );
    final notificationService = LocalNotificationService(
      logger: logger,
      permissionService: permissionService,
    );
    final initializer = AppInitializer(
      logger: logger,
      storageService: storageService,
      hiveInitializer: hiveInitializer,
      demoSeedRepository: demoSeedRepository,
      notificationService: notificationService,
      permissionService: permissionService,
    );

    await initializer.initialize();
    await connectivityStateService.initialize();

    return AppBootstrapData(
      logger: logger,
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
        appLoggerProvider.overrideWithValue(logger),
        storageServiceProvider.overrideWithValue(storageService),
        hiveInitializerProvider.overrideWithValue(hiveInitializer),
        permissionServiceProvider.overrideWithValue(permissionService),
        connectivityStateServiceProvider
            .overrideWithValue(connectivityStateService),
        notificationServiceProvider.overrideWithValue(notificationService),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        demoSeedRepositoryProvider.overrideWithValue(demoSeedRepository),
      ],
    );
  }
}
