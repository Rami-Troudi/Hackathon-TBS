import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class GuardianProfileOverviewData {
  const GuardianProfileOverviewData({
    required this.activeSeniorId,
    required this.seniorProfile,
    required this.guardianProfile,
    required this.linkedGuardians,
    required this.dashboardSummary,
  });

  final String? activeSeniorId;
  final SeniorProfile? seniorProfile;
  final GuardianProfile? guardianProfile;
  final List<GuardianProfile> linkedGuardians;
  final DashboardSummary dashboardSummary;
}

final guardianProfileOverviewProvider =
    FutureProvider.autoDispose<GuardianProfileOverviewData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final appSessionRepository = ref.watch(appSessionRepositoryProvider);
  final dashboardRepository = ref.watch(dashboardRepositoryProvider);

  final activeSeniorId = await activeSeniorResolver.resolveActiveSeniorId();
  if (activeSeniorId == null) {
    return const GuardianProfileOverviewData(
      activeSeniorId: null,
      seniorProfile: null,
      guardianProfile: null,
      linkedGuardians: <GuardianProfile>[],
      dashboardSummary: DashboardSummary(
        globalStatus: SeniorGlobalStatus.ok,
        pendingAlerts: 0,
        todayCheckIns: 0,
        missedMedications: 0,
        openIncidents: 0,
      ),
    );
  }

  final session = await appSessionRepository.getSession();
  final seniorProfile =
      await profileRepository.getSeniorProfileById(activeSeniorId);
  final linkedGuardians =
      await profileRepository.getLinkedGuardians(activeSeniorId);
  final dashboardSummary = await dashboardRepository.fetchDashboardSummary(
    seniorId: activeSeniorId,
  );
  final guardianProfile = session != null &&
          session.activeRole == AppRole.guardian
      ? await profileRepository.getGuardianProfileById(session.activeProfileId)
      : null;

  return GuardianProfileOverviewData(
    activeSeniorId: activeSeniorId,
    seniorProfile: seniorProfile,
    guardianProfile: guardianProfile,
    linkedGuardians: linkedGuardians,
    dashboardSummary: dashboardSummary,
  );
});
