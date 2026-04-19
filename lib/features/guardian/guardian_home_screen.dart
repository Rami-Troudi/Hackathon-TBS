import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';
import 'package:senior_companion/shared/widgets/connectivity_banner.dart';

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

class GuardianHomeScreen extends ConsumerWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(guardianHomeDataProvider);
    final connectivityState =
        ref.watch(connectivityStateProvider).valueOrNull ??
            AppConnectivityState.online;

    return AppScaffoldShell(
      title: _tr(
        context,
        fr: 'Tableau aidant',
        en: 'Guardian Dashboard',
        ar: 'لوحة المرافق',
      ),
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianHome,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianAlerts),
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: _tr(context, fr: 'Alertes', en: 'Alerts', ar: 'التنبيهات'),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianTimeline),
          icon: const Icon(Icons.timeline_outlined),
          tooltip:
              _tr(context, fr: 'Chronologie', en: 'Timeline', ar: 'التسلسل'),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          tooltip:
              _tr(context, fr: 'Paramètres', en: 'Settings', ar: 'الإعدادات'),
        ),
      ],
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            _tr(
              context,
              fr: 'Impossible de charger le tableau: $error',
              en: 'Could not load dashboard: $error',
              ar: 'تعذر تحميل اللوحة: $error',
            ),
          ),
        ),
        data: (data) {
          if (data.activeSeniorId == null) {
            return Center(
              child: Text(
                _tr(
                  context,
                  fr: 'Aucun senior lié dans cette session aidant.',
                  en: 'No linked senior found in this guardian session.',
                  ar: 'لا يوجد مسن مرتبط في جلسة المرافق هذه.',
                ),
              ),
            );
          }

          final canShowSeniorInfo = data.settings.linkedSeniorInfoVisible;
          final seniorName = canShowSeniorInfo
              ? data.seniorProfile?.displayName ?? data.activeSeniorId!
              : _tr(
                  context,
                  fr: 'Senior lié',
                  en: 'Linked senior',
                  ar: 'المسن المرتبط',
                );
          final guardianLabel = data.guardianProfile == null
              ? _tr(
                  context,
                  fr: 'Vue aidant',
                  en: 'Guardian view',
                  ar: 'عرض المرافق',
                )
              : '${data.guardianProfile!.displayName} • ${data.guardianProfile!.relationshipLabel}';

          return ListView(
            children: [
              Text(
                seniorName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v4,
              Text(
                guardianLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (connectivityState != AppConnectivityState.online) ...[
                Gaps.v16,
                ConnectivityBanner(state: connectivityState),
              ],
              Gaps.v16,
              _GlobalStatusCard(
                status: data.dashboardSummary.globalStatus,
                statusDescription:
                    data.dashboardSummary.globalStatus.description,
                pendingAlerts: data.pendingActiveAlerts,
                todayCheckIns: data.dashboardSummary.todayCheckIns,
                missedMedications: data.dashboardSummary.missedMedications,
                openIncidents: data.dashboardSummary.openIncidents,
              ),
              Gaps.v16,
              _QuickActionRow(
                onAlerts: () => context.push(AppRoutes.guardianAlerts),
                onTimeline: () => context.push(AppRoutes.guardianTimeline),
                onProfile: () => context.push(AppRoutes.guardianProfile),
              ),
              Gaps.v16,
              if (data.settings.showCheckInMonitoring) ...[
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Check-ins',
                    en: 'Check-ins',
                    ar: 'تأكيدات الحضور',
                  ),
                  subtitle: _checkInSubtitle(context, data.checkInState),
                  icon: Icons.check_circle_outline,
                  onTap: () => context.push(AppRoutes.guardianCheckIns),
                ),
                Gaps.v8,
              ],
              if (data.settings.showMedicationReminders) ...[
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Médication',
                    en: 'Medication',
                    ar: 'الأدوية',
                  ),
                  subtitle:
                      '${_tr(context, fr: 'Pris', en: 'Taken', ar: 'تم') } ${data.todayMedicationTaken} • ${_tr(context, fr: 'Manqué', en: 'Missed', ar: 'فائت')} ${data.todayMedicationMissed} • ${_tr(context, fr: 'En attente', en: 'Pending', ar: 'معلّق')} ${data.todayMedicationPending}',
                  icon: Icons.medication_outlined,
                  onTap: () => context.push(AppRoutes.guardianMedication),
                ),
                Gaps.v8,
              ],
              if (data.settings.showIncidentMonitoring) ...[
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Incidents',
                    en: 'Incidents',
                    ar: 'الحوادث',
                  ),
                  subtitle:
                      '${_tr(context, fr: 'Suspects ouverts', en: 'Open suspected', ar: 'مشتبه به مفتوح')} ${data.incidentState.openSuspectedIncidents} • ${_tr(context, fr: 'Confirmés ouverts', en: 'Open confirmed', ar: 'مؤكد مفتوح')} ${data.incidentState.openConfirmedIncidents} • ${_incidentLabel(context, data.incidentState.status)}',
                  icon: Icons.report_gmailerrorred_outlined,
                  onTap: () => context.push(AppRoutes.guardianIncidents),
                ),
              ],
              if (data.settings.showHydrationReminders) ...[
                Gaps.v8,
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Hydratation',
                    en: 'Hydration',
                    ar: 'الترطيب',
                  ),
                  subtitle:
                      '${_tr(context, fr: 'Complété', en: 'Completed', ar: 'مكتمل')} ${data.hydrationState.completedCount}/${data.hydrationState.dailyGoalCompletions} • ${_tr(context, fr: 'Manqué', en: 'Missed', ar: 'فائت')} ${data.hydrationState.missedCount}',
                  icon: Icons.local_drink_outlined,
                  onTap: () => context.push(AppRoutes.guardianHydration),
                ),
              ],
              if (data.settings.showNutritionReminders) ...[
                Gaps.v8,
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Nutrition',
                    en: 'Nutrition',
                    ar: 'التغذية',
                  ),
                  subtitle:
                      '${_tr(context, fr: 'Complété', en: 'Completed', ar: 'مكتمل')} ${data.nutritionState.completedCount}/${data.nutritionState.slots.length} • ${_tr(context, fr: 'Manqué', en: 'Missed', ar: 'فائت')} ${data.nutritionState.missedCount}',
                  icon: Icons.restaurant_outlined,
                  onTap: () => context.push(AppRoutes.guardianNutrition),
                ),
              ],
              if (data.settings.showLocationUpdates) ...[
                Gaps.v8,
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Localisation',
                    en: 'Location',
                    ar: 'الموقع',
                  ),
                  subtitle: data.safeZoneStatus.zoneLabel,
                  icon: Icons.my_location_outlined,
                  onTap: () => context.push(AppRoutes.guardianLocation),
                ),
              ],
              if (data.settings.dailyDigestEnabled ||
                  data.settings.weeklyDigestEnabled) ...[
                Gaps.v8,
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Résumé quotidien',
                    en: 'Daily digest',
                    ar: 'الملخص اليومي',
                  ),
                  subtitle: data.dailySummary.headline,
                  icon: Icons.summarize_outlined,
                  onTap: () => context.push(AppRoutes.guardianSummary),
                ),
              ],
              if (data.settings.showInsightsModule) ...[
                Gaps.v8,
                MonitoringCard(
                  title: _tr(
                    context,
                    fr: 'Insights IA',
                    en: 'AI insights',
                    ar: 'رؤى الذكاء الاصطناعي',
                  ),
                  subtitle: _tr(
                    context,
                    fr:
                        'Questions/réponses ancrées et explications depuis les données locales',
                    en: 'Grounded Q&A and smart explanations from local data',
                    ar: 'أسئلة وأجوبة وتفسيرات مبنية على البيانات المحلية',
                  ),
                  icon: Icons.smart_toy_outlined,
                  onTap: () => context.push(AppRoutes.guardianInsights),
                ),
              ],
              Gaps.v16,
              _TopAlertsCard(
                alerts: data.topAlerts,
                onOpenAlerts: () => context.push(AppRoutes.guardianAlerts),
              ),
              Gaps.v16,
              _RecentEventsCard(
                events: data.recentImportantEvents,
                onOpenTimeline: () => context.push(AppRoutes.guardianTimeline),
              ),
            ],
          );
        },
      ),
    );
  }

  String _checkInSubtitle(BuildContext context, CheckInState state) {
    return switch (state.status) {
      CheckInStatus.completed =>
        _tr(
          context,
          fr: 'Complété aujourd’hui à ${formatLocalTime(state.completedAt!)}',
          en: 'Today completed at ${formatLocalTime(state.completedAt!)}',
          ar: 'تم التأكيد اليوم عند ${formatLocalTime(state.completedAt!)}',
        ),
      CheckInStatus.missed =>
        _tr(
          context,
          fr:
              'Manqué aujourd’hui à ${formatLocalTime(state.missedAt ?? state.windowEnd)}',
          en: 'Today missed at ${formatLocalTime(state.missedAt ?? state.windowEnd)}',
          ar:
              'فائت اليوم عند ${formatLocalTime(state.missedAt ?? state.windowEnd)}',
        ),
      CheckInStatus.pending =>
        _tr(
          context,
          fr:
              'En attente aujourd’hui (${formatLocalTime(state.windowStart)}-${formatLocalTime(state.windowEnd)})',
          en:
              'Pending today (${formatLocalTime(state.windowStart)}-${formatLocalTime(state.windowEnd)})',
          ar:
              'معلّق اليوم (${formatLocalTime(state.windowStart)}-${formatLocalTime(state.windowEnd)})',
        ),
    };
  }

  String _incidentLabel(BuildContext context, IncidentFlowStatus status) =>
      switch (status) {
        IncidentFlowStatus.clear => _tr(
            context,
            fr: 'Aucun incident actif',
            en: 'No active incident',
            ar: 'لا يوجد حادث نشط',
          ),
        IncidentFlowStatus.suspected => _tr(
            context,
            fr: 'Incident suspect en cours',
            en: 'Suspicious incident open',
            ar: 'حادث مشتبه به مفتوح',
          ),
        IncidentFlowStatus.confirmed => _tr(
            context,
            fr: 'Incident confirmé en cours',
            en: 'Confirmed incident open',
            ar: 'حادث مؤكد مفتوح',
          ),
        IncidentFlowStatus.emergency => _tr(
            context,
            fr: 'État d’urgence',
            en: 'Emergency state',
            ar: 'حالة طوارئ',
          ),
      };
}

class _GlobalStatusCard extends StatelessWidget {
  const _GlobalStatusCard({
    required this.status,
    required this.statusDescription,
    required this.pendingAlerts,
    required this.todayCheckIns,
    required this.missedMedications,
    required this.openIncidents,
  });

  final SeniorGlobalStatus status;
  final String statusDescription;
  final int pendingAlerts;
  final int todayCheckIns;
  final int missedMedications;
  final int openIncidents;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: status == SeniorGlobalStatus.actionRequired
          ? AppCardTone.danger
          : status == SeniorGlobalStatus.watch
              ? AppCardTone.warning
              : AppCardTone.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(status: status),
          Gaps.v12,
          Text(
            statusDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Gaps.v16,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _Metric(
                  label: _tr(
                    context,
                    fr: 'Alertes en attente',
                    en: 'Pending alerts',
                    ar: 'تنبيهات معلقة',
                  ),
                  value: pendingAlerts,
                  highlight: pendingAlerts > 0),
              _Metric(
                label: _tr(
                  context,
                  fr: 'Check-ins du jour',
                  en: 'Today check-ins',
                  ar: 'تأكيدات اليوم',
                ),
                value: todayCheckIns,
              ),
              _Metric(
                  label: _tr(
                    context,
                    fr: 'Médicaments manqués',
                    en: 'Missed meds',
                    ar: 'أدوية فائتة',
                  ),
                  value: missedMedications,
                  highlight: missedMedications > 0),
              _Metric(
                  label: _tr(
                    context,
                    fr: 'Incidents ouverts',
                    en: 'Open incidents',
                    ar: 'حوادث مفتوحة',
                  ),
                  value: openIncidents,
                  highlight: openIncidents > 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.onAlerts,
    required this.onTimeline,
    required this.onProfile,
  });

  final VoidCallback onAlerts;
  final VoidCallback onTimeline;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAlerts,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(_tr(context, fr: 'Alertes', en: 'Alerts', ar: 'التنبيهات')),
          ),
        ),
        Gaps.h8,
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTimeline,
            icon: const Icon(Icons.timeline_outlined),
            label: Text(_tr(context, fr: 'Chronologie', en: 'Timeline', ar: 'التسلسل')),
          ),
        ),
        Gaps.h8,
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onProfile,
            icon: const Icon(Icons.person_outline),
            label: Text(_tr(context, fr: 'Senior', en: 'Senior', ar: 'المسن')),
          ),
        ),
      ],
    );
  }
}

class _TopAlertsCard extends StatelessWidget {
  const _TopAlertsCard({
    required this.alerts,
    required this.onOpenAlerts,
  });

  final List<GuardianAlert> alerts;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: _tr(context, fr: 'Alertes prioritaires', en: 'Top alerts', ar: 'أهم التنبيهات'),
            actionLabel: _tr(context, fr: 'Voir tout', en: 'View all', ar: 'عرض الكل'),
            onAction: onOpenAlerts,
          ),
          if (alerts.isEmpty)
            Text(
              _tr(
                context,
                fr: 'Aucune alerte pour le moment.',
                en: 'No alerts right now.',
                ar: 'لا توجد تنبيهات الآن.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    SeverityChip(severity: alert.severity),
                    Gaps.h8,
                    Expanded(child: Text(alert.title)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentEventsCard extends StatelessWidget {
  const _RecentEventsCard({
    required this.events,
    required this.onOpenTimeline,
  });

  final List<PersistedEventRecord> events;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: _tr(
              context,
              fr: 'Événements importants récents',
              en: 'Recent important events',
              ar: 'الأحداث المهمة الأخيرة',
            ),
            actionLabel:
                _tr(context, fr: 'Chronologie', en: 'Timeline', ar: 'التسلسل'),
            onAction: onOpenTimeline,
          ),
          if (events.isEmpty)
            Text(
              _tr(
                context,
                fr: 'Aucun événement important pour le moment.',
                en: 'No important events yet.',
                ar: 'لا توجد أحداث مهمة بعد.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...events.take(5).map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(iconForEventType(event.type), size: 18),
                        Gaps.h8,
                        Expanded(
                          child: Text(
                            '${event.type.timelineLabel} • ${formatLocalTime(event.happenedAt)}\n${formatEventDetail(event)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
