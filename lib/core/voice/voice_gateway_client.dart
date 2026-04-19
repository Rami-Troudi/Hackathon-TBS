import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:senior_companion/core/config/app_config.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';

enum VoiceGatewayErrorKind {
  network,
  timeout,
  unauthorized,
  badRequest,
  server,
  invalidResponse,
  unknown,
}

class VoiceGatewayException implements Exception {
  const VoiceGatewayException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.detail,
  });

  final VoiceGatewayErrorKind kind;
  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (status: $statusCode)';
    final detailPart = detail == null ? '' : ' | detail: $detail';
    return '$message$status$detailPart';
  }
}

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

    Response<List<int>> response;
    try {
      response = await dio.post<List<int>>(
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
    } on DioException catch (error) {
      throw _mapDioException(error);
    }

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const VoiceGatewayException(
        kind: VoiceGatewayErrorKind.invalidResponse,
        message: 'Voice gateway returned an empty audio response.',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final outputFile = File(
      '${tempDir.path}/senior-companion-response-${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await outputFile.writeAsBytes(bytes, flush: true);
    return VoiceGatewayAudioResponse(audioFilePath: outputFile.path);
  }

  VoiceGatewayException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final detail = _extractResponseDetail(error.response?.data);

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return VoiceGatewayException(
        kind: VoiceGatewayErrorKind.timeout,
        message: 'Voice service timed out.',
        statusCode: statusCode,
        detail: detail,
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return VoiceGatewayException(
        kind: VoiceGatewayErrorKind.network,
        message: 'Could not reach the voice service.',
        statusCode: statusCode,
        detail: detail ?? error.message,
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return VoiceGatewayException(
        kind: VoiceGatewayErrorKind.unauthorized,
        message: 'Voice service authorization failed.',
        statusCode: statusCode,
        detail: detail,
      );
    }

    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return VoiceGatewayException(
        kind: VoiceGatewayErrorKind.badRequest,
        message: 'Voice service rejected the request.',
        statusCode: statusCode,
        detail: detail,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return VoiceGatewayException(
        kind: VoiceGatewayErrorKind.server,
        message: 'Voice service is currently unavailable.',
        statusCode: statusCode,
        detail: detail,
      );
    }

    return VoiceGatewayException(
      kind: VoiceGatewayErrorKind.unknown,
      message: 'Voice service request failed.',
      statusCode: statusCode,
      detail: detail ?? error.message,
    );
  }

  String? _extractResponseDetail(Object? data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (data is List<int>) {
      final decoded = utf8.decode(data, allowMalformed: true).trim();
      return decoded.isEmpty ? null : decoded;
    }
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      return jsonEncode(data);
    }
    return data.toString();
  }
}
