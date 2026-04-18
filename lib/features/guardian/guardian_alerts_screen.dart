import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/features/guardian/guardian_alerts_providers.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianAlertsScreen extends ConsumerWidget {
  const GuardianAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(guardianAlertsDataProvider);

    return AppScaffoldShell(
      title: 'Guardian Alerts',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianAlerts,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianTimeline),
          icon: const Icon(Icons.timeline_outlined),
          tooltip: 'Timeline',
        ),
      ],
      child: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load alerts: $error')),
        data: (data) {
          if (data.seniorId == null) {
            return const Center(child: Text('No linked senior for alerts.'));
          }

          return ListView(
            children: [
              Text(
                data.seniorProfile?.displayName ?? data.seniorId!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v4,
              Text(
                'Active ${data.activeCount} • Acknowledged ${data.acknowledgedCount} • Resolved ${data.resolvedCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Gaps.v16,
              if (data.alerts.isEmpty)
                Text(
                  'No alerts found from local monitoring history.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.alerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _AlertCard(
                      alert: alert,
                      onAcknowledge: alert.state == GuardianAlertState.active
                          ? () => _acknowledgeAlert(ref, alert.id)
                          : null,
                      onResolve: alert.state != GuardianAlertState.resolved
                          ? () => _resolveAlert(ref, alert.id)
                          : null,
                      onOpenTimeline: () =>
                          context.push(AppRoutes.guardianTimeline),
                      onOpenMonitoring: () => context.push(
                        _routeForDestination(alert.destination),
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

  Future<void> _acknowledgeAlert(WidgetRef ref, String alertId) async {
    await ref.read(guardianAlertRepositoryProvider).acknowledgeAlert(alertId);
    ref.invalidate(guardianAlertsDataProvider);
    ref.invalidate(guardianHomeDataProvider);
  }

  Future<void> _resolveAlert(WidgetRef ref, String alertId) async {
    await ref.read(guardianAlertRepositoryProvider).resolveAlert(alertId);
    ref.invalidate(guardianAlertsDataProvider);
    ref.invalidate(guardianHomeDataProvider);
  }

  String _routeForDestination(GuardianMonitoringDestination destination) {
    return switch (destination) {
      GuardianMonitoringDestination.timeline => AppRoutes.guardianTimeline,
      GuardianMonitoringDestination.checkIns => AppRoutes.guardianCheckIns,
      GuardianMonitoringDestination.medication => AppRoutes.guardianMedication,
      GuardianMonitoringDestination.hydration => AppRoutes.guardianHydration,
      GuardianMonitoringDestination.nutrition => AppRoutes.guardianNutrition,
      GuardianMonitoringDestination.location => AppRoutes.guardianLocation,
      GuardianMonitoringDestination.incidents => AppRoutes.guardianIncidents,
    };
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onOpenTimeline,
    required this.onOpenMonitoring,
    this.onAcknowledge,
    this.onResolve,
  });

  final GuardianAlert alert;
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenMonitoring;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<AppStatusColors>();
    final severityColor = switch (alert.severity) {
      GuardianAlertSeverity.info => statusColors?.info ?? Colors.blue,
      GuardianAlertSeverity.warning => statusColors?.watch ?? Colors.orange,
      GuardianAlertSeverity.critical =>
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
                Icon(Icons.priority_high_outlined, color: severityColor),
                Gaps.h8,
                Expanded(
                  child: Text(
                    alert.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: severityColor,
                        ),
                  ),
                ),
              ],
            ),
            Gaps.v4,
            Text(
              '${alert.severity.label} • ${alert.state.label} • ${formatLocalDay(alert.happenedAt)} ${formatLocalTime(alert.happenedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Gaps.v8,
            Text(
              alert.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v8,
            Row(
              children: [
                if (onAcknowledge != null)
                  TextButton(
                    onPressed: onAcknowledge,
                    child: const Text('Acknowledge'),
                  ),
                if (onResolve != null)
                  TextButton(
                    onPressed: onResolve,
                    child: const Text('Resolve'),
                  ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: onOpenTimeline,
                  child: const Text('Open timeline context'),
                ),
                TextButton(
                  onPressed: onOpenMonitoring,
                  child: const Text('Open monitoring section'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
