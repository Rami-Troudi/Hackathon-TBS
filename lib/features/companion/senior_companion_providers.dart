import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';

class SeniorCompanionState {
  const SeniorCompanionState({
    required this.status,
    this.lastRequestPath,
    this.lastResponsePath,
    this.errorMessage,
  });

  final VoiceInteractionStatus status;
  final String? lastRequestPath;
  final String? lastResponsePath;
  final String? errorMessage;

  bool get isBusy =>
      status == VoiceInteractionStatus.listening ||
      status == VoiceInteractionStatus.processing ||
      status == VoiceInteractionStatus.playing;

  SeniorCompanionState copyWith({
    VoiceInteractionStatus? status,
    String? lastRequestPath,
    String? lastResponsePath,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SeniorCompanionState(
      status: status ?? this.status,
      lastRequestPath: lastRequestPath ?? this.lastRequestPath,
      lastResponsePath: lastResponsePath ?? this.lastResponsePath,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory SeniorCompanionState.initial({required bool gatewayConfigured}) {
    return SeniorCompanionState(
      status: gatewayConfigured
          ? VoiceInteractionStatus.idle
          : VoiceInteractionStatus.unavailable,
    );
  }
}

class SeniorCompanionController extends StateNotifier<SeniorCompanionState> {
  SeniorCompanionController({
    required this.ref,
  }) : super(
          SeniorCompanionState.initial(
            gatewayConfigured: ref.read(voiceGatewayConfiguredProvider),
          ),
        );

  final Ref ref;

  Future<void> startListening() async {
    if (state.isBusy) return;
    if (!ref.read(voiceGatewayConfiguredProvider)) {
      state = state.copyWith(
        status: VoiceInteractionStatus.unavailable,
        errorMessage: 'Voice gateway is not configured.',
      );
      return;
    }

    final recorder = ref.read(voiceRecordingServiceProvider);
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(
        status: VoiceInteractionStatus.error,
        errorMessage: 'Microphone permission is required for voice companion.',
      );
      return;
    }

    try {
      final path = await recorder.start();
      state = state.copyWith(
        status: VoiceInteractionStatus.listening,
        lastRequestPath: path,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceInteractionStatus.error,
        errorMessage: 'Could not start recording: $error',
      );
    }
  }

  Future<void> stopAndSend() async {
    if (state.status != VoiceInteractionStatus.listening) return;
    final recorder = ref.read(voiceRecordingServiceProvider);
    state = state.copyWith(status: VoiceInteractionStatus.processing);

    try {
      final audioPath = await recorder.stop();
      if (audioPath == null || audioPath.isEmpty) {
        state = state.copyWith(
          status: VoiceInteractionStatus.error,
          errorMessage: 'No recorded audio was captured.',
        );
        return;
      }

      final result = await ref
          .read(voiceCompanionRepositoryProvider)
          .askSeniorWithAudio(audioPath);
      state = state.copyWith(
        status: VoiceInteractionStatus.playing,
        lastRequestPath: audioPath,
        lastResponsePath: result.responseAudioPath,
        clearError: true,
      );
      await ref
          .read(voicePlaybackServiceProvider)
          .playFile(result.responseAudioPath);
      state = state.copyWith(status: VoiceInteractionStatus.idle);
    } catch (error) {
      state = state.copyWith(
        status: VoiceInteractionStatus.error,
        errorMessage: 'Voice companion failed: $error',
      );
    }
  }

  Future<void> replayLastResponse() async {
    final path = state.lastResponsePath;
    if (path == null || state.isBusy) return;

    try {
      state = state.copyWith(status: VoiceInteractionStatus.playing);
      await ref.read(voicePlaybackServiceProvider).playFile(path);
      state = state.copyWith(status: VoiceInteractionStatus.idle);
    } catch (error) {
      state = state.copyWith(
        status: VoiceInteractionStatus.error,
        errorMessage: 'Could not replay response: $error',
      );
    }
  }

  Future<void> cancel() async {
    final recorder = ref.read(voiceRecordingServiceProvider);
    final playback = ref.read(voicePlaybackServiceProvider);
    if (await recorder.isRecording()) {
      await recorder.stop();
    }
    await playback.stop();
    state = state.copyWith(status: VoiceInteractionStatus.idle);
  }
}

final seniorCompanionControllerProvider = StateNotifierProvider.autoDispose<
    SeniorCompanionController, SeniorCompanionState>(
  (ref) => SeniorCompanionController(ref: ref),
);
