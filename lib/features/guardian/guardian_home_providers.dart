import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';

class GuardianHomeData {
  const GuardianHomeData({
    required this.activeSeniorId,
    required this.dashboardSummary,
    required this.recentEvents,
  });

  final String? activeSeniorId;
  final DashboardSummary dashboardSummary;
  final List<PersistedEventRecord> recentEvents;
}

final guardianHomeDataProvider =
    FutureProvider.autoDispose<GuardianHomeData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final dashboardRepository = ref.watch(dashboardRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);

  final activeSeniorId = await activeSeniorResolver.resolveActiveSeniorId();
  final summary = await dashboardRepository.fetchDashboardSummary(
    seniorId: activeSeniorId,
  );
  final recentEvents = activeSeniorId == null
      ? const <PersistedEventRecord>[]
      : await eventRepository.fetchRecentEventsForSenior(
          activeSeniorId,
          limit: 8,
        );

  return GuardianHomeData(
    activeSeniorId: activeSeniorId,
    dashboardSummary: summary,
    recentEvents: recentEvents,
  );
});
