import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
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
  final TextEditingController _questionController = TextEditingController();

  static const List<String> _suggestions = <String>[
    'What changed today?',
    'What needs attention right now?',
    'Summarize medication today.',
    'Summarize hydration and meals.',
    'Any incident or location concern?',
    'Give me a short daily recap.',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _send(String question) async {
    final text = question.trim();
    if (text.isEmpty) return;
    _questionController.clear();
    await ref.read(guardianInsightsControllerProvider.notifier).ask(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guardianInsightsControllerProvider);
    return AppScaffoldShell(
      title: 'Insights',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianInsights,
      child: ListView(
        children: [
          AppCard(
            tone: AppCardTone.sage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guardian Assistant',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Gaps.v8,
                Text(
                  'Ask about alerts, adherence, incidents, location, and summaries. Answers stay grounded in local deterministic data.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          Gaps.v16,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: state.isBusy ? null : () => _send(suggestion),
                  ),
                )
                .toList(),
          ),
          Gaps.v16,
          ...state.messages.map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Align(
                alignment: message.fromGuardian
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.84,
                  child: AppCard(
                    tone: message.fromGuardian
                        ? AppCardTone.clay
                        : AppCardTone.surface,
                    child: Text(message.text),
                  ),
                ),
              ),
            ),
          ),
          if (state.isBusy) ...[
            Gaps.v8,
            const Center(child: CircularProgressIndicator()),
          ],
          if (state.errorMessage != null) ...[
            Gaps.v8,
            Text(
              'Assistant warning: ${state.errorMessage}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
          Gaps.v12,
          TextField(
            controller: _questionController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: state.isBusy ? null : _send,
            decoration: const InputDecoration(
              labelText: 'Ask a grounded question',
              hintText: 'Example: What needs attention right now?',
            ),
          ),
          Gaps.v8,
          FilledButton.icon(
            onPressed:
                state.isBusy ? null : () => _send(_questionController.text),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
