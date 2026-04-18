import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/features/nutrition/nutrition_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianNutritionScreen extends ConsumerWidget {
  const GuardianNutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(guardianNutritionMonitoringDataProvider);
    return AppScaffoldShell(
      title: 'Nutrition monitoring',
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load nutrition: $error')),
        data: (data) {
          final profileName = data.seniorProfile?.displayName ?? 'Senior';
          return ListView(
            children: [
              Text(
                profileName,
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
                        'Today: ${data.todayState.completedCount}/${data.todayState.slots.length} meals completed',
                      ),
                      Gaps.v4,
                      Text(
                        'Pending ${data.todayState.pendingCount} • Missed ${data.todayState.missedCount}',
                      ),
                      Gaps.v8,
                      Text(
                        'Last 7 days: ${data.completedLast7Days} completed • ${data.missedLast7Days} missed',
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.v16,
              Text(
                'Recent nutrition activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Gaps.v8,
              if (data.recentEvents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No meal events yet.'),
                  ),
                )
              else
                ...data.recentEvents.take(15).map(
                      (event) => Card(
                        child: ListTile(
                          title: Text(event.type.timelineLabel),
                          subtitle: Text(formatEventDetail(event)),
                          trailing: Icon(iconForEventType(event.type)),
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
