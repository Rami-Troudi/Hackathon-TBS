import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';
import 'package:senior_companion/shared/widgets/connectivity_banner.dart';
import 'package:url_launcher/url_launcher.dart';

class SeniorHomeScreen extends ConsumerStatefulWidget {
  const SeniorHomeScreen({super.key});

  @override
  ConsumerState<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends ConsumerState<SeniorHomeScreen> {
  String? _lastPromptToken;

  @override
  Widget build(BuildContext context) {
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
        data: (data) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUrgentPromptIfNeeded(context, data);
          });
          return _SeniorHomeContent(data: data);
        },
      ),
    );
  }

  Future<void> _showUrgentPromptIfNeeded(
    BuildContext context,
    SeniorHomeData data,
  ) async {
    if (!mounted || data.activeSeniorId == null) return;
    final reminder = data.nextReminder;
    final promptToken =
        '${data.checkInState.status.name}-${reminder?.plan.id}-${reminder?.status.name}';
    if (_lastPromptToken == promptToken) return;

    if (data.checkInState.status != CheckInStatus.completed) {
      _lastPromptToken = promptToken;
      final yes = await _showSeniorPrompt(
        context,
        title: 'Are you okay?',
        body: 'Please confirm your daily check-in now.',
        yesLabel: 'Yes',
        noLabel: 'No',
      );
      if (!mounted) return;
      if (yes == true) {
        await ref
            .read(checkInRepositoryProvider)
            .markCheckInCompleted(data.activeSeniorId!);
      } else if (yes == false) {
        await ref
            .read(checkInRepositoryProvider)
            .markNeedHelp(data.activeSeniorId!);
      }
      ref.invalidate(seniorHomeDataProvider);
      return;
    }

    if (reminder != null &&
        reminder.status == MedicationReminderStatus.pending) {
      _lastPromptToken = promptToken;
      final yes = await _showSeniorPrompt(
        context,
        title: 'Medication reminder',
        body:
            'Did you take ${reminder.plan.medicationName} (${reminder.slotLabel})?',
        yesLabel: 'Taken',
        noLabel: 'Not yet',
      );
      if (!mounted) return;
      if (yes == true) {
        await ref.read(medicationRepositoryProvider).markMedicationTaken(
              data.activeSeniorId!,
              planId: reminder.plan.id,
            );
      } else if (yes == false) {
        await ref.read(medicationRepositoryProvider).markMedicationMissed(
              data.activeSeniorId!,
              planId: reminder.plan.id,
            );
      }
      ref.invalidate(seniorHomeDataProvider);
    }
  }

  Future<bool?> _showSeniorPrompt(
    BuildContext context, {
    required String title,
    required String body,
    required String yesLabel,
    required String noLabel,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Senior prompt',
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.notifications_active_outlined,
                  size: 84,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                SizedBox(
                  height: 62,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(yesLabel),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 62,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(noLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final greeting = switch (settings.languageCode) {
      'ar' => 'Marhaban, $profileName',
      'en' => 'Hello, $profileName',
      _ => 'Bonjour, $profileName',
    };
    final connectivityState =
        ref.watch(connectivityStateProvider).valueOrNull ??
            AppConnectivityState.online;

    return ListView(
      children: [
        Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Quick actions below keep your family informed.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (connectivityState != AppConnectivityState.online) ...[
          const SizedBox(height: AppSpacing.md),
          ConnectivityBanner(state: connectivityState),
        ],
        const SizedBox(height: AppSpacing.md),
        _StatusCard(summary: data.summary),
        const SizedBox(height: AppSpacing.md),
        _PrimaryActionCard(
          checkInState: data.checkInState,
          onPrimaryAction: () async {
            final created = await ref
                .read(checkInRepositoryProvider)
                .markCheckInCompleted(seniorId);
            ref.invalidate(seniorHomeDataProvider);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(created ? 'Check-in completed' : 'Already completed'),
              ),
            );
          },
          onHelpAction: () async {
            await ref.read(checkInRepositoryProvider).markNeedHelp(seniorId);
            ref.invalidate(seniorHomeDataProvider);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help request sent')),
            );
          },
          onEmergencyCall: () => _launchEmergencyDialer(context),
          onCompanion: () => context.push(AppRoutes.seniorCompanion),
        ),
        const SizedBox(height: AppSpacing.md),
        _MedicationQuickCard(
          reminder: data.nextReminder,
          onTaken: data.nextReminder == null
              ? null
              : () async {
                  await ref
                      .read(medicationRepositoryProvider)
                      .markMedicationTaken(
                        seniorId,
                        planId: data.nextReminder!.plan.id,
                      );
                  ref.invalidate(seniorHomeDataProvider);
                },
          onMissed: data.nextReminder == null
              ? null
              : () async {
                  await ref
                      .read(medicationRepositoryProvider)
                      .markMedicationMissed(
                        seniorId,
                        planId: data.nextReminder!.plan.id,
                      );
                  ref.invalidate(seniorHomeDataProvider);
                },
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonal(
              onPressed: () => context.push(AppRoutes.seniorHydration),
              child: const Text('Hydration'),
            ),
            FilledButton.tonal(
              onPressed: () => context.push(AppRoutes.seniorNutrition),
              child: const Text('Meals'),
            ),
            FilledButton.tonal(
              onPressed: () => context.push(AppRoutes.seniorSummary),
              child: const Text('Daily summary'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchEmergencyDialer(BuildContext context) async {
    final uri = Uri.parse('tel:112');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open emergency dialer')),
      );
    }
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
          const SizedBox(height: AppSpacing.sm),
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
    required this.onEmergencyCall,
    required this.onCompanion,
  });

  final CheckInState checkInState;
  final VoidCallback onPrimaryAction;
  final VoidCallback onHelpAction;
  final VoidCallback onEmergencyCall;
  final VoidCallback onCompanion;

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
        const SizedBox(height: AppSpacing.sm),
        BigAction(
          label: 'I\'m okay',
          subtitle: 'Send today\'s check-in',
          icon: Icons.favorite_outline,
          onTap: onPrimaryAction,
        ),
        const SizedBox(height: AppSpacing.sm),
        BigAction(
          label: 'I need help',
          subtitle: 'Alert your family now',
          icon: Icons.call_outlined,
          tone: BigActionTone.destructive,
          onTap: onHelpAction,
        ),
        const SizedBox(height: AppSpacing.sm),
        BigAction(
          label: 'Emergency call',
          subtitle: 'Open 112 dialer now',
          icon: Icons.local_phone_outlined,
          tone: BigActionTone.destructive,
          onTap: onEmergencyCall,
        ),
        const SizedBox(height: AppSpacing.sm),
        BigAction(
          label: 'Talk to Companion',
          subtitle: 'Ask by voice',
          icon: Icons.mic_outlined,
          tone: BigActionTone.soft,
          onTap: onCompanion,
        ),
      ],
    );
  }
}

class _MedicationQuickCard extends StatelessWidget {
  const _MedicationQuickCard({
    required this.reminder,
    required this.onTaken,
    required this.onMissed,
  });

  final MedicationReminder? reminder;
  final VoidCallback? onTaken;
  final VoidCallback? onMissed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.sage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reminder == null
                ? 'Next medication: no pending reminder.'
                : 'Next medication: ${reminder!.plan.medicationName} at ${reminder!.slotLabel}.',
          ),
          if (reminder != null &&
              reminder!.status == MedicationReminderStatus.pending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onTaken,
                    child: const Text('Taken'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMissed,
                    child: const Text('Not yet'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
