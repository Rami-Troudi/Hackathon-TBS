import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:senior_companion/core/config/app_config.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';

class VoiceGatewayClient {
  const VoiceGatewayClient({
    required this.dio,
    required this.config,
  });

  final Dio dio;
  final AppConfig config;

  bool get isConfigured => config.hasVoiceGateway;

  Future<VoiceGatewayAudioResponse> sendVoice({
    required String audioFilePath,
    required VoiceAudience audience,
    required Map<String, dynamic> appContext,
  }) async {
    if (!isConfigured) {
      throw StateError('Voice gateway is not configured.');
    }

    final endpoint =
        Uri.parse(config.voiceGatewayBaseUrl).resolve('/voice').toString();
    final data = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(
        audioFilePath,
        filename: 'senior-companion-request.wav',
      ),
      'audience': audience.name,
      'app_context_json': jsonEncode(appContext),
    });

    final response = await dio.post<List<int>>(
      endpoint,
      data: data,
      options: Options(
        responseType: ResponseType.bytes,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: <String, String>{
          if (config.voiceGatewayApiKey.isNotEmpty)
            'X-API-Key': config.voiceGatewayApiKey,
        },
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Voice gateway returned an empty audio response.');
    }

    final tempDir = await getTemporaryDirectory();
    final outputFile = File(
      '${tempDir.path}/senior-companion-response-${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await outputFile.writeAsBytes(bytes, flush: true);
    return VoiceGatewayAudioResponse(audioFilePath: outputFile.path);
  }
}
