import 'package:flutter/foundation.dart';
import 'package:senior_companion/shared/models/app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableNetworkLogs,
    required this.voiceGatewayBaseUrl,
    required this.voiceGatewayApiKey,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableNetworkLogs;
  final String voiceGatewayBaseUrl;
  final String voiceGatewayApiKey;

  bool get hasVoiceGateway => voiceGatewayBaseUrl.trim().isNotEmpty;

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
      voiceGatewayBaseUrl: const String.fromEnvironment(
        'VOICE_GATEWAY_BASE_URL',
        defaultValue: 'https://xqdrant.moetezfradi.me',
      ),
      voiceGatewayApiKey: const String.fromEnvironment('VOICE_GATEWAY_API_KEY',
          defaultValue: ''),
    );
  }
}
