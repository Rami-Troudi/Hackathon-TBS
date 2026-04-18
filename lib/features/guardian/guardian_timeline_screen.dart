import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_timeline_providers.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/guardian_timeline_filter.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class GuardianTimelineScreen extends ConsumerWidget {
  const GuardianTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(guardianTimelineDataProvider);
    final filteredAsync = ref.watch(guardianFilteredTimelineProvider);
    final filter = ref.watch(guardianTimelineFilterProvider);

    return AppScaffoldShell(
      title: 'Guardian Timeline',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianTimeline,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianAlerts),
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: 'Alerts',
        ),
      ],
      child: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load timeline: $error')),
        data: (data) {
          if (data.seniorId == null) {
            return const Center(child: Text('No linked senior for timeline.'));
          }

          final events = filteredAsync.value ?? const <PersistedEventRecord>[];

          return ListView(
            children: [
              Text(
                data.seniorProfile?.displayName ?? data.seniorId!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v8,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in GuardianTimelineFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(option.label),
                          selected: filter == option,
                          onSelected: (_) {
                            ref
                                .read(guardianTimelineFilterProvider.notifier)
                                .state = option;
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Gaps.v16,
              if (events.isEmpty)
                const EmptyStateBlock(
                  icon: Icons.timeline_outlined,
                  title: 'No events for this filter',
                  description:
                      'Try another category or generate demo activity from the developer hub.',
                )
              else
                ..._buildDayGroups(context, events),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildDayGroups(
    BuildContext context,
    List<PersistedEventRecord> events,
  ) {
    final groups = <String, List<PersistedEventRecord>>{};
    for (final event in events) {
      final dayKey = formatLocalDay(event.happenedAt);
      groups.putIfAbsent(dayKey, () => <PersistedEventRecord>[]).add(event);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            entry.key,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
      widgets.addAll(
        entry.value.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: TimelineEventTile(event: event),
          ),
        ),
      );
      widgets.add(Gaps.v8);
    }
    return widgets;
  }
}
