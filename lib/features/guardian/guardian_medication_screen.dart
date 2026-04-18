import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_medication_providers.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianMedicationScreen extends ConsumerWidget {
  const GuardianMedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringAsync = ref.watch(guardianMedicationMonitoringDataProvider);

    return AppScaffoldShell(
      title: 'Medication Monitoring',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianAlerts),
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: 'Alerts',
        ),
      ],
      child: monitoringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load medication: $error')),
        data: (data) {
          if (data.seniorId == null) {
            return const Center(
                child: Text('No linked senior for medication.'));
          }

          return ListView(
            children: [
              Text(
                data.seniorProfile?.displayName ?? data.seniorId!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v16,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Gaps.v8,
                      Text(
                        'Taken ${data.takenToday} • Missed ${data.missedToday} • Pending ${data.pendingToday}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Gaps.v4,
                      Text(
                        '7-day adherence: ${data.adherenceRateLast7Days.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.v16,
              Text(
                'Medication plans',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gaps.v8,
              if (data.plans.isEmpty)
                Text(
                  'No active medication plans.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.medication_outlined),
                        title: Text(plan.medicationName),
                        subtitle: Text(
                          '${plan.dosageLabel} • ${plan.scheduledTimes.join(', ')}',
                        ),
                      ),
                    ),
                  ),
                ),
              Gaps.v16,
              Text(
                'Today reminders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gaps.v8,
              if (data.todayReminders.isEmpty)
                Text(
                  'No reminders for today.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.todayReminders.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReminderTile(reminder: reminder),
                  ),
                ),
              Gaps.v16,
              Text(
                'Recent medication activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gaps.v8,
              if (data.recentMedicationEvents.isEmpty)
                Text(
                  'No recent medication events.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.recentMedicationEvents.take(8).map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Card(
                          child: ListTile(
                            leading: Icon(iconForEventType(event.type)),
                            title: Text(event.type.timelineLabel),
                            subtitle: Text(
                              '${formatLocalDay(event.happenedAt)} ${formatLocalTime(event.happenedAt)} • ${formatEventDetail(event)}',
                            ),
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
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
  });

  final MedicationReminder reminder;

  @override
  Widget build(BuildContext context) {
    final label = switch (reminder.status) {
      MedicationReminderStatus.pending => 'Pending',
      MedicationReminderStatus.taken => 'Taken',
      MedicationReminderStatus.missed => 'Missed',
    };

    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule_outlined),
        title: Text('${reminder.plan.medicationName} • ${reminder.slotLabel}'),
        subtitle: Text(
          '$label${reminder.resolvedAt == null ? '' : ' at ${formatLocalTime(reminder.resolvedAt!)}'}',
        ),
      ),
    );
  }
}
