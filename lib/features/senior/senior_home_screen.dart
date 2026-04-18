import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class SeniorHomeScreen extends ConsumerWidget {
  const SeniorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorHomeAsync = ref.watch(seniorHomeDataProvider);

    return AppScaffoldShell(
      title: 'Senior Home',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.home),
          icon: const Icon(Icons.developer_mode_outlined),
          tooltip: 'Developer Hub',
        ),
      ],
      child: seniorHomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load senior home: $error')),
        data: (data) => _SeniorHomeContent(data: data),
      ),
    );
  }
}

class _SeniorHomeContent extends ConsumerWidget {
  const _SeniorHomeContent({
    required this.data,
  });

  final SeniorHomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorId = data.activeSeniorId;
    if (seniorId == null) {
      return const Center(
        child: Text(
            'No active senior context. Switch to a senior profile in Settings.'),
      );
    }

    return ListView(
      children: [
        Text(
          'Hello, ${data.profile?.displayName ?? 'there'}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Gaps.v4,
        Text(
          'Today\'s support in one place.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Gaps.v16,
        _StatusCard(summary: data.summary),
        Gaps.v16,
        _PrimaryActionCard(
          checkInState: data.checkInState,
          onPrimaryAction: () => _completeCheckIn(context, ref, seniorId),
          onHelpAction: () => _needHelp(context, ref, seniorId),
        ),
        Gaps.v16,
        _NextReminderCard(reminder: data.nextReminder),
        Gaps.v16,
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.checkIn),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Open Check-in'),
        ),
        Gaps.v8,
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.medication),
          icon: const Icon(Icons.medication_outlined),
          label: const Text('Open Medication'),
        ),
        Gaps.v8,
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.incident),
          icon: const Icon(Icons.warning_amber_outlined),
          label: const Text('Open Help & Incident'),
        ),
        Gaps.v16,
        _RecentActivityCard(events: data.recentEvents),
      ],
    );
  }

  Future<void> _completeCheckIn(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    final created = await ref
        .read(checkInRepositoryProvider)
        .markCheckInCompleted(seniorId);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Check-in completed'
              : 'Today\'s check-in was already completed',
        ),
      ),
    );
  }

  Future<void> _needHelp(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    await ref.read(checkInRepositoryProvider).markNeedHelp(seniorId);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Help request recorded. Support has been alerted.')),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<AppStatusColors>();
    final statusColor = switch (summary.globalStatus) {
      SeniorGlobalStatus.ok => statusColors?.ok ?? Colors.green,
      SeniorGlobalStatus.watch => statusColors?.watch ?? Colors.orange,
      SeniorGlobalStatus.actionRequired =>
        statusColors?.actionRequired ?? Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            Gaps.h8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.globalStatus.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    summary.globalStatus.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.checkInState,
    required this.onPrimaryAction,
    required this.onHelpAction,
  });

  final CheckInState checkInState;
  final VoidCallback onPrimaryAction;
  final VoidCallback onHelpAction;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (checkInState.status) {
      CheckInStatus.completed =>
        'Completed at ${_formatTime(checkInState.completedAt)}',
      CheckInStatus.missed =>
        'Missed ${checkInState.windowLabel}. You can still check in now.',
      CheckInStatus.pending =>
        'Pending in ${checkInState.windowLabel}. Please confirm your status.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Primary daily action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v4,
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v16,
            FilledButton(
              onPressed: onPrimaryAction,
              child: const Text('I\'m okay'),
            ),
            Gaps.v8,
            OutlinedButton(
              onPressed: onHelpAction,
              child: const Text('I need help'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return 'just now';
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({
    required this.reminder,
  });

  final MedicationReminder? reminder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next reminder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v4,
            if (reminder == null)
              Text(
                'No pending reminders right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                '${reminder!.plan.medicationName} (${reminder!.plan.dosageLabel}) at ${reminder!.slotLabel}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.events,
  });

  final List<PersistedEventRecord> events;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v8,
            if (events.isEmpty)
              Text(
                'No recent events yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '${event.type.timelineLabel} • ${_formatTime(event.happenedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
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
