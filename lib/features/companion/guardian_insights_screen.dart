import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/assistant_message.dart';
import 'package:senior_companion/shared/models/assistant_role.dart';
import 'package:senior_companion/shared/models/assistant_suggestion.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

import 'guardian_insights_providers.dart';

class GuardianInsightsScreen extends ConsumerStatefulWidget {
  const GuardianInsightsScreen({super.key});

  @override
  ConsumerState<GuardianInsightsScreen> createState() =>
      _GuardianInsightsScreenState();
}

class _GuardianInsightsScreenState
    extends ConsumerState<GuardianInsightsScreen> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guardianInsightsControllerProvider.notifier).ensureInitialized();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guardianInsightsControllerProvider);
    final controller = ref.read(guardianInsightsControllerProvider.notifier);

    return AppScaffoldShell(
      title: 'AI Insights',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianInsights,
      child: Column(
        children: [
          const AppCard(
            tone: AppCardTone.surface,
            child: Text(
              'Grounded insights from local alerts, timeline, status, and summaries.',
            ),
          ),
          Gaps.v12,
          Expanded(
            child: ListView.builder(
              itemCount: state.messages.length + (state.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ThinkingBubble(),
                  );
                }
                final message = state.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ChatMessageBubble(
                    message: message,
                    onSuggestionTap: (suggestion) async {
                      await controller.sendSuggestion(suggestion);
                    },
                  ),
                );
              },
            ),
          ),
          Gaps.v8,
          _SuggestionRow(
            suggestions: state.suggestions,
            onTap: (suggestion) async {
              await controller.sendSuggestion(suggestion);
            },
          ),
          Gaps.v8,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Ask for grounded insights...',
                  ),
                  onSubmitted: (_) => _submit(controller),
                ),
              ),
              Gaps.h8,
              FilledButton(
                onPressed: state.isSending ? null : () => _submit(controller),
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit(GuardianInsightsController controller) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await controller.sendText(text);
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.onSuggestionTap,
  });

  final AssistantMessage message;
  final Future<void> Function(AssistantSuggestion suggestion) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.role == AssistantRole.assistant;
    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AppCard(
          tone: isAssistant ? AppCardTone.surface : AppCardTone.sage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.text),
              if (isAssistant && message.referencedFacts.isNotEmpty) ...[
                Gaps.v8,
                Text(
                  'Evidence: ${message.referencedFacts.take(3).join(' • ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (isAssistant &&
                  message.suggestions
                      .any((suggestion) => suggestion.routeHint != null))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: message.suggestions
                        .where((suggestion) => suggestion.routeHint != null)
                        .take(3)
                        .map(
                          (suggestion) => TextButton(
                            onPressed: () =>
                                context.push(suggestion.routeHint!),
                            child: Text('Open ${suggestion.label}'),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              if (isAssistant && message.suggestions.isNotEmpty) ...[
                Gaps.v8,
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: message.suggestions.take(3).map((suggestion) {
                    return ActionChip(
                      label: Text(suggestion.label),
                      onPressed: () => onSuggestionTap(suggestion),
                    );
                  }).toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestions,
    required this.onTap,
  });

  final List<AssistantSuggestion> suggestions;
  final Future<void> Function(AssistantSuggestion suggestion) onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.take(6).map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilledButton.tonal(
                onPressed: () => onTap(suggestion),
                child: Text(suggestion.label),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: AppCard(
        child: Text('Generating grounded insight...'),
      ),
    );
  }
}
