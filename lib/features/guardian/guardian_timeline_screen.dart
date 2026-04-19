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

String _tr(
  BuildContext context, {
  required String fr,
  required String en,
  required String ar,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'en':
      return en;
    default:
      return fr;
  }
}

class GuardianTimelineScreen extends ConsumerWidget {
  const GuardianTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(guardianTimelineDataProvider);
    final filteredAsync = ref.watch(guardianFilteredTimelineProvider);
    final filter = ref.watch(guardianTimelineFilterProvider);

    return AppScaffoldShell(
      title: _tr(
        context,
        fr: 'Chronologie aidant',
        en: 'Guardian Timeline',
        ar: 'تسلسل المرافق',
      ),
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianTimeline,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianAlerts),
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: _tr(context, fr: 'Alertes', en: 'Alerts', ar: 'التنبيهات'),
        ),
      ],
      child: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            _tr(
              context,
              fr: 'Impossible de charger la chronologie : $error',
              en: 'Could not load timeline: $error',
              ar: 'تعذر تحميل التسلسل: $error',
            ),
          ),
        ),
        data: (data) {
          if (data.seniorId == null) {
            return Center(
              child: Text(
                _tr(
                  context,
                  fr: 'Aucun senior lié pour la chronologie.',
                  en: 'No linked senior for timeline.',
                  ar: 'لا يوجد مسن مرتبط للتسلسل.',
                ),
              ),
            );
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
                          label: Text(_labelForFilter(context, option)),
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
                EmptyStateBlock(
                  icon: Icons.timeline_outlined,
                  title: _tr(
                    context,
                    fr: 'Aucun événement pour ce filtre',
                    en: 'No events for this filter',
                    ar: 'لا توجد أحداث لهذا الفلتر',
                  ),
                  description: _tr(
                    context,
                    fr:
                        'Essayez une autre catégorie ou générez de l’activité démo depuis le hub développeur.',
                    en:
                        'Try another category or generate demo activity from the developer hub.',
                    ar:
                        'جرّب فئة أخرى أو أنشئ نشاطًا تجريبيًا من مركز المطور.',
                  ),
                )
              else
                ..._buildDayGroups(context, events),
            ],
          );
        },
      ),
    );
  }

  String _labelForFilter(BuildContext context, GuardianTimelineFilter filter) {
    return switch (filter) {
      GuardianTimelineFilter.all => _tr(
          context,
          fr: 'Tout',
          en: 'All',
          ar: 'الكل',
        ),
      GuardianTimelineFilter.checkIns => _tr(
          context,
          fr: 'Check-ins',
          en: 'Check-ins',
          ar: 'تأكيدات الحضور',
        ),
      GuardianTimelineFilter.medication => _tr(
          context,
          fr: 'Médication',
          en: 'Medication',
          ar: 'الأدوية',
        ),
      GuardianTimelineFilter.location => _tr(
          context,
          fr: 'Localisation',
          en: 'Location',
          ar: 'الموقع',
        ),
      GuardianTimelineFilter.incidents => _tr(
          context,
          fr: 'Incidents',
          en: 'Incidents',
          ar: 'الحوادث',
        ),
      GuardianTimelineFilter.emergency => _tr(
          context,
          fr: 'Urgence',
          en: 'Emergency',
          ar: 'الطوارئ',
        ),
      GuardianTimelineFilter.wellbeing => _tr(
          context,
          fr: 'Bien-être',
          en: 'Wellbeing',
          ar: 'الرفاهية',
        ),
    };
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
