import 'package:senior_companion/core/voice/voice_context_payload_builder.dart';
import 'package:senior_companion/core/voice/voice_gateway_client.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';

abstract class VoiceCompanionRepository {
  bool get isConfigured;

  Future<VoiceInteractionResult> askSeniorWithAudio(String audioFilePath);
}

class GatewayVoiceCompanionRepository implements VoiceCompanionRepository {
  const GatewayVoiceCompanionRepository({
    required this.gatewayClient,
    required this.contextPayloadBuilder,
  });

  final VoiceGatewayClient gatewayClient;
  final VoiceContextPayloadBuilder contextPayloadBuilder;

  @override
  bool get isConfigured => gatewayClient.isConfigured;

  @override
  Future<VoiceInteractionResult> askSeniorWithAudio(
      String audioFilePath) async {
    final context = await contextPayloadBuilder.buildSeniorPayload();
    final response = await gatewayClient.sendVoice(
      audioFilePath: audioFilePath,
      audience: VoiceAudience.senior,
      appContext: context,
    );
    return VoiceInteractionResult(
      responseAudioPath: response.audioFilePath,
      responseText: response.responseText,
    );
  }
}
