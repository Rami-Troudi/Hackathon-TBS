import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/features/nutrition/nutrition_providers.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(seniorNutritionDataProvider);
    return AppScaffoldShell(
      title: 'Nutrition',
      role: AppShellRole.senior,
      child: nutritionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load nutrition: $error')),
        data: (data) {
          final seniorId = data.seniorId;
          if (seniorId == null) {
            return const Center(child: Text('No active senior context found.'));
          }
          return ListView(
            children: [
              Text(
                'Meal routine for today',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v8,
              AppCard(
                tone: AppCardTone.clay,
                child: Text(
                  'Completed ${data.state.completedCount}/${data.state.slots.length} • Missed ${data.state.missedCount} • Pending ${data.state.pendingCount}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Gaps.v16,
              ...data.state.slots.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _MealCard(
                    meal: slot,
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
    String mealId,
  ) async {
    final created =
        await ref.read(nutritionRepositoryProvider).markMealCompleted(
              seniorId,
              mealId: mealId,
            );
    ref.invalidate(seniorNutritionDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(created ? 'Meal confirmed' : 'This meal is already recorded'),
      ),
    );
  }

  Future<void> _markMissed(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
    String mealId,
  ) async {
    final created = await ref.read(nutritionRepositoryProvider).markMealMissed(
          seniorId,
          mealId: mealId,
        );
    ref.invalidate(seniorNutritionDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(created
            ? 'Meal marked as skipped'
            : 'This meal is already recorded'),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.onDone,
    required this.onSkip,
  });

  final MealSlotState meal;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (meal.status) {
      MealSlotStatus.pending => 'Pending',
      MealSlotStatus.completed => 'Completed',
      MealSlotStatus.missed => 'Missed',
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meal.mealLabel, style: Theme.of(context).textTheme.titleLarge),
          Gaps.v4,
          Text(
            'Time ${_formatTime(meal.scheduledAt)} • $statusLabel',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Gaps.v12,
          if (meal.status == MealSlotStatus.pending) ...[
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
              'Recorded at ${_formatTime(meal.resolvedAt ?? meal.scheduledAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
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
