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
  VoiceGatewayClient({
    required this.dio,
    required this.config,
    Future<Directory> Function()? temporaryDirectoryProvider,
  }) : _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory;

  final Dio dio;
  final AppConfig config;
  final Future<Directory> Function() _temporaryDirectoryProvider;

  bool get isConfigured =>
      config.usesLocalVoiceFallback || config.hasVoiceGateway;

  Future<VoiceGatewayAudioResponse> sendVoice({
    required String audioFilePath,
    required VoiceAudience audience,
    required Map<String, dynamic> appContext,
  }) async {
    if (config.usesLocalVoiceFallback) {
      return _buildLocalFallbackResponse(appContext);
    }

    if (!config.hasVoiceGateway) {
      throw StateError('Voice gateway is not configured.');
    }

    final endpoint = _voiceEndpoint(config.voiceGatewayBaseUrl);
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

    final outputPath = await _writeResponseBytes(bytes);
    return VoiceGatewayAudioResponse(audioFilePath: outputPath);
  }

  String _voiceEndpoint(String baseUrl) {
    final parsed = Uri.parse(baseUrl.trim());
    final normalizedPath = parsed.path.endsWith('/')
        ? parsed.path
        : parsed.path.isEmpty
            ? '/'
            : '${parsed.path}/';
    return parsed.replace(path: '${normalizedPath}voice').toString();
  }

  Future<VoiceGatewayAudioResponse> _buildLocalFallbackResponse(
    Map<String, dynamic> appContext,
  ) async {
    final responseText = _buildLocalFallbackText(appContext);
    final outputPath = await _writeResponseBytes(_buildSilentWavBytes());
    return VoiceGatewayAudioResponse(
      audioFilePath: outputPath,
      responseText: responseText,
    );
  }

  String _buildLocalFallbackText(Map<String, dynamic> appContext) {
    final summary = _readString(
      appContext['summary'],
      fallback: 'I checked your local status summary.',
    );
    final today = appContext['today'];
    final todayMap = today is Map<String, dynamic>
        ? today
        : today is Map
            ? Map<String, dynamic>.from(today)
            : const <String, dynamic>{};
    final checkIn = _readString(todayMap['checkIn'], fallback: 'pending');
    final nextMedication =
        _readString(todayMap['nextMedication'], fallback: 'none pending');
    final activeAlerts = appContext['activeAlerts'];
    final activeAlertCount = activeAlerts is List ? activeAlerts.length : 0;

    return 'QA local fallback response. '
        '$summary '
        'Check-in: $checkIn. '
        'Next medication: $nextMedication. '
        'Active alerts: $activeAlertCount.';
  }

  String _readString(
    Object? value, {
    required String fallback,
  }) {
    final content = value?.toString().trim() ?? '';
    return content.isEmpty ? fallback : content;
  }

  Future<String> _writeResponseBytes(List<int> bytes) async {
    final tempDir = await _temporaryDirectoryProvider();
    final outputFile = File(
      '${tempDir.path}/senior-companion-response-${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await outputFile.writeAsBytes(bytes, flush: true);
    return outputFile.path;
  }

  List<int> _buildSilentWavBytes() {
    const sampleRate = 16000;
    const channels = 1;
    const bitsPerSample = 16;
    const seconds = 2;
    final dataLength = sampleRate * seconds * channels * (bitsPerSample ~/ 8);
    final totalLength = 36 + dataLength;
    final bytes = <int>[];

    void writeAscii(String value) => bytes.addAll(value.codeUnits);
    void writeUint16(int value) =>
        bytes.addAll([value & 0xFF, (value >> 8) & 0xFF]);
    void writeUint32(int value) => bytes.addAll([
          value & 0xFF,
          (value >> 8) & 0xFF,
          (value >> 16) & 0xFF,
          (value >> 24) & 0xFF,
        ]);

    writeAscii('RIFF');
    writeUint32(totalLength);
    writeAscii('WAVE');
    writeAscii('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(sampleRate * channels * (bitsPerSample ~/ 8));
    writeUint16(channels * (bitsPerSample ~/ 8));
    writeUint16(bitsPerSample);
    writeAscii('data');
    writeUint32(dataLength);
    bytes.addAll(List<int>.filled(dataLength, 0));

    return bytes;
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
