import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/features/incident/incident_providers.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';

class IncidentConfirmationScreen extends ConsumerWidget {
  const IncidentConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentDataProvider);
    return AppScaffoldShell(
      title: 'Help & Incident',
      child: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load incident flow: $error')),
        data: (data) {
          final seniorId = data.seniorId;
          if (seniorId == null) {
            return const Center(child: Text('No active senior context found.'));
          }

          final statusLabel = switch (data.flowState.status) {
            IncidentFlowStatus.clear => 'No active incident',
            IncidentFlowStatus.suspected => 'Suspicious incident under review',
            IncidentFlowStatus.confirmed => 'Incident confirmed',
            IncidentFlowStatus.emergency => 'Emergency state triggered',
          };

          return ListView(
            children: [
              Text(
                'Need help?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Gaps.v4,
                      Text(
                        'Use these actions to confirm if everything is okay or request urgent help.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Gaps.v8,
                      Text(
                        'Open suspected: ${data.flowState.openSuspectedIncidents} • Open confirmed: ${data.flowState.openConfirmedIncidents}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.v16,
              FilledButton(
                onPressed: () => _triggerEmergency(context, ref, seniorId),
                child: const Text('Emergency - I need help now'),
              ),
              Gaps.v8,
              FilledButton.tonal(
                onPressed: () => _confirmIncident(context, ref, seniorId),
                child: const Text('Confirm incident'),
              ),
              Gaps.v8,
              FilledButton.tonal(
                onPressed: () => _reportSuspicious(context, ref, seniorId),
                child: const Text('Something seems wrong'),
              ),
              Gaps.v8,
              OutlinedButton(
                onPressed: () => _dismissIncident(context, ref, seniorId),
                child: const Text('I\'m okay'),
              ),
              Gaps.v16,
              Text(
                'Recent incident activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gaps.v8,
              if (data.recentIncidentEvents.isEmpty)
                Text(
                  'No incident events yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...data.recentIncidentEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      '${event.type.timelineLabel} • ${_formatTime(event.happenedAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reportSuspicious(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    await ref
        .read(incidentRepositoryProvider)
        .reportSuspiciousIncident(seniorId);
    ref.invalidate(incidentDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suspicious incident recorded')),
    );
  }

  Future<void> _dismissIncident(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    await ref.read(incidentRepositoryProvider).dismissIncident(seniorId);
    ref.invalidate(incidentDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incident dismissed. Status updated.')),
    );
  }

  Future<void> _confirmIncident(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    await ref.read(incidentRepositoryProvider).confirmIncident(seniorId);
    ref.invalidate(incidentDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incident confirmed')),
    );
  }

  Future<void> _triggerEmergency(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    await ref.read(incidentRepositoryProvider).requestImmediateHelp(seniorId);
    ref.invalidate(incidentDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency flow triggered')),
    );
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
