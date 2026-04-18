import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/features/summary/summary_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/daily_summary.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class SeniorSummaryScreen extends ConsumerWidget {
  const SeniorSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(seniorSummaryDataProvider);
    return AppScaffoldShell(
      title: 'Daily summary',
      role: AppShellRole.senior,
      child: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load summary: $error')),
        data: (data) => _SummaryView(summary: data.summary),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              summary.headline,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Gaps.v16,
        _SummarySection(
          title: 'Going well',
          items: summary.whatWentWell,
          emptyLabel: 'No positive highlights yet.',
        ),
        Gaps.v16,
        _SummarySection(
          title: 'Needs attention',
          items: summary.needsAttention,
          emptyLabel: 'Nothing urgent right now.',
        ),
        Gaps.v16,
        _SummarySection(
          title: 'Notable events',
          items: summary.notableEvents,
          emptyLabel: 'No notable events yet.',
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Gaps.v8,
            if (items.isEmpty)
              Text(emptyLabel)
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
