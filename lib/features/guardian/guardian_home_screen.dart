import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class GuardianHomeScreen extends ConsumerWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(guardianHomeDataProvider);

    return AppScaffoldShell(
      title: 'Guardian Dashboard',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianHome,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianAlerts),
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: 'Alerts',
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianTimeline),
          icon: const Icon(Icons.timeline_outlined),
          tooltip: 'Timeline',
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
      ],
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load dashboard: $error')),
        data: (data) {
          if (data.activeSeniorId == null) {
            return const Center(
              child: Text('No linked senior found in this guardian session.'),
            );
          }

          final canShowSeniorInfo = data.settings.linkedSeniorInfoVisible;
          final seniorName = canShowSeniorInfo
              ? data.seniorProfile?.displayName ?? data.activeSeniorId!
              : 'Linked senior';
          final guardianLabel = data.guardianProfile == null
              ? 'Guardian view'
              : '${data.guardianProfile!.displayName} • ${data.guardianProfile!.relationshipLabel}';

          return ListView(
            children: [
              Text(
                seniorName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v4,
              Text(
                guardianLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Gaps.v16,
              _GlobalStatusCard(
                status: data.dashboardSummary.globalStatus,
                statusDescription:
                    data.dashboardSummary.globalStatus.description,
                pendingAlerts: data.pendingActiveAlerts,
                todayCheckIns: data.dashboardSummary.todayCheckIns,
                missedMedications: data.dashboardSummary.missedMedications,
                openIncidents: data.dashboardSummary.openIncidents,
              ),
              Gaps.v16,
              _QuickActionRow(
                onAlerts: () => context.push(AppRoutes.guardianAlerts),
                onTimeline: () => context.push(AppRoutes.guardianTimeline),
                onProfile: () => context.push(AppRoutes.guardianProfile),
              ),
              Gaps.v16,
              MonitoringCard(
                title: 'Check-ins',
                subtitle: _checkInSubtitle(data.checkInState),
                icon: Icons.check_circle_outline,
                onTap: () => context.push(AppRoutes.guardianCheckIns),
              ),
              Gaps.v8,
              MonitoringCard(
                title: 'Medication',
                subtitle:
                    'Taken ${data.todayMedicationTaken} • Missed ${data.todayMedicationMissed} • Pending ${data.todayMedicationPending}',
                icon: Icons.medication_outlined,
                onTap: () => context.push(AppRoutes.guardianMedication),
              ),
              Gaps.v8,
              MonitoringCard(
                title: 'Incidents',
                subtitle:
                    'Open suspected ${data.incidentState.openSuspectedIncidents} • Open confirmed ${data.incidentState.openConfirmedIncidents} • ${_incidentLabel(data.incidentState.status)}',
                icon: Icons.report_gmailerrorred_outlined,
                onTap: () => context.push(AppRoutes.guardianIncidents),
              ),
              if (data.settings.showHydrationReminders) ...[
                Gaps.v8,
                MonitoringCard(
                  title: 'Hydration',
                  subtitle:
                      'Completed ${data.hydrationState.completedCount}/${data.hydrationState.dailyGoalCompletions} • Missed ${data.hydrationState.missedCount}',
                  icon: Icons.local_drink_outlined,
                  onTap: () => context.push(AppRoutes.guardianHydration),
                ),
              ],
              if (data.settings.showNutritionReminders) ...[
                Gaps.v8,
                MonitoringCard(
                  title: 'Nutrition',
                  subtitle:
                      'Completed ${data.nutritionState.completedCount}/${data.nutritionState.slots.length} • Missed ${data.nutritionState.missedCount}',
                  icon: Icons.restaurant_outlined,
                  onTap: () => context.push(AppRoutes.guardianNutrition),
                ),
              ],
              if (data.settings.showLocationUpdates) ...[
                Gaps.v8,
                MonitoringCard(
                  title: 'Location',
                  subtitle: data.safeZoneStatus.zoneLabel,
                  icon: Icons.my_location_outlined,
                  onTap: () => context.push(AppRoutes.guardianLocation),
                ),
              ],
              if (data.settings.dailyDigestEnabled ||
                  data.settings.weeklyDigestEnabled) ...[
                Gaps.v8,
                MonitoringCard(
                  title: 'Daily digest',
                  subtitle: data.dailySummary.headline,
                  icon: Icons.summarize_outlined,
                  onTap: () => context.push(AppRoutes.guardianSummary),
                ),
              ],
              Gaps.v8,
              MonitoringCard(
                title: 'AI insights',
                subtitle: 'Grounded Q&A and smart explanations from local data',
                icon: Icons.smart_toy_outlined,
                onTap: () => context.push(AppRoutes.guardianInsights),
              ),
              Gaps.v16,
              _TopAlertsCard(
                alerts: data.topAlerts,
                onOpenAlerts: () => context.push(AppRoutes.guardianAlerts),
              ),
              Gaps.v16,
              _RecentEventsCard(
                events: data.recentImportantEvents,
                onOpenTimeline: () => context.push(AppRoutes.guardianTimeline),
              ),
            ],
          );
        },
      ),
    );
  }

  String _checkInSubtitle(CheckInState state) {
    return switch (state.status) {
      CheckInStatus.completed =>
        'Today completed at ${formatLocalTime(state.completedAt!)}',
      CheckInStatus.missed =>
        'Today missed at ${formatLocalTime(state.missedAt ?? state.windowEnd)}',
      CheckInStatus.pending =>
        'Pending today (${formatLocalTime(state.windowStart)}-${formatLocalTime(state.windowEnd)})',
    };
  }

  String _incidentLabel(IncidentFlowStatus status) => switch (status) {
        IncidentFlowStatus.clear => 'No active incident',
        IncidentFlowStatus.suspected => 'Suspicious incident open',
        IncidentFlowStatus.confirmed => 'Confirmed incident open',
        IncidentFlowStatus.emergency => 'Emergency state',
      };
}

class _GlobalStatusCard extends StatelessWidget {
  const _GlobalStatusCard({
    required this.status,
    required this.statusDescription,
    required this.pendingAlerts,
    required this.todayCheckIns,
    required this.missedMedications,
    required this.openIncidents,
  });

  final SeniorGlobalStatus status;
  final String statusDescription;
  final int pendingAlerts;
  final int todayCheckIns;
  final int missedMedications;
  final int openIncidents;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: status == SeniorGlobalStatus.actionRequired
          ? AppCardTone.danger
          : status == SeniorGlobalStatus.watch
              ? AppCardTone.warning
              : AppCardTone.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(status: status),
          Gaps.v12,
          Text(
            statusDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Gaps.v16,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _Metric(
                  label: 'Pending alerts',
                  value: pendingAlerts,
                  highlight: pendingAlerts > 0),
              _Metric(label: 'Today check-ins', value: todayCheckIns),
              _Metric(
                  label: 'Missed meds',
                  value: missedMedications,
                  highlight: missedMedications > 0),
              _Metric(
                  label: 'Open incidents',
                  value: openIncidents,
                  highlight: openIncidents > 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.onAlerts,
    required this.onTimeline,
    required this.onProfile,
  });

  final VoidCallback onAlerts;
  final VoidCallback onTimeline;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAlerts,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Alerts'),
          ),
        ),
        Gaps.h8,
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTimeline,
            icon: const Icon(Icons.timeline_outlined),
            label: const Text('Timeline'),
          ),
        ),
        Gaps.h8,
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onProfile,
            icon: const Icon(Icons.person_outline),
            label: const Text('Senior'),
          ),
        ),
      ],
    );
  }
}

class _TopAlertsCard extends StatelessWidget {
  const _TopAlertsCard({
    required this.alerts,
    required this.onOpenAlerts,
  });

  final List<GuardianAlert> alerts;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Top alerts',
            actionLabel: 'View all',
            onAction: onOpenAlerts,
          ),
          if (alerts.isEmpty)
            Text(
              'No alerts right now.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    SeverityChip(severity: alert.severity),
                    Gaps.h8,
                    Expanded(child: Text(alert.title)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentEventsCard extends StatelessWidget {
  const _RecentEventsCard({
    required this.events,
    required this.onOpenTimeline,
  });

  final List<PersistedEventRecord> events;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Recent important events',
            actionLabel: 'Timeline',
            onAction: onOpenTimeline,
          ),
          if (events.isEmpty)
            Text(
              'No important events yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...events.take(5).map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(iconForEventType(event.type), size: 18),
                        Gaps.h8,
                        Expanded(
                          child: Text(
                            '${event.type.timelineLabel} • ${formatLocalTime(event.happenedAt)}\n${formatEventDetail(event)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
