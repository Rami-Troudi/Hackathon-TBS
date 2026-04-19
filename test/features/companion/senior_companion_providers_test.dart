import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/voice/voice_companion_repository.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';
import 'package:senior_companion/core/voice/voice_playback_service.dart';
import 'package:senior_companion/core/voice/voice_recording_service.dart';
import 'package:senior_companion/features/companion/senior_companion_providers.dart';

class _FakeVoiceCompanionRepository implements VoiceCompanionRepository {
  int calls = 0;
  String? receivedPath;

  @override
  bool get isConfigured => true;

  @override
  Future<VoiceInteractionResult> askSeniorWithAudio(
    String audioFilePath,
  ) async {
    calls += 1;
    receivedPath = audioFilePath;
    return const VoiceInteractionResult(
      responseAudioPath: '/tmp/voice-response.wav',
    );
  }
}

class _FakeVoiceRecordingService implements VoiceRecordingService {
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
    return '/tmp/voice-request.wav';
  }

  @override
  Future<String?> stop() async {
    recording = false;
    return '/tmp/voice-request.wav';
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

void main() {
  test('senior companion records audio, sends it, and plays response',
      () async {
    final repository = _FakeVoiceCompanionRepository();
    final recorder = _FakeVoiceRecordingService();
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
    expect(state.lastRequestPath, '/tmp/voice-request.wav');
    expect(state.lastResponsePath, '/tmp/voice-response.wav');
    expect(repository.calls, 1);
    expect(repository.receivedPath, '/tmp/voice-request.wav');
    expect(playback.playedPath, '/tmp/voice-response.wav');
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
}
