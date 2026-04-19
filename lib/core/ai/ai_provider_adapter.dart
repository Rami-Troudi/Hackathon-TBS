import 'package:dio/dio.dart';
import 'package:senior_companion/core/ai/ai_request.dart';
import 'package:senior_companion/core/config/app_config.dart';

abstract class AiProviderAdapter {
  bool get isConfigured;

  Future<String?> generateText({
    required AiRequest request,
    required String prompt,
  });
}

class OpenAiCompatibleProviderAdapter implements AiProviderAdapter {
  const OpenAiCompatibleProviderAdapter({
    required this.dio,
    required this.config,
  });

  final Dio dio;
  final AppConfig config;

  @override
  bool get isConfigured =>
      config.aiProvider == 'openai_compatible' &&
      config.aiApiKey.isNotEmpty &&
      config.aiModel.isNotEmpty;

  @override
  Future<String?> generateText({
    required AiRequest request,
    required String prompt,
  }) async {
    if (!isConfigured) return null;

    final endpoint = '${config.aiBaseUrl}/chat/completions';
    final response = await dio.post<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        'model': config.aiModel,
        'temperature': 0.2,
        'messages': <Map<String, String>>[
          const <String, String>{
            'role': 'system',
            'content':
                'You are a grounded in-app assistant. Use only provided app context.',
          },
          <String, String>{'role': 'user', 'content': prompt},
        ],
      },
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer ${config.aiApiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );

    final body = response.data;
    if (body == null) return null;
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map<String, dynamic>) return null;
    final message = first['message'];
    if (message is! Map<String, dynamic>) return null;
    final content = message['content'];
    if (content is String) return content;
    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is Map<String, dynamic> && part['text'] is String) {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(part['text'] as String);
        }
      }
      return buffer.isEmpty ? null : buffer.toString();
    }
    return null;
  }
}

class NullAiProviderAdapter implements AiProviderAdapter {
  const NullAiProviderAdapter();

  @override
  bool get isConfigured => false;

  @override
  Future<String?> generateText({
    required AiRequest request,
    required String prompt,
  }) async {
    return null;
  }
}
