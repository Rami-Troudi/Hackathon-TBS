import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/features/medication/medication_providers.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class MedicationScreen extends ConsumerWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationAsync = ref.watch(medicationDataProvider);
    return AppScaffoldShell(
      title: 'Medication',
      role: AppShellRole.senior,
      child: medicationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load medications: $error')),
        data: (data) {
          final seniorId = data.seniorId;
          if (seniorId == null) {
            return const Center(child: Text('No active senior context found.'));
          }

          return ListView(
            children: [
              Text(
                'Today\'s reminders',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v8,
              if (data.reminders.isEmpty)
                Text(
                  'No medication plans configured for today.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.reminders.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _MedicationReminderCard(
                      reminder: reminder,
                      onTaken: () => _markTaken(
                        context,
                        ref,
                        seniorId: seniorId,
                        planId: reminder.plan.id,
                      ),
                      onMissed: () => _markMissed(
                        context,
                        ref,
                        seniorId: seniorId,
                        planId: reminder.plan.id,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markTaken(
    BuildContext context,
    WidgetRef ref, {
    required String seniorId,
    required String planId,
  }) async {
    final created =
        await ref.read(medicationRepositoryProvider).markMedicationTaken(
              seniorId,
              planId: planId,
            );
    ref.invalidate(medicationDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(created
            ? 'Medication confirmed as taken'
            : 'Already confirmed today'),
      ),
    );
  }

  Future<void> _markMissed(
    BuildContext context,
    WidgetRef ref, {
    required String seniorId,
    required String planId,
  }) async {
    final created =
        await ref.read(medicationRepositoryProvider).markMedicationMissed(
              seniorId,
              planId: planId,
            );
    ref.invalidate(medicationDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(created
            ? 'Medication marked as skipped/missed'
            : 'Already marked missed today'),
      ),
    );
  }
}

class _MedicationReminderCard extends StatelessWidget {
  const _MedicationReminderCard({
    required this.reminder,
    required this.onTaken,
    required this.onMissed,
  });

  final MedicationReminder reminder;
  final VoidCallback onTaken;
  final VoidCallback onMissed;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (reminder.status) {
      MedicationReminderStatus.pending => 'Pending',
      MedicationReminderStatus.taken => 'Taken',
      MedicationReminderStatus.missed => 'Missed',
    };
    final statusColor = switch (reminder.status) {
      MedicationReminderStatus.pending => Theme.of(context).colorScheme.primary,
      MedicationReminderStatus.taken =>
        Theme.of(context).extension<AppStatusColors>()?.ok ?? Colors.green,
      MedicationReminderStatus.missed =>
        Theme.of(context).extension<AppStatusColors>()?.watch ?? Colors.orange,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reminder.plan.medicationName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Gaps.v4,
          Text(
            '${reminder.plan.dosageLabel} • ${reminder.slotLabel}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (reminder.plan.note != null) ...[
            Gaps.v4,
            Text(
              reminder.plan.note!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          Gaps.v8,
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: statusColor,
                ),
          ),
          Gaps.v12,
          if (reminder.status == MedicationReminderStatus.pending) ...[
            FilledButton(
              onPressed: onTaken,
              child: const Text('Taken'),
            ),
            Gaps.v8,
            OutlinedButton(
              onPressed: onMissed,
              child: const Text('Skip for now'),
            ),
          ] else
            Text(
              'Recorded at ${_formatTime(reminder.resolvedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '--:--';
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
