import 'package:flutter/foundation.dart';
import 'package:senior_companion/shared/models/app_environment.dart';

enum VoiceGatewayMode {
  gateway,
  localFallback;

  static VoiceGatewayMode fromRaw(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'local_fallback' => VoiceGatewayMode.localFallback,
      _ => VoiceGatewayMode.gateway,
    };
  }
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableNetworkLogs,
    required this.voiceGatewayBaseUrl,
    required this.voiceGatewayApiKey,
    required this.voiceGatewayMode,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableNetworkLogs;
  final String voiceGatewayBaseUrl;
  final String voiceGatewayApiKey;
  final VoiceGatewayMode voiceGatewayMode;

  bool get hasVoiceGateway => voiceGatewayBaseUrl.trim().isNotEmpty;
  bool get usesLocalVoiceFallback =>
      voiceGatewayMode == VoiceGatewayMode.localFallback;

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
      voiceGatewayMode: VoiceGatewayMode.fromRaw(
        const String.fromEnvironment(
          'VOICE_GATEWAY_MODE',
          defaultValue: 'local_fallback',
        ),
      ),
    );
  }
}
