import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/voice/voice_companion_repository.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';
import 'package:senior_companion/core/voice/voice_playback_service.dart';
import 'package:senior_companion/core/voice/voice_recording_service.dart';
import 'package:senior_companion/core/voice/voice_gateway_client.dart';
import 'package:senior_companion/features/companion/senior_companion_providers.dart';

class _FakeVoiceCompanionRepository implements VoiceCompanionRepository {
  _FakeVoiceCompanionRepository({this.responseTextToReturn});

  int calls = 0;
  String? receivedPath;
  final String? responseTextToReturn;

  @override
  bool get isConfigured => true;

  @override
  Future<VoiceInteractionResult> askSeniorWithAudio(
    String audioFilePath,
  ) async {
    calls += 1;
    receivedPath = audioFilePath;
    return VoiceInteractionResult(
      responseAudioPath: 'voice-response.wav',
      responseText: responseTextToReturn,
    );
  }
}

class _ThrowingVoiceCompanionRepository implements VoiceCompanionRepository {
  _ThrowingVoiceCompanionRepository(this.error);

  final Object error;

  @override
  bool get isConfigured => true;

  @override
  Future<VoiceInteractionResult> askSeniorWithAudio(
      String audioFilePath) async {
    throw error;
  }
}

class _FakeVoiceRecordingService implements VoiceRecordingService {
  _FakeVoiceRecordingService(this.recordedPath);

  final String recordedPath;
  bool recording = false;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> isRecording() async => recording;

  @override
  Future<String> start() async {
    recording = true;
    return recordedPath;
  }

  @override
  Future<String?> stop() async {
    recording = false;
    return recordedPath;
  }
}

class _FakeVoicePlaybackService implements VoicePlaybackService {
  String? playedPath;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playFile(String path) async {
    playedPath = path;
  }

  @override
  Future<void> stop() async {}
}

Future<String> _createWavFile({required int seconds}) async {
  const sampleRate = 16000;
  const channels = 1;
  const bitsPerSample = 16;
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

  final file = File(
    '${Directory.systemTemp.path}/sc-voice-test-${DateTime.now().microsecondsSinceEpoch}-$seconds.wav',
  );
  await file.writeAsBytes(bytes.toBytes(), flush: true);
  return file.path;
}

void main() {
  test('senior companion records audio, sends it, and plays response',
      () async {
    final recordingPath = await _createWavFile(seconds: 4);
    addTearDown(() => File(recordingPath).delete());

    final repository = _FakeVoiceCompanionRepository();
    final recorder = _FakeVoiceRecordingService(recordingPath);
    final playback = _FakeVoicePlaybackService();
    final container = ProviderContainer(
      overrides: [
        voiceCompanionRepositoryProvider.overrideWithValue(repository),
        voiceGatewayConfiguredProvider.overrideWithValue(true),
        voiceRecordingServiceProvider.overrideWithValue(recorder),
        voicePlaybackServiceProvider.overrideWithValue(playback),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(seniorCompanionControllerProvider.notifier);
    await notifier.startListening();

    expect(
      container.read(seniorCompanionControllerProvider).status,
      VoiceInteractionStatus.listening,
    );

    await notifier.stopAndSend();

    final state = container.read(seniorCompanionControllerProvider);
    expect(state.status, VoiceInteractionStatus.idle);
    expect(state.lastRequestPath, recordingPath);
    expect(state.lastResponsePath, 'voice-response.wav');
    expect(state.lastResponseText, isNull);
    expect(repository.calls, 1);
    expect(repository.receivedPath, recordingPath);
    expect(playback.playedPath, 'voice-response.wav');
  });

  test('senior companion is unavailable when gateway is not configured',
      () async {
    final container = ProviderContainer(
      overrides: [
        voiceGatewayConfiguredProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(seniorCompanionControllerProvider);

    expect(state.status, VoiceInteractionStatus.unavailable);
  });

  test('senior companion rejects recordings shorter than 3 seconds', () async {
    final shortPath = await _createWavFile(seconds: 1);
    addTearDown(() => File(shortPath).delete());

    final repository = _FakeVoiceCompanionRepository();
    final recorder = _FakeVoiceRecordingService(shortPath);
    final playback = _FakeVoicePlaybackService();
    final container = ProviderContainer(
      overrides: [
        voiceCompanionRepositoryProvider.overrideWithValue(repository),
        voiceGatewayConfiguredProvider.overrideWithValue(true),
        voiceRecordingServiceProvider.overrideWithValue(recorder),
        voicePlaybackServiceProvider.overrideWithValue(playback),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(seniorCompanionControllerProvider.notifier);
    await notifier.startListening();
    await notifier.stopAndSend();

    final state = container.read(seniorCompanionControllerProvider);
    expect(state.status, VoiceInteractionStatus.error);
    expect(state.errorMessage, contains('at least 3 seconds'));
    expect(repository.calls, 0);
  });

  test('senior companion shows local fallback guidance on gateway failures',
      () async {
    final recordingPath = await _createWavFile(seconds: 4);
    addTearDown(() => File(recordingPath).delete());

    final recorder = _FakeVoiceRecordingService(recordingPath);
    final playback = _FakeVoicePlaybackService();
    final repository = _ThrowingVoiceCompanionRepository(
      const VoiceGatewayException(
        kind: VoiceGatewayErrorKind.server,
        message: 'Voice service is currently unavailable.',
        statusCode: 500,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        voiceCompanionRepositoryProvider.overrideWithValue(repository),
        voiceGatewayConfiguredProvider.overrideWithValue(true),
        voiceRecordingServiceProvider.overrideWithValue(recorder),
        voicePlaybackServiceProvider.overrideWithValue(playback),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(seniorCompanionControllerProvider.notifier);
    await notifier.startListening();
    await notifier.stopAndSend();

    final state = container.read(seniorCompanionControllerProvider);
    expect(state.status, VoiceInteractionStatus.error);
    expect(state.errorMessage,
        contains('Voice service is currently unavailable.'));
    expect(state.errorMessage, contains('Local guidance:'));
  });

  test('senior companion stores deterministic local response text', () async {
    final recordingPath = await _createWavFile(seconds: 4);
    addTearDown(() => File(recordingPath).delete());

    final repository = _FakeVoiceCompanionRepository(
      responseTextToReturn:
          'QA local fallback response. Hydration looks good today.',
    );
    final recorder = _FakeVoiceRecordingService(recordingPath);
    final playback = _FakeVoicePlaybackService();
    final container = ProviderContainer(
      overrides: [
        voiceCompanionRepositoryProvider.overrideWithValue(repository),
        voiceGatewayConfiguredProvider.overrideWithValue(true),
        voiceRecordingServiceProvider.overrideWithValue(recorder),
        voicePlaybackServiceProvider.overrideWithValue(playback),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(seniorCompanionControllerProvider.notifier);
    await notifier.startListening();
    await notifier.stopAndSend();

    final state = container.read(seniorCompanionControllerProvider);
    expect(state.status, VoiceInteractionStatus.idle);
    expect(
      state.lastResponseText,
      'QA local fallback response. Hydration looks good today.',
    );
  });
}
