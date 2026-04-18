import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_check_in_providers.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianCheckInScreen extends ConsumerWidget {
  const GuardianCheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringAsync = ref.watch(guardianCheckInMonitoringDataProvider);

    return AppScaffoldShell(
      title: 'Check-in Monitoring',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianCheckIns,
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
            Center(child: Text('Could not load check-ins: $error')),
        data: (data) {
          if (data.seniorId == null) {
            return const Center(child: Text('No linked senior for check-ins.'));
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
                        _todayLabel(data.todayState),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Gaps.v4,
                      Text(
                        'Window ${formatLocalTime(data.todayState.windowStart)} - ${formatLocalTime(data.todayState.windowEnd)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Last 7 days: ${data.completedInLast7Days} completed • ${data.missedInLast7Days} missed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Gaps.v16,
              Text(
                'Recent check-in history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gaps.v8,
              if (data.recentCheckInEvents.isEmpty)
                Text(
                  'No check-in events available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.recentCheckInEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Card(
                      child: ListTile(
                        leading: Icon(iconForEventType(event.type)),
                        title: Text(event.type.timelineLabel),
                        subtitle: Text(
                          '${formatLocalDay(event.happenedAt)} ${formatLocalTime(event.happenedAt)}',
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

  String _todayLabel(CheckInState state) => switch (state.status) {
        CheckInStatus.completed =>
          'Completed at ${formatLocalTime(state.completedAt!)}',
        CheckInStatus.missed =>
          'Missed at ${formatLocalTime(state.missedAt ?? state.windowEnd)}',
        CheckInStatus.pending => 'Pending',
      };
}
