import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/check_in/check_in_providers.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(checkInDataProvider);
    return AppScaffoldShell(
      title: 'Check-in',
      role: AppShellRole.senior,
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load check-in: $error')),
        data: (data) {
          final seniorId = data.seniorId;
          if (seniorId == null) {
            return const Center(
              child: Text('No active senior context found.'),
            );
          }
          return ListView(
            children: [
              Text(
                'How are you feeling now?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v8,
              _StateBanner(state: data.checkInState),
              Gaps.v16,
              FilledButton(
                onPressed: () => _markOkay(context, ref, seniorId),
                child: const Text('I\'m okay'),
              ),
              Gaps.v8,
              OutlinedButton(
                onPressed: () => _needHelp(context, ref, seniorId),
                child: const Text('I need help'),
              ),
              Gaps.v8,
              TextButton(
                onPressed: () => context.push(AppRoutes.incident),
                child: const Text('Open detailed help flow'),
              ),
              Gaps.v16,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent check-ins',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Gaps.v8,
                      if (data.recentCheckIns.isEmpty)
                        Text(
                          'No check-in events yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...data.recentCheckIns.map(
                          (event) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              '${event.type.timelineLabel} • ${_formatTime(event.happenedAt)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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

  Future<void> _markOkay(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    final created = await ref
        .read(checkInRepositoryProvider)
        .markCheckInCompleted(seniorId);
    ref.invalidate(checkInDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created ? 'Check-in completed' : 'You already checked in today',
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
    ref.invalidate(checkInDataProvider);
    ref.invalidate(seniorHomeDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help request recorded')),
    );
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _StateBanner extends StatelessWidget {
  const _StateBanner({
    required this.state,
  });

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final (title, color) = switch (state.status) {
      CheckInStatus.pending => (
          'Pending',
          Theme.of(context).colorScheme.primary
        ),
      CheckInStatus.completed => (
          'Completed',
          Theme.of(context).extension<AppStatusColors>()?.ok ?? Colors.green
        ),
      CheckInStatus.missed => (
          'Missed',
          Theme.of(context).extension<AppStatusColors>()?.watch ?? Colors.orange
        ),
    };

    final windowRange =
        '${_formatTime(state.windowStart)} - ${_formatTime(state.windowEnd)}';
    final detail = switch (state.status) {
      CheckInStatus.pending =>
        'Window: $windowRange. Please confirm your status.',
      CheckInStatus.completed =>
        'Completed at ${_formatTime(state.completedAt ?? DateTime.now())}.',
      CheckInStatus.missed =>
        'Window $windowRange was missed. You can still check in now.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, color: color),
            Gaps.h8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
