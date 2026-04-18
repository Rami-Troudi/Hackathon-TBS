import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class GuardianAlertsData {
  const GuardianAlertsData({
    required this.seniorId,
    required this.seniorProfile,
    required this.alerts,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final List<GuardianAlert> alerts;

  int get activeCount =>
      alerts.where((alert) => alert.state == GuardianAlertState.active).length;
  int get acknowledgedCount => alerts
      .where((alert) => alert.state == GuardianAlertState.acknowledged)
      .length;
  int get resolvedCount => alerts
      .where((alert) => alert.state == GuardianAlertState.resolved)
      .length;
}

final guardianAlertsDataProvider =
    FutureProvider.autoDispose<GuardianAlertsData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final alertRepository = ref.watch(guardianAlertRepositoryProvider);

  final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const GuardianAlertsData(
      seniorId: null,
      seniorProfile: null,
      alerts: <GuardianAlert>[],
    );
  }

  final seniorProfile = await profileRepository.getSeniorProfileById(seniorId);
  final alerts = await alertRepository.fetchAlertsForSenior(seniorId);
  return GuardianAlertsData(
    seniorId: seniorId,
    seniorProfile: seniorProfile,
    alerts: alerts,
  );
});
