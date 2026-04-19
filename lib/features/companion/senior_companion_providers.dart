import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/voice/voice_companion_repository.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';
import 'package:senior_companion/core/voice/voice_gateway_client.dart';
import 'package:senior_companion/core/voice/voice_playback_service.dart';
import 'package:senior_companion/core/voice/voice_recording_service.dart';

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
  DateTime? _listeningStartedAt;
  String? _activeRecordingPath;

  static const Duration _minRecordingDuration = Duration(seconds: 3);
  static const int _wavHeaderBytes = 44;
  static const int _pcm16Mono16kBytesPerSecond = 32000;
  static const int _minRecordingBytes = _pcm16Mono16kBytesPerSecond * 3;

  VoiceRecordingService get _recorder =>
      ref.read(voiceRecordingServiceProvider);
  VoicePlaybackService get _playback => ref.read(voicePlaybackServiceProvider);
  VoiceCompanionRepository get _voiceRepository =>
      ref.read(voiceCompanionRepositoryProvider);

  Future<void> startListening() async {
    if (state.isBusy) return;
    if (!ref.read(voiceGatewayConfiguredProvider)) {
      state = state.copyWith(
        status: VoiceInteractionStatus.unavailable,
        errorMessage: 'Voice gateway is not configured.',
      );
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(
        status: VoiceInteractionStatus.error,
        errorMessage: 'Microphone permission is required for voice companion.',
      );
      return;
    }

    try {
      final path = await _recorder.start();
      _activeRecordingPath = path;
      _listeningStartedAt = DateTime.now();
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
    state = state.copyWith(status: VoiceInteractionStatus.processing);

    try {
      final stoppedPath = await _recorder.stop();
      final audioPath = stoppedPath ?? _activeRecordingPath;
      _activeRecordingPath = null;
      if (audioPath == null || audioPath.isEmpty) {
        await _setErrorWithFallback('No recorded audio was captured.');
        return;
      }

      final validationError = await _validateCapture(audioPath);
      _listeningStartedAt = null;
      if (validationError != null) {
        await _setErrorWithFallback(validationError);
        return;
      }

      final result = await _voiceRepository.askSeniorWithAudio(audioPath);
      if (!mounted) return;
      state = state.copyWith(
        status: VoiceInteractionStatus.playing,
        lastRequestPath: audioPath,
        lastResponsePath: result.responseAudioPath,
        clearError: true,
      );
      await _playback.playFile(result.responseAudioPath);
      if (!mounted) return;
      state = state.copyWith(status: VoiceInteractionStatus.idle);
    } catch (error) {
      _listeningStartedAt = null;
      if (error is VoiceGatewayException) {
        final guidance = await _buildLocalFallbackGuidance();
        if (!mounted) return;
        state = state.copyWith(
          status: VoiceInteractionStatus.error,
          errorMessage: '${_gatewayErrorMessage(error)}\n$guidance',
        );
        return;
      }

      await _setErrorWithFallback('Voice companion failed: $error');
    }
  }

  Future<void> replayLastResponse() async {
    final path = state.lastResponsePath;
    if (path == null || state.isBusy) return;

    try {
      state = state.copyWith(status: VoiceInteractionStatus.playing);
      await _playback.playFile(path);
      state = state.copyWith(status: VoiceInteractionStatus.idle);
    } catch (error) {
      state = state.copyWith(
        status: VoiceInteractionStatus.error,
        errorMessage: 'Could not replay response: $error',
      );
    }
  }

  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _activeRecordingPath = null;
    _listeningStartedAt = null;
    await _playback.stop();
    state = state.copyWith(status: VoiceInteractionStatus.idle);
  }

  Future<String?> _validateCapture(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      return 'The recording could not be found. Please try again.';
    }

    final length = await file.length();
    if (length <= _wavHeaderBytes) {
      return 'No voice was captured. Please hold the button and speak clearly.';
    }

    final payloadBytes = length - _wavHeaderBytes;
    final fileDuration = Duration(
      milliseconds:
          ((payloadBytes / _pcm16Mono16kBytesPerSecond) * 1000).round(),
    );
    final elapsed = _listeningStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_listeningStartedAt!);
    final effectiveDuration = elapsed > fileDuration ? elapsed : fileDuration;

    if (effectiveDuration < _minRecordingDuration ||
        length < _minRecordingBytes) {
      return 'Recording too short. Please speak for at least 3 seconds before sending.';
    }

    return null;
  }

  Future<void> _setErrorWithFallback(String baseMessage) async {
    final guidance = await _buildLocalFallbackGuidance();
    if (!mounted) return;
    state = state.copyWith(
      status: VoiceInteractionStatus.error,
      errorMessage: '$baseMessage\n$guidance',
    );
  }

  Future<String> _buildLocalFallbackGuidance() async {
    try {
      final context =
          await ref.read(aiContextBuilderProvider).buildSeniorContext();
      final actions = <String>[];
      if (context.activeAlerts.isNotEmpty) {
        actions.add('Check active alerts from the guardian dashboard.');
      }
      final nextReminder = context.nextReminder;
      if (nextReminder != null) {
        actions.add('Next medication reminder: ${nextReminder.slotLabel}.');
      }
      if (actions.isEmpty) {
        actions.add('Open Daily Summary to review today\'s guidance.');
      }
      return 'Local guidance: ${context.summary.headline} ${actions.join(' ')}';
    } catch (_) {
      return 'Local guidance: Open Daily Summary and Alerts for deterministic status details.';
    }
  }

  String _gatewayErrorMessage(VoiceGatewayException error) {
    final detail = (error.detail ?? '').trim();
    return switch (error.kind) {
      VoiceGatewayErrorKind.badRequest => detail.isEmpty
          ? 'Voice request was rejected.'
          : 'Voice request was rejected: $detail',
      VoiceGatewayErrorKind.timeout => 'Voice service timed out.',
      VoiceGatewayErrorKind.network => 'Could not reach the voice service.',
      VoiceGatewayErrorKind.unauthorized =>
        'Voice service authorization failed.',
      VoiceGatewayErrorKind.server => 'Voice service is currently unavailable.',
      VoiceGatewayErrorKind.invalidResponse =>
        'Voice service returned an invalid response.',
      VoiceGatewayErrorKind.unknown => 'Voice service request failed.',
    };
  }
}

final seniorCompanionControllerProvider =
    StateNotifierProvider<SeniorCompanionController, SeniorCompanionState>(
  (ref) => SeniorCompanionController(ref: ref),
);
