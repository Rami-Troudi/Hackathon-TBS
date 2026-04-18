import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_router.dart';
import 'package:senior_companion/core/config/app_config.dart';
import 'package:senior_companion/core/events/app_event_bus.dart';
import 'package:senior_companion/core/events/app_event_mapper.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/networking/api_client.dart';
import 'package:senior_companion/core/networking/dio_provider.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/repositories/dashboard_repository.dart';
import 'package:senior_companion/core/repositories/demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_app_session_repository.dart';
import 'package:senior_companion/core/repositories/local/local_dashboard_repository.dart';
import 'package:senior_companion/core/repositories/local/local_demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_preferences_repository.dart';
import 'package:senior_companion/core/repositories/local/local_profile_repository.dart';
import 'package:senior_companion/core/repositories/preferences_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/core/storage/storage_service.dart';

final appConfigProvider = Provider<AppConfig>(
  (_) => throw UnimplementedError(
      'appConfigProvider must be overridden at bootstrap'),
);

final appLoggerProvider = Provider<AppLogger>(
  (_) => throw UnimplementedError(
      'appLoggerProvider must be overridden at bootstrap'),
);

final storageServiceProvider = Provider<StorageService>(
  (_) => throw UnimplementedError(
      'storageServiceProvider must be overridden at bootstrap'),
);

final hiveInitializerProvider = Provider<HiveInitializer>(
  (_) => throw UnimplementedError(
      'hiveInitializerProvider must be overridden at bootstrap'),
);

final permissionServiceProvider = Provider<PermissionService>(
  (_) => throw UnimplementedError(
      'permissionServiceProvider must be overridden at bootstrap'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (_) => throw UnimplementedError(
      'notificationServiceProvider must be overridden at bootstrap'),
);

final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final appEventMapperProvider = Provider<AppEventMapper>(
  (_) => const AppEventMapper(),
);

final statusEngineProvider = Provider<SeniorStatusEngine>(
  (_) => const SeniorStatusEngine(),
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return buildDioClient(
    config,
    logger: ref.watch(appLoggerProvider),
  );
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    dio: ref.watch(dioProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

final appSessionRepositoryProvider = Provider<AppSessionRepository>(
  (ref) => LocalAppSessionRepository(
    storage: ref.watch(storageServiceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => LocalPreferencesRepository(
    storage: ref.watch(storageServiceProvider),
  ),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => LocalProfileRepository(
    hiveInitializer: ref.watch(hiveInitializerProvider),
  ),
);

final activeSeniorResolverProvider = Provider<ActiveSeniorResolver>(
  (ref) => ActiveSeniorResolver(
    appSessionRepository: ref.watch(appSessionRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  ),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => LocalEventRepository(
    hiveInitializer: ref.watch(hiveInitializerProvider),
    eventMapper: ref.watch(appEventMapperProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  ),
);

final demoSeedRepositoryProvider = Provider<DemoSeedRepository>(
  (ref) => LocalDemoSeedRepository(
    profileRepository: ref.watch(profileRepositoryProvider),
    storage: ref.watch(storageServiceProvider),
  ),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => LocalDashboardRepository(
    eventRepository: ref.watch(eventRepositoryProvider),
    statusEngine: ref.watch(statusEngineProvider),
    activeSeniorResolver: ref.watch(activeSeniorResolverProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

final appEventRecorderProvider = Provider<AppEventRecorder>(
  (ref) => AppEventRecorder(
    eventBus: ref.watch(appEventBusProvider),
    eventRepository: ref.watch(eventRepositoryProvider),
  ),
);

final routerProvider = Provider<GoRouter>(buildAppRouter);
