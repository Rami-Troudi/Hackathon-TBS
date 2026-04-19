import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_router.dart';
import 'package:senior_companion/core/ai/ai_assistant_repository.dart';
import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/ai/ai_fallback_service.dart';
import 'package:senior_companion/core/ai/ai_prompt_builder.dart';
import 'package:senior_companion/core/ai/ai_provider_adapter.dart';
import 'package:senior_companion/core/ai/ai_response_parser.dart';
import 'package:senior_companion/core/ai/alert_explanation_service.dart';
import 'package:senior_companion/core/ai/status_explanation_service.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
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
import 'package:senior_companion/core/repositories/check_in_repository.dart';
import 'package:senior_companion/core/repositories/dashboard_repository.dart';
import 'package:senior_companion/core/repositories/demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/guardian_alert_repository.dart';
import 'package:senior_companion/core/repositories/hydration_repository.dart';
import 'package:senior_companion/core/repositories/incident_repository.dart';
import 'package:senior_companion/core/repositories/local/local_app_session_repository.dart';
import 'package:senior_companion/core/repositories/local/local_check_in_repository.dart';
import 'package:senior_companion/core/repositories/local/local_dashboard_repository.dart';
import 'package:senior_companion/core/repositories/local/local_demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/local/local_event_repository.dart';
import 'package:senior_companion/core/repositories/local/local_guardian_alert_repository.dart';
import 'package:senior_companion/core/repositories/local/local_hydration_repository.dart';
import 'package:senior_companion/core/repositories/local/local_incident_repository.dart';
import 'package:senior_companion/core/repositories/local/local_medication_repository.dart';
import 'package:senior_companion/core/repositories/local/local_nutrition_repository.dart';
import 'package:senior_companion/core/repositories/local/local_preferences_repository.dart';
import 'package:senior_companion/core/repositories/local/local_profile_repository.dart';
import 'package:senior_companion/core/repositories/local/local_safe_zone_repository.dart';
import 'package:senior_companion/core/repositories/local/local_settings_repository.dart';
import 'package:senior_companion/core/repositories/local/local_summary_repository.dart';
import 'package:senior_companion/core/repositories/medication_repository.dart';
import 'package:senior_companion/core/repositories/nutrition_repository.dart';
import 'package:senior_companion/core/repositories/preferences_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/repositories/safe_zone_repository.dart';
import 'package:senior_companion/core/repositories/settings_repository.dart';
import 'package:senior_companion/core/repositories/summary_repository.dart';
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

final connectivityStateServiceProvider = Provider<ConnectivityStateService>(
  (ref) {
    final service = InMemoryConnectivityStateService();
    ref.onDispose(service.dispose);
    return service;
  },
);

final connectivityStateProvider = StreamProvider<AppConnectivityState>(
  (ref) => ref.watch(connectivityStateServiceProvider).watch(),
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

final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => LocalCheckInRepository(
    eventRepository: ref.watch(eventRepositoryProvider),
    eventRecorder: ref.watch(appEventRecorderProvider),
  ),
);

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => LocalMedicationRepository(
    hiveInitializer: ref.watch(hiveInitializerProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    eventRepository: ref.watch(eventRepositoryProvider),
    eventRecorder: ref.watch(appEventRecorderProvider),
  ),
);

final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => LocalIncidentRepository(
    eventRepository: ref.watch(eventRepositoryProvider),
    eventRecorder: ref.watch(appEventRecorderProvider),
    statusEngine: ref.watch(statusEngineProvider),
  ),
);

final guardianAlertRepositoryProvider = Provider<GuardianAlertRepository>(
  (ref) => LocalGuardianAlertRepository(
    eventRepository: ref.watch(eventRepositoryProvider),
    statusEngine: ref.watch(statusEngineProvider),
    storage: ref.watch(storageServiceProvider),
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(
    storage: ref.watch(storageServiceProvider),
  ),
);

final hydrationRepositoryProvider = Provider<HydrationRepository>(
  (ref) => LocalHydrationRepository(
    eventRepository: ref.watch(eventRepositoryProvider),
    eventRecorder: ref.watch(appEventRecorderProvider),
  ),
);

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => LocalNutritionRepository(
    eventRepository: ref.watch(eventRepositoryProvider),
    eventRecorder: ref.watch(appEventRecorderProvider),
  ),
);

final safeZoneRepositoryProvider = Provider<SafeZoneRepository>(
  (ref) => LocalSafeZoneRepository(
    hiveInitializer: ref.watch(hiveInitializerProvider),
    eventRepository: ref.watch(eventRepositoryProvider),
    eventRecorder: ref.watch(appEventRecorderProvider),
  ),
);

final summaryRepositoryProvider = Provider<SummaryRepository>(
  (ref) => LocalSummaryRepository(
    eventRepository: ref.watch(eventRepositoryProvider),
    statusEngine: ref.watch(statusEngineProvider),
  ),
);

final statusExplanationServiceProvider = Provider<StatusExplanationService>(
  (_) => const StatusExplanationService(),
);

final alertExplanationServiceProvider = Provider<AlertExplanationService>(
  (_) => const AlertExplanationService(),
);

final aiContextBuilderProvider = Provider<AiContextBuilder>(
  (ref) => AiContextBuilder(
    activeSeniorResolver: ref.watch(activeSeniorResolverProvider),
    appSessionRepository: ref.watch(appSessionRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    summaryRepository: ref.watch(summaryRepositoryProvider),
    dashboardRepository: ref.watch(dashboardRepositoryProvider),
    checkInRepository: ref.watch(checkInRepositoryProvider),
    medicationRepository: ref.watch(medicationRepositoryProvider),
    hydrationRepository: ref.watch(hydrationRepositoryProvider),
    nutritionRepository: ref.watch(nutritionRepositoryProvider),
    safeZoneRepository: ref.watch(safeZoneRepositoryProvider),
    incidentRepository: ref.watch(incidentRepositoryProvider),
    guardianAlertRepository: ref.watch(guardianAlertRepositoryProvider),
    eventRepository: ref.watch(eventRepositoryProvider),
  ),
);

final aiPromptBuilderProvider = Provider<AiPromptBuilder>(
  (_) => const AiPromptBuilder(),
);

final aiResponseParserProvider = Provider<AiResponseParser>(
  (_) => const AiResponseParser(),
);

final aiProviderAdapterProvider = Provider<AiProviderAdapter>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasExternalAi) {
    return const NullAiProviderAdapter();
  }
  return OpenAiCompatibleProviderAdapter(
    dio: ref.watch(dioProvider),
    config: config,
  );
});

final aiFallbackServiceProvider = Provider<AiFallbackService>(
  (ref) => AiFallbackService(
    statusExplanationService: ref.watch(statusExplanationServiceProvider),
    alertExplanationService: ref.watch(alertExplanationServiceProvider),
  ),
);

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>(
  (ref) => LocalAiAssistantRepository(
    contextBuilder: ref.watch(aiContextBuilderProvider),
    promptBuilder: ref.watch(aiPromptBuilderProvider),
    providerAdapter: ref.watch(aiProviderAdapterProvider),
    responseParser: ref.watch(aiResponseParserProvider),
    fallbackService: ref.watch(aiFallbackServiceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

final routerProvider = Provider<GoRouter>(buildAppRouter);
