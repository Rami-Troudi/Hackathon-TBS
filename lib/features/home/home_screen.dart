import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/features/home/home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

/// The prototype hub screen shown after splash when no active session exists.
///
/// This screen serves two purposes in G0:
/// 1. **Demo hub** — quick navigation to senior and guardian placeholder screens.
/// 2. **Foundation showcase** — demonstrates that every G0 layer is wired
///    correctly: FutureProvider, AsyncValue, mock repositories, event bus,
///    local notifications, and role persistence.
///
/// In G1 this screen will be replaced by a proper role-selection / onboarding
/// flow that creates a real session and routes to the correct experience.
///
/// This is a [ConsumerWidget] — there is no local mutable state. All data
/// comes from [homeDataProvider] and all mutations go through Riverpod.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // ── Action handlers ─────────────────────────────────────────────────────────
  //
  // These are static methods because HomeScreen is stateless. They receive
  // the ref and context they need as parameters. ref.read is correct here
  // because these are triggered by user actions, not reactive rebuilds.

  static Future<void> _toggleRole(WidgetRef ref) async {
    final preferencesRepo = ref.read(preferencesRepositoryProvider);
    final currentRole = await preferencesRepo.getPreferredRole();
    final nextRole =
        currentRole == AppRole.senior ? AppRole.guardian : AppRole.senior;
    await preferencesRepo.setPreferredRole(nextRole);
    // Invalidate so the provider re-runs and the UI reflects the new role.
    // Note: this also re-increments the launch count — known prototype behaviour,
    // documented in home_providers.dart.
    ref.invalidate(homeDataProvider);
  }

  static void _publishExampleEvent(WidgetRef ref, BuildContext context) {
    ref.read(appEventBusProvider).publish(
          CheckInCompletedEvent(
            seniorId: 'demo-senior',
            happenedAt: DateTime.now(),
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CheckInCompletedEvent published on the event bus'),
      ),
    );
  }

  static Future<void> _sendInfoNotification(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.showInfo(
      title: 'Senior Companion',
      body: 'Prototype foundation is running correctly.',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Info notification sent')),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeDataAsync = ref.watch(homeDataProvider);

    return AppScaffoldShell(
      title: 'Home',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
      ],
      child: homeDataAsync.when(
        loading: _buildLoading,
        error: (error, _) => _buildError(context, ref, error),
        data: (homeData) => _buildContent(context, ref, homeData),
      ),
    );
  }

  // ── Loading state ────────────────────────────────────────────────────────────

  static Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  // ── Error state ──────────────────────────────────────────────────────────────

  static Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            Gaps.v16,
            Text(
              'Could not load home data',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Gaps.v8,
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Gaps.v24,
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(homeDataProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data state ───────────────────────────────────────────────────────────────

  static Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HomeData homeData,
  ) {
    return ListView(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Text(
          'Prototype Foundation',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Gaps.v4,
        Text(
          'Launch count: ${homeData.launchCount}  •  '
          'Role: ${homeData.preferredRole.label}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Gaps.v24,

        // ── Status card ─────────────────────────────────────────────────────
        _StatusCard(summary: homeData.dashboardSummary),
        Gaps.v16,

        // ── Navigation ──────────────────────────────────────────────────────
        Text(
          'Navigate to',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Gaps.v8,
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.seniorHome),
          icon: const Icon(Icons.accessibility_new_outlined),
          label: const Text('Senior Placeholder'),
        ),
        Gaps.v8,
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.guardianHome),
          icon: const Icon(Icons.family_restroom_outlined),
          label: const Text('Guardian Placeholder'),
        ),
        Gaps.v24,

        // ── Foundation demos ─────────────────────────────────────────────────
        Text(
          'Foundation demos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Gaps.v8,
        OutlinedButton.icon(
          onPressed: () => _toggleRole(ref),
          icon: const Icon(Icons.swap_horiz_outlined),
          label: Text(
            'Switch to '
            '${homeData.preferredRole == AppRole.senior ? 'Guardian' : 'Senior'}',
          ),
        ),
        Gaps.v8,
        OutlinedButton.icon(
          onPressed: () => _publishExampleEvent(ref, context),
          icon: const Icon(Icons.bolt_outlined),
          label: const Text('Publish CheckInCompletedEvent'),
        ),
        Gaps.v8,
        OutlinedButton.icon(
          onPressed: () => _sendInfoNotification(ref, context),
          icon: const Icon(Icons.notifications_outlined),
          label: const Text('Trigger Info Notification'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status card widget
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the [DashboardSummary] with a colour-coded status indicator
/// derived from [SeniorGlobalStatus].
///
/// This is a self-contained widget so it can be reused on the guardian
/// dashboard in G4 without coupling to [HomeScreen].
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
            // ── Status row ─────────────────────────────────────────────────
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

            // ── Metrics row ────────────────────────────────────────────────
            Row(
              children: [
                _MetricChip(
                  label: 'Alerts',
                  value: summary.pendingAlerts,
                  highlight: summary.pendingAlerts > 0,
                ),
                Gaps.h8,
                _MetricChip(
                  label: 'Check-ins',
                  value: summary.todayCheckIns,
                ),
                Gaps.h8,
                _MetricChip(
                  label: 'Missed meds',
                  value: summary.missedMedications,
                  highlight: summary.missedMedications > 0,
                ),
                Gaps.h8,
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

// ─────────────────────────────────────────────────────────────────────────────

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
      mainAxisSize: MainAxisSize.min,
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
