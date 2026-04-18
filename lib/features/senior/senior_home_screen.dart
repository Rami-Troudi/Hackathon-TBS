import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/hydration_state.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/meal_state.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class SeniorHomeScreen extends ConsumerWidget {
  const SeniorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorHomeAsync = ref.watch(seniorHomeDataProvider);

    return AppScaffoldShell(
      title: 'Senior Home',
      role: AppShellRole.senior,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.home),
          icon: const Icon(Icons.developer_mode_outlined),
          tooltip: 'Developer Hub',
        ),
      ],
      child: seniorHomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load senior home: $error')),
        data: (data) => _SeniorHomeContent(data: data),
      ),
    );
  }
}

class _SeniorHomeContent extends ConsumerWidget {
  const _SeniorHomeContent({
    required this.data,
  });

  final SeniorHomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorId = data.activeSeniorId;
    if (seniorId == null) {
      return const Center(
        child: Text(
            'No active senior context. Switch to a senior profile in Settings.'),
      );
    }
    final settings = data.settings;
    final profileName = data.profile?.displayName ?? 'there';
    final greetingStyle = settings.largeTextEnabled
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 30)
        : Theme.of(context).textTheme.headlineSmall;
    final isSimplified = settings.simplifiedModeEnabled;
    final greeting = _localizedGreeting(
      settings.languageCode,
      profileName: profileName,
    );
    final supportLine = _localizedSupportLine(
      settings.languageCode,
      emergencyContactLabel: settings.emergencyContactLabel,
    );
    final reminderIntensityLabel =
        _reminderIntensityLabel(settings.reminderIntensity.name);

    return ListView(
      children: [
        Text(
          greeting,
          style: greetingStyle,
        ),
        Gaps.v4,
        Text(
          supportLine,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Gaps.v4,
        Text(
          'Reminder intensity: $reminderIntensityLabel',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Gaps.v16,
        _StatusCard(
          summary: data.summary,
          highContrast: settings.highContrastEnabled,
        ),
        Gaps.v16,
        _WellbeingSnapshotCard(
          hydrationState: data.hydrationState,
          nutritionState: data.nutritionState,
        ),
        Gaps.v8,
        _SafeZoneStatusCard(status: data.safeZoneStatus),
        Gaps.v16,
        _PrimaryActionCard(
          checkInState: data.checkInState,
          onPrimaryAction: () => _completeCheckIn(context, ref, seniorId),
          onHelpAction: () => _needHelp(context, ref, seniorId),
        ),
        Gaps.v16,
        _NextReminderCard(
          reminder: data.nextReminder,
          reminderIntensityLabel: reminderIntensityLabel,
        ),
        Gaps.v16,
        Text(
          'Daily tools',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Gaps.v8,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SeniorToolButton(
              icon: Icons.check_circle_outline,
              label: 'Check-in',
              onTap: () => context.push(AppRoutes.checkIn),
            ),
            _SeniorToolButton(
              icon: Icons.medication_outlined,
              label: 'Medication',
              onTap: () => context.push(AppRoutes.medication),
            ),
            _SeniorToolButton(
              icon: Icons.warning_amber_outlined,
              label: 'Help',
              onTap: () => context.push(AppRoutes.incident),
            ),
            _SeniorToolButton(
              icon: Icons.local_drink_outlined,
              label: 'Hydration',
              onTap: () => context.push(AppRoutes.seniorHydration),
            ),
            _SeniorToolButton(
              icon: Icons.restaurant_outlined,
              label: 'Nutrition',
              onTap: () => context.push(AppRoutes.seniorNutrition),
            ),
            _SeniorToolButton(
              icon: Icons.summarize_outlined,
              label: 'Summary',
              onTap: () => context.push(AppRoutes.seniorSummary),
            ),
          ],
        ),
        Gaps.v16,
        if (!isSimplified) _RecentActivityCard(events: data.recentEvents),
      ],
    );
  }

  String _localizedGreeting(
    String languageCode, {
    required String profileName,
  }) {
    return switch (languageCode) {
      'ar' => 'Marhaban, $profileName',
      'en' => 'Hello, $profileName',
      _ => 'Bonjour, $profileName',
    };
  }

  String _localizedSupportLine(
    String languageCode, {
    required String emergencyContactLabel,
  }) {
    return switch (languageCode) {
      'ar' =>
        'Your daily support is ready. $emergencyContactLabel is your emergency contact.',
      'en' =>
        'Today\'s support in one place. $emergencyContactLabel is your emergency contact.',
      _ =>
        'Votre soutien quotidien est prêt. $emergencyContactLabel est votre contact d\'urgence.',
    };
  }

  String _reminderIntensityLabel(String raw) {
    return switch (raw) {
      'low' => 'Low',
      'high' => 'High',
      _ => 'Normal',
    };
  }

  Future<void> _completeCheckIn(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    final created = await ref
        .read(checkInRepositoryProvider)
        .markCheckInCompleted(seniorId);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Check-in completed'
              : 'Today\'s check-in was already completed',
        ),
      ),
    );
  }

  Future<void> _needHelp(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    await ref.read(checkInRepositoryProvider).markNeedHelp(seniorId);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Help request recorded. Support has been alerted.')),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.summary,
    required this.highContrast,
  });

  final DashboardSummary summary;
  final bool highContrast;

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
      color: highContrast ? Colors.black : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            Gaps.h8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.globalStatus.label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: highContrast ? Colors.white : null,
                        ),
                  ),
                  Text(
                    summary.globalStatus.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: highContrast ? Colors.white70 : null,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WellbeingSnapshotCard extends StatelessWidget {
  const _WellbeingSnapshotCard({
    required this.hydrationState,
    required this.nutritionState,
  });

  final HydrationState hydrationState;
  final NutritionState nutritionState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wellbeing today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v8,
            Text(
              'Hydration: ${hydrationState.completedCount}/${hydrationState.dailyGoalCompletions} completed',
            ),
            Text(
              'Meals: ${nutritionState.completedCount}/${nutritionState.slots.length} completed',
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeZoneStatusCard extends StatelessWidget {
  const _SafeZoneStatusCard({
    required this.status,
  });

  final SafeZoneStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safe status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v4,
            Text(status.zoneLabel),
            if (status.location != null)
              Text(
                'Updated ${_formatTime(status.location!.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
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

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.checkInState,
    required this.onPrimaryAction,
    required this.onHelpAction,
  });

  final CheckInState checkInState;
  final VoidCallback onPrimaryAction;
  final VoidCallback onHelpAction;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (checkInState.status) {
      CheckInStatus.completed =>
        'Completed at ${_formatTime(checkInState.completedAt)}',
      CheckInStatus.missed =>
        'Missed ${checkInState.windowLabel}. You can still check in now.',
      CheckInStatus.pending =>
        'Pending in ${checkInState.windowLabel}. Please confirm your status.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Primary daily action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v4,
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v16,
            SizedBox(
              width: double.infinity,
              height: 132,
              child: FilledButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.favorite_outline),
                label: const Text('I\'m okay'),
              ),
            ),
            Gaps.v8,
            SizedBox(
              width: double.infinity,
              height: 132,
              child: FilledButton.icon(
                onPressed: onHelpAction,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.call_outlined),
                label: const Text('I need help'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return 'just now';
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _SeniorToolButton extends StatelessWidget {
  const _SeniorToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({
    required this.reminder,
    required this.reminderIntensityLabel,
  });

  final MedicationReminder? reminder;
  final String reminderIntensityLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next reminder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v4,
            if (reminder == null)
              Text(
                'No pending reminders right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                '${reminder!.plan.medicationName} (${reminder!.plan.dosageLabel}) at ${reminder!.slotLabel}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            Gaps.v4,
            Text(
              'Current reminder intensity: $reminderIntensityLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.events,
  });

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
              'Recent activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.v8,
            if (events.isEmpty)
              Text(
                'No recent events yet.',
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
