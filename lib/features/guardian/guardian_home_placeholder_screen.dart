import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianHomePlaceholderScreen extends ConsumerWidget {
  const GuardianHomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(guardianHomeDataProvider);

    return AppScaffoldShell(
      title: 'Guardian Home',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.home),
          icon: const Icon(Icons.developer_mode_outlined),
          tooltip: 'Developer Hub',
        ),
      ],
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load guardian summary: $error'),
        ),
        data: (data) => ListView(
          children: [
            Text(
              'Guardian Monitoring Snapshot',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Gaps.v4,
            Text(
              data.activeSeniorId == null
                  ? 'No linked senior in current session.'
                  : 'Tracking senior: ${data.activeSeniorId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v16,
            _StatusCard(summary: data.dashboardSummary),
            Gaps.v16,
            _RecentTimelineCard(events: data.recentEvents),
            Gaps.v16,
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.home),
              icon: const Icon(Icons.developer_mode_outlined),
              label: const Text('Open Developer Hub (Generate Events)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.summary});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Gaps.h8,
                Text(
                  summary.globalStatus.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            Gaps.v4,
            Text(
              summary.globalStatus.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v16,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                _MetricChip(
                  label: 'Alerts',
                  value: summary.pendingAlerts,
                  highlight: summary.pendingAlerts > 0,
                ),
                _MetricChip(label: 'Check-ins', value: summary.todayCheckIns),
                _MetricChip(
                  label: 'Missed meds',
                  value: summary.missedMedications,
                  highlight: summary.missedMedications > 0,
                ),
                _MetricChip(
                  label: 'Incidents',
                  value: summary.openIncidents,
                  highlight: summary.openIncidents > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}

class _RecentTimelineCard extends StatelessWidget {
  const _RecentTimelineCard({required this.events});

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
              'Recent timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v8,
            if (events.isEmpty)
              Text(
                'No persisted events yet.',
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
