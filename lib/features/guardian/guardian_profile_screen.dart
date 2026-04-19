import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/features/guardian/guardian_profile_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianProfileScreen extends ConsumerWidget {
  const GuardianProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(guardianProfileOverviewProvider);

    return AppScaffoldShell(
      title: 'Senior Overview',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianProfile,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianHome),
          icon: const Icon(Icons.dashboard_outlined),
          tooltip: 'Dashboard',
        ),
      ],
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load profile: $error')),
        data: (data) {
          if (data.activeSeniorId == null || data.seniorProfile == null) {
            return const Center(child: Text('No linked senior profile found.'));
          }

          final senior = data.seniorProfile!;
          final guardianText = data.guardianProfile == null
              ? 'Guardian relationship unavailable in this session.'
              : 'You are monitoring as ${data.guardianProfile!.relationshipLabel}.';

          return ListView(
            children: [
              Text(
                senior.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v4,
              Text(
                guardianText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Gaps.v16,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Gaps.v8,
                      Text('Age: ${senior.age}'),
                      Text(
                          'Language: ${senior.preferredLanguage.toUpperCase()}'),
                    ],
                  ),
                ),
              ),
              Gaps.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accessibility preferences',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Gaps.v8,
                      Text(
                          'Large text: ${senior.largeTextEnabled ? 'Enabled' : 'Disabled'}'),
                      Text(
                        'High contrast: ${senior.highContrastEnabled ? 'Enabled' : 'Disabled'}',
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Gaps.v8,
                      Text(
                          'Global status: ${data.dashboardSummary.globalStatus.label}'),
                      Text(
                          'Pending alerts: ${data.dashboardSummary.pendingAlerts}'),
                      Text(
                          'Today check-ins: ${data.dashboardSummary.todayCheckIns}'),
                      Text(
                          'Missed medications: ${data.dashboardSummary.missedMedications}'),
                      Text(
                          'Open incidents: ${data.dashboardSummary.openIncidents}'),
                    ],
                  ),
                ),
              ),
              Gaps.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked guardians',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Gaps.v8,
                      if (data.linkedGuardians.isEmpty)
                        const Text('No linked guardian profiles')
                      else
                        ...data.linkedGuardians.map(
                          (guardian) => Text(
                            '${guardian.displayName} • ${guardian.relationshipLabel}',
                          ),
                        ),
                    ],
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
