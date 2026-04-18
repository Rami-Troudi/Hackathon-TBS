import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/dashboard_repository.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

/// Simulated network latency for mock repository responses.
/// Keep this short enough not to slow down development, but long enough
/// to surface real loading states in the UI.
const _kMockDelay = Duration(milliseconds: 350);

class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository({
    required this.logger,
  });

  final AppLogger logger;

  @override
  Future<DashboardSummary> fetchDashboardSummary() async {
    logger.debug('MockDashboardRepository: loading mock dashboard summary');
    await Future<void>.delayed(_kMockDelay);

    return DashboardSummary(
      globalStatus: SeniorGlobalStatus.watch,
      pendingAlerts: 2,
      todayCheckIns: 1,
      missedMedications: 1,
      openIncidents: 0,
      lastCheckInAt: DateTime.now().subtract(const Duration(hours: 3)),
      nextScheduledReminder: DateTime.now().add(const Duration(hours: 2)),
    );
  }
}
