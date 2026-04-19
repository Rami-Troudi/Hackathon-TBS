import 'package:flutter/foundation.dart';
import 'package:senior_companion/shared/models/app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableNetworkLogs,
    required this.aiProvider,
    required this.aiApiKey,
    required this.aiModel,
    required this.aiBaseUrl,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableNetworkLogs;
  final String aiProvider;
  final String aiApiKey;
  final String aiModel;
  final String aiBaseUrl;

  bool get hasExternalAi =>
      aiProvider != 'none' && aiApiKey.isNotEmpty && aiModel.isNotEmpty;

  factory AppConfig.fromEnvironment(AppEnvironment environment) {
    final baseUrl = switch (environment) {
      AppEnvironment.dev => 'https://prototype.local',
      AppEnvironment.staging => 'https://staging.prototype.local',
      AppEnvironment.prod => 'https://api.prototype.local',
    };

    return AppConfig(
      environment: environment,
      apiBaseUrl: baseUrl,
      enableNetworkLogs: kDebugMode,
      aiProvider:
          const String.fromEnvironment('AI_PROVIDER', defaultValue: 'none'),
      aiApiKey: const String.fromEnvironment('AI_API_KEY', defaultValue: ''),
      aiModel: const String.fromEnvironment(
        'AI_MODEL',
        defaultValue: 'gpt-4o-mini',
      ),
      aiBaseUrl: const String.fromEnvironment(
        'AI_BASE_URL',
        defaultValue: 'https://api.openai.com/v1',
      ),
    );
  }
}
