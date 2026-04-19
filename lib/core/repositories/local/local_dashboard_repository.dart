import 'package:senior_companion/core/events/status_engine.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
import 'package:senior_companion/core/repositories/dashboard_repository.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class LocalDashboardRepository implements DashboardRepository {
  const LocalDashboardRepository({
    required this.eventRepository,
    required this.statusEngine,
    required this.activeSeniorResolver,
    required this.logger,
  });

  final EventRepository eventRepository;
  final SeniorStatusEngine statusEngine;
  final ActiveSeniorResolver activeSeniorResolver;
  final AppLogger logger;

  @override
  Future<DashboardSummary> fetchDashboardSummary({String? seniorId}) async {
    final resolvedSeniorId =
        seniorId ?? await activeSeniorResolver.resolveActiveSeniorId();
    if (resolvedSeniorId == null) {
      logger.debug(
        'LocalDashboardRepository: no active senior resolved, returning empty summary',
      );
      return const DashboardSummary(
        globalStatus: SeniorGlobalStatus.ok,
        pendingAlerts: 0,
        todayCheckIns: 0,
        missedMedications: 0,
        openIncidents: 0,
      );
    }

    final timeline = await eventRepository.fetchTimelineForSenior(
      resolvedSeniorId,
      order: TimelineOrder.oldestFirst,
    );
    final evaluation = statusEngine.evaluate(timeline);
    return DashboardSummary(
      globalStatus: evaluation.status,
      pendingAlerts: evaluation.pendingAlerts,
      todayCheckIns: evaluation.todayCheckIns,
      missedMedications: evaluation.missedMedications,
      openIncidents: evaluation.openIncidents,
      lastCheckInAt: evaluation.lastCheckInAt,
      nextScheduledReminder: null,
    );
  }
}
