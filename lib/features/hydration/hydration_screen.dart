import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/features/hydration/hydration_providers.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydrationAsync = ref.watch(seniorHydrationDataProvider);
    return AppScaffoldShell(
      title: 'Hydration',
      child: hydrationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load hydration: $error')),
        data: (data) {
          final seniorId = data.seniorId;
          if (seniorId == null) {
            return const Center(child: Text('No active senior context found.'));
          }
          return ListView(
            children: [
              Text(
                'Stay hydrated today',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Completed ${data.state.completedCount}/${data.state.dailyGoalCompletions} • Missed ${data.state.missedCount} • Pending ${data.state.pendingCount}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              Gaps.v16,
              ...data.state.slots.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _HydrationSlotCard(
                    slot: slot,
                    onDone: () => _markDone(context, ref, seniorId, slot.id),
                    onSkip: () => _markMissed(context, ref, seniorId, slot.id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markDone(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
    String slotId,
  ) async {
    final created =
        await ref.read(hydrationRepositoryProvider).markHydrationCompleted(
              seniorId,
              slotId: slotId,
            );
    ref.invalidate(seniorHydrationDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(created
            ? 'Hydration confirmed'
            : 'This hydration slot is already recorded'),
      ),
    );
  }

  Future<void> _markMissed(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
    String slotId,
  ) async {
    final created =
        await ref.read(hydrationRepositoryProvider).markHydrationMissed(
              seniorId,
              slotId: slotId,
            );
    ref.invalidate(seniorHydrationDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(created
            ? 'Hydration marked as skipped'
            : 'This hydration slot is already recorded'),
      ),
    );
  }
}

class _HydrationSlotCard extends StatelessWidget {
  const _HydrationSlotCard({
    required this.slot,
    required this.onDone,
    required this.onSkip,
  });

  final HydrationSlotState slot;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (slot.status) {
      HydrationSlotStatus.pending => 'Pending',
      HydrationSlotStatus.completed => 'Completed',
      HydrationSlotStatus.missed => 'Missed',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(slot.label, style: Theme.of(context).textTheme.titleLarge),
            Gaps.v4,
            Text(
              'Time ${_formatTime(slot.scheduledAt)} • $statusLabel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v8,
            if (slot.status == HydrationSlotStatus.pending) ...[
              FilledButton(
                onPressed: onDone,
                child: const Text('Done'),
              ),
              Gaps.v8,
              OutlinedButton(
                onPressed: onSkip,
                child: const Text('Skip'),
              ),
            ] else
              Text(
                'Recorded at ${_formatTime(slot.resolvedAt ?? slot.scheduledAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
