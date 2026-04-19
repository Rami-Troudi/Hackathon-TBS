import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
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
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class SeniorHomeScreen extends ConsumerWidget {
  const SeniorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorHomeAsync = ref.watch(seniorHomeDataProvider);

    return AppScaffoldShell(
      title: 'Today',
      role: AppShellRole.senior,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
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
      return const EmptyStateBlock(
        title: 'No active senior profile',
        description: 'Open settings to switch to a senior profile.',
        icon: Icons.person_off_outlined,
      );
    }

    final settings = data.settings;
    final profileName = data.profile?.displayName ?? 'there';
    final greetingStyle = settings.largeTextEnabled
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 30)
        : Theme.of(context).textTheme.headlineSmall;
    final greeting = _localizedGreeting(
      settings.languageCode,
      profileName: profileName,
    );
    final supportLine = settings.simplifiedModeEnabled
        ? _localizedSimpleSupportLine(settings.languageCode)
        : _localizedSupportLine(
            settings.languageCode,
            emergencyContactLabel: settings.emergencyContactLabel,
          );

    return ListView(
      children: [
        Text(greeting, style: greetingStyle),
        Gaps.v4,
        Text(
          supportLine,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Gaps.v16,
        _StatusCard(summary: data.summary),
        Gaps.v16,
        _PrimaryActionCard(
          checkInState: data.checkInState,
          onPrimaryAction: () => _completeCheckIn(context, ref, seniorId),
          onHelpAction: () => _needHelp(context, ref, seniorId),
        ),
        Gaps.v16,
        _TodayRoutineCard(
          checkInState: data.checkInState,
          nextReminder: data.nextReminder,
          hydrationState: data.hydrationState,
          nutritionState: data.nutritionState,
          safeZoneStatus: data.safeZoneStatus,
          simplifiedModeEnabled: settings.simplifiedModeEnabled,
          onMedication: () => context.push(AppRoutes.medication),
          onHydration: () => context.push(AppRoutes.seniorHydration),
          onNutrition: () => context.push(AppRoutes.seniorNutrition),
          onSummary: () => context.push(AppRoutes.seniorSummary),
          onCompanion: () => context.push(AppRoutes.seniorCompanion),
        ),
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
        'Your support actions are below. In an emergency, contact $emergencyContactLabel.',
      'en' =>
        'Your support actions are below. In an emergency, contact $emergencyContactLabel.',
      _ =>
        'Vos actions essentielles sont ci-dessous. En cas d’urgence, contactez $emergencyContactLabel.',
    };
  }

  String _localizedSimpleSupportLine(String languageCode) {
    return switch (languageCode) {
      'ar' => 'Use the two large buttons below to check in or ask for help.',
      'en' => 'Use the two large buttons below to check in or ask for help.',
      _ =>
        'Utilisez les deux grands boutons ci-dessous pour confirmer ou demander de l’aide.',
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
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(status: summary.globalStatus),
          Gaps.v12,
          Text(
            summary.globalStatus.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
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
      CheckInStatus.completed => 'You already checked in today.',
      CheckInStatus.missed => 'Please confirm now.',
      CheckInStatus.pending => 'Please confirm now.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Gaps.v12,
        BigAction(
          label: 'I\'m okay',
          subtitle: 'Send today\'s check-in',
          icon: Icons.favorite_outline,
          onTap: onPrimaryAction,
        ),
        Gaps.v8,
        BigAction(
          label: 'I need help',
          subtitle: 'Alert your family now',
          icon: Icons.call_outlined,
          tone: BigActionTone.destructive,
          onTap: onHelpAction,
        ),
      ],
    );
  }
}

class _TodayRoutineCard extends StatelessWidget {
  const _TodayRoutineCard({
    required this.checkInState,
    required this.nextReminder,
    required this.hydrationState,
    required this.nutritionState,
    required this.safeZoneStatus,
    required this.simplifiedModeEnabled,
    required this.onMedication,
    required this.onHydration,
    required this.onNutrition,
    required this.onSummary,
    required this.onCompanion,
  });

  final CheckInState checkInState;
  final MedicationReminder? nextReminder;
  final HydrationState hydrationState;
  final NutritionState nutritionState;
  final SafeZoneStatus safeZoneStatus;
  final bool simplifiedModeEnabled;
  final VoidCallback onMedication;
  final VoidCallback onHydration;
  final VoidCallback onNutrition;
  final VoidCallback onSummary;
  final VoidCallback onCompanion;

  @override
  Widget build(BuildContext context) {
    final checkInLabel = switch (checkInState.status) {
      CheckInStatus.completed => 'Done',
      CheckInStatus.pending => 'Pending',
      CheckInStatus.missed => 'Pending',
    };

    return AppCard(
      tone: AppCardTone.sage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today routine',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Gaps.v8,
          Text('Check-in: $checkInLabel'),
          Text(
            nextReminder == null
                ? 'Medication: No pending reminder'
                : 'Medication: ${nextReminder!.plan.medicationName} at ${nextReminder!.slotLabel}',
          ),
          if (!simplifiedModeEnabled) ...[
            Text(
              'Hydration: ${hydrationState.completedCount}/${hydrationState.dailyGoalCompletions}',
            ),
            Text(
              'Meals: ${nutritionState.completedCount}/${nutritionState.slots.length}',
            ),
            Text('Safe status: ${safeZoneStatus.zoneLabel}'),
          ],
          Gaps.v12,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonal(
                onPressed: onMedication,
                child: const Text('Medication'),
              ),
              FilledButton.tonal(
                onPressed: onHydration,
                child: const Text('Hydration'),
              ),
              FilledButton.tonal(
                onPressed: onNutrition,
                child: const Text('Meals'),
              ),
              TextButton(
                onPressed: onSummary,
                child: const Text('Daily summary'),
              ),
              FilledButton.tonal(
                onPressed: onCompanion,
                child: const Text('Companion'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
