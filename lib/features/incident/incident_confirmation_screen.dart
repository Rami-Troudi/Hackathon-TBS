import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/features/incident/incident_providers.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';

class IncidentConfirmationScreen extends ConsumerWidget {
  const IncidentConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentDataProvider);
    return AppScaffoldShell(
      title: 'Help & Incident',
      role: AppShellRole.senior,
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
            IncidentFlowStatus.suspected => 'Please confirm if you are okay',
            IncidentFlowStatus.confirmed => 'Help is being prepared',
            IncidentFlowStatus.emergency => 'Emergency support triggered',
          };

          return ListView(
            children: [
              Text(
                'Need help?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v8,
              AppCard(
                tone: data.flowState.status == IncidentFlowStatus.emergency ||
                        data.flowState.status == IncidentFlowStatus.confirmed
                    ? AppCardTone.danger
                    : AppCardTone.surface,
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
                  ],
                ),
              ),
              Gaps.v16,
              BigAction(
                label: 'I need help now',
                subtitle: 'Start emergency support',
                icon: Icons.call_outlined,
                tone: BigActionTone.destructive,
                onTap: () => _triggerEmergency(context, ref, seniorId),
              ),
              Gaps.v8,
              BigAction(
                label: 'I\'m okay',
                subtitle: 'Clear the incident prompt',
                icon: Icons.verified_outlined,
                tone: BigActionTone.primary,
                onTap: () => _dismissIncident(context, ref, seniorId),
              ),
            ],
          );
        },
      ),
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
}
