import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/config/app_config.dart';
import 'package:senior_companion/core/voice/voice_gateway_client.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';
import 'package:senior_companion/shared/models/app_environment.dart';

Future<String> _createWavFile() async {
  const sampleRate = 16000;
  const channels = 1;
  const bitsPerSample = 16;
  const seconds = 3;
  final dataLength = sampleRate * seconds * channels * (bitsPerSample ~/ 8);
  final totalLength = 36 + dataLength;

  final bytes = BytesBuilder();
  void writeAscii(String value) => bytes.add(value.codeUnits);
  void writeUint16(int value) => bytes.add([value & 0xFF, (value >> 8) & 0xFF]);
  void writeUint32(int value) => bytes.add([
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
  bytes.add(List<int>.filled(dataLength, 0));

  final artifactDir = await _testArtifactDirectory();
  final file = File(
    '${artifactDir.path}/voice-gateway-test-${DateTime.now().microsecondsSinceEpoch}.wav',
  );
  await file.writeAsBytes(bytes.toBytes(), flush: true);
  return file.path;
}

Future<Directory> _testArtifactDirectory() async {
  final dir = Directory(
    '${Directory.current.path}/.dart_tool/test_artifacts/voice_gateway_client',
  );
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

VoiceGatewayClient _clientFor(
  String baseUrl, {
  VoiceGatewayMode mode = VoiceGatewayMode.gateway,
}) {
  final config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://prototype.local',
    enableNetworkLogs: false,
    voiceGatewayBaseUrl: baseUrl,
    voiceGatewayApiKey: '',
    voiceGatewayMode: mode,
  );
  return VoiceGatewayClient(
    dio: Dio(),
    config: config,
    temporaryDirectoryProvider: _testArtifactDirectory,
  );
}

void main() {
  test('maps 400 gateway responses to badRequest with detail', () async {
    final audioPath = await _createWavFile();
    addTearDown(() => File(audioPath).delete());

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      await request.drain();
      request.response.statusCode = 400;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"detail":"Could not detect speech in audio"}');
      await request.response.close();
    });

    final client =
        _clientFor('http://${server.address.address}:${server.port}');

    expect(
      () => client.sendVoice(
        audioFilePath: audioPath,
        audience: VoiceAudience.senior,
        appContext: const <String, dynamic>{'source': 'test'},
      ),
      throwsA(
        predicate(
          (error) =>
              error is VoiceGatewayException &&
              error.kind == VoiceGatewayErrorKind.badRequest &&
              (error.detail ?? '').contains('Could not detect speech in audio'),
        ),
      ),
    );
  });

  test('maps 500 gateway responses to server error', () async {
    final audioPath = await _createWavFile();
    addTearDown(() => File(audioPath).delete());

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      await request.drain();
      request.response.statusCode = 500;
      request.response.write('Internal Server Error');
      await request.response.close();
    });

    final client =
        _clientFor('http://${server.address.address}:${server.port}');

    expect(
      () => client.sendVoice(
        audioFilePath: audioPath,
        audience: VoiceAudience.senior,
        appContext: const <String, dynamic>{'source': 'test'},
      ),
      throwsA(
        predicate(
          (error) =>
              error is VoiceGatewayException &&
              error.kind == VoiceGatewayErrorKind.server,
        ),
      ),
    );
  });

  test(
      'local fallback mode bypasses network and returns deterministic response',
      () async {
    final audioPath = await _createWavFile();
    addTearDown(() => File(audioPath).delete());
    final client = _clientFor(
      'http://127.0.0.1:1',
      mode: VoiceGatewayMode.localFallback,
    );

    final response = await client.sendVoice(
      audioFilePath: audioPath,
      audience: VoiceAudience.senior,
      appContext: const <String, dynamic>{
        'summary': 'Hydration looks good today.',
        'today': <String, dynamic>{
          'checkIn': 'completed',
          'nextMedication': 'Vitamin D at 18:00',
        },
        'activeAlerts': <String>['medium: Missed check-in'],
      },
    );
    addTearDown(() => File(response.audioFilePath).delete());

    expect(client.isConfigured, isTrue);
    expect(await File(response.audioFilePath).exists(), isTrue);
    expect(await File(response.audioFilePath).length(), greaterThan(44));
    expect(response.responseText, contains('QA local fallback response.'));
    expect(response.responseText, contains('Hydration looks good today.'));
    expect(response.responseText, contains('Check-in: completed.'));
    expect(
      response.responseText,
      contains('Next medication: Vitamin D at 18:00.'),
    );
    expect(response.responseText, contains('Active alerts: 1.'));
  });
}
