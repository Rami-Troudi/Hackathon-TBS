import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/features/guardian/guardian_alerts_providers.dart';
import 'package:senior_companion/features/guardian/guardian_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
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

class GuardianAlertsScreen extends ConsumerWidget {
  const GuardianAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(guardianAlertsDataProvider);

    return AppScaffoldShell(
      title: _tr(
        context,
        fr: 'Alertes aidant',
        en: 'Guardian Alerts',
        ar: 'تنبيهات المرافق',
      ),
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianAlerts,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.guardianTimeline),
          icon: const Icon(Icons.timeline_outlined),
          tooltip:
              _tr(context, fr: 'Chronologie', en: 'Timeline', ar: 'التسلسل'),
        ),
      ],
      child: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            _tr(
              context,
              fr: 'Impossible de charger les alertes : $error',
              en: 'Could not load alerts: $error',
              ar: 'تعذر تحميل التنبيهات: $error',
            ),
          ),
        ),
        data: (data) {
          if (data.seniorId == null) {
            return Center(
              child: Text(
                _tr(
                  context,
                  fr: 'Aucun senior lié pour les alertes.',
                  en: 'No linked senior for alerts.',
                  ar: 'لا يوجد مسن مرتبط للتنبيهات.',
                ),
              ),
            );
          }

          return ListView(
            children: [
              Text(
                data.seniorProfile?.displayName ?? data.seniorId!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Gaps.v4,
              Text(
                '${_tr(context, fr: 'Actives', en: 'Active', ar: 'نشطة')} ${data.activeCount} • ${_tr(context, fr: 'Accusées', en: 'Acknowledged', ar: 'تم الاطلاع')} ${data.acknowledgedCount} • ${_tr(context, fr: 'Résolues', en: 'Resolved', ar: 'تم الحل')} ${data.resolvedCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Gaps.v16,
              if (data.alerts.isEmpty)
                EmptyStateBlock(
                  icon: Icons.notifications_none_outlined,
                  title: _tr(
                    context,
                    fr: 'Aucune alerte pour le moment',
                    en: 'No alerts right now',
                    ar: 'لا توجد تنبيهات الآن',
                  ),
                  description: _tr(
                    context,
                    fr:
                        'La surveillance locale n’a rien détecté qui nécessite une action.',
                    en:
                        'Local monitoring has not found anything that needs attention.',
                    ar:
                        'المراقبة المحلية لم ترصد شيئًا يحتاج إلى تدخل.',
                  ),
                )
              else
                ...data.alerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AlertListCard(
                      alert: alert,
                      onAcknowledge: alert.state == GuardianAlertState.active
                          ? () => _acknowledgeAlert(ref, alert.id)
                          : null,
                      onResolve: alert.state != GuardianAlertState.resolved
                          ? () => _resolveAlert(ref, alert.id)
                          : null,
                      onOpenTimeline: () =>
                          context.push(AppRoutes.guardianTimeline),
                      onOpenMonitoring: () => context.push(
                        _routeForDestination(alert.destination),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _acknowledgeAlert(WidgetRef ref, String alertId) async {
    await ref.read(guardianAlertRepositoryProvider).acknowledgeAlert(alertId);
    ref.invalidate(guardianAlertsDataProvider);
    ref.invalidate(guardianHomeDataProvider);
  }

  Future<void> _resolveAlert(WidgetRef ref, String alertId) async {
    await ref.read(guardianAlertRepositoryProvider).resolveAlert(alertId);
    ref.invalidate(guardianAlertsDataProvider);
    ref.invalidate(guardianHomeDataProvider);
  }

  String _routeForDestination(GuardianMonitoringDestination destination) {
    return switch (destination) {
      GuardianMonitoringDestination.timeline => AppRoutes.guardianTimeline,
      GuardianMonitoringDestination.checkIns => AppRoutes.guardianCheckIns,
      GuardianMonitoringDestination.medication => AppRoutes.guardianMedication,
      GuardianMonitoringDestination.hydration => AppRoutes.guardianHydration,
      GuardianMonitoringDestination.nutrition => AppRoutes.guardianNutrition,
      GuardianMonitoringDestination.location => AppRoutes.guardianLocation,
      GuardianMonitoringDestination.incidents => AppRoutes.guardianIncidents,
    };
  }
}
