import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/core/voice/voice_interaction.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

import 'senior_companion_providers.dart';

class SeniorCompanionScreen extends ConsumerWidget {
  const SeniorCompanionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seniorCompanionControllerProvider);
    final controller = ref.read(seniorCompanionControllerProvider.notifier);
    final isListening = state.status == VoiceInteractionStatus.listening;

    return AppScaffoldShell(
      title: 'Voice Companion',
      role: AppShellRole.senior,
      child: ListView(
        children: [
          AppCard(
            tone: state.status == VoiceInteractionStatus.error
                ? AppCardTone.warning
                : AppCardTone.sage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headlineFor(state.status),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Gaps.v8,
                Text(
                  _descriptionFor(state.status),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (state.errorMessage != null) ...[
                  Gaps.v12,
                  Text(
                    state.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Gaps.v24,
          BigAction(
            label: isListening ? 'Stop and send' : 'Talk to Companion',
            subtitle: isListening
                ? 'Send your voice question'
                : 'Ask by voice in Tunisian Arabic or simple language',
            icon: isListening ? Icons.stop_circle_outlined : Icons.mic_outlined,
            tone:
                isListening ? BigActionTone.destructive : BigActionTone.primary,
            onTap: isListening
                ? controller.stopAndSend
                : controller.startListening,
          ),
          Gaps.v12,
          if (state.isBusy && !isListening)
            const Center(child: CircularProgressIndicator()),
          if (state.lastResponsePath != null) ...[
            Gaps.v12,
            BigAction(
              label: 'Replay answer',
              subtitle: 'Play the last voice response again',
              icon: Icons.replay_outlined,
              tone: BigActionTone.soft,
              onTap: state.isBusy ? null : controller.replayLastResponse,
            ),
          ],
          if (state.lastResponseText != null) ...[
            Gaps.v12,
            AppCard(
              child: Text(state.lastResponseText!),
            ),
          ],
          Gaps.v16,
          OutlinedButton.icon(
            onPressed: state.isBusy ? controller.cancel : null,
            icon: const Icon(Icons.close_outlined),
            label: const Text('Cancel'),
          ),
          Gaps.v24,
          const AppCard(
            child: Text(
              'Local fallback is active by default for reliable demos. To test the external gateway, set VOICE_GATEWAY_MODE=gateway (and VOICE_GATEWAY_BASE_URL if needed). App data remains local source of truth.',
            ),
          ),
        ],
      ),
    );
  }

  String _headlineFor(VoiceInteractionStatus status) {
    return switch (status) {
      VoiceInteractionStatus.idle => 'Ask by voice',
      VoiceInteractionStatus.listening => 'Listening...',
      VoiceInteractionStatus.processing => 'Understanding...',
      VoiceInteractionStatus.playing => 'Answering...',
      VoiceInteractionStatus.unavailable => 'Voice companion unavailable',
      VoiceInteractionStatus.error => 'Voice companion needs attention',
    };
  }

  String _descriptionFor(VoiceInteractionStatus status) {
    return switch (status) {
      VoiceInteractionStatus.idle =>
        'Tap the microphone, speak for at least 3 seconds, then send it.',
      VoiceInteractionStatus.listening =>
        'Speak clearly. Tap stop when you are done.',
      VoiceInteractionStatus.processing =>
        'Your question is being processed by the voice assistant.',
      VoiceInteractionStatus.playing => 'Playing the assistant response.',
      VoiceInteractionStatus.unavailable =>
        'Local fallback is the default mode. To use the external gateway, set VOICE_GATEWAY_MODE=gateway and configure VOICE_GATEWAY_BASE_URL.',
      VoiceInteractionStatus.error =>
        'Check microphone permission, network access, or gateway availability.',
    };
  }
}
