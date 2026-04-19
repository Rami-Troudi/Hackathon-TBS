import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/features/guardian/guardian_alerts_providers.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

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
                const EmptyStateBlock(
                  icon: Icons.notifications_none_outlined,
                  title: 'No alerts right now',
                  description:
                      'Local monitoring has not found anything that needs attention.',
                )
              else
                ...data.alerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AlertListCard(
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
