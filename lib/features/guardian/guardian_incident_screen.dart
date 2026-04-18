import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_incident_providers.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianIncidentScreen extends ConsumerWidget {
  const GuardianIncidentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(guardianIncidentMonitoringDataProvider);

    return AppScaffoldShell(
      title: 'Incident Monitoring',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianAlerts),
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: 'Alerts',
        ),
      ],
      child: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load incidents: $error')),
        data: (data) {
          if (data.seniorId == null) {
            return const Center(child: Text('No linked senior for incidents.'));
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
                        _statusLabel(data.currentState.status),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Gaps.v8,
                      Text(
                        'Open suspected ${data.currentState.openSuspectedIncidents} • Open confirmed ${data.currentState.openConfirmedIncidents}',
                        style: Theme.of(context).textTheme.bodyMedium,
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
                    'Last 7 days: suspected ${data.suspectedCountLast7Days} • confirmed ${data.confirmedCountLast7Days} • dismissed ${data.dismissedCountLast7Days} • emergency ${data.emergencyCountLast7Days}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Gaps.v16,
              Text(
                'Recent incident history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gaps.v8,
              if (data.recentIncidentEvents.isEmpty)
                Text(
                  'No incident events yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.recentIncidentEvents.take(12).map(
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

  String _statusLabel(IncidentFlowStatus status) => switch (status) {
        IncidentFlowStatus.clear => 'No active incident',
        IncidentFlowStatus.suspected => 'Suspicious incident in progress',
        IncidentFlowStatus.confirmed => 'Confirmed incident open',
        IncidentFlowStatus.emergency => 'Emergency state active',
      };
}
