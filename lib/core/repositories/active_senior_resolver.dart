import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/shared/models/app_role.dart';

class ActiveSeniorResolver {
  const ActiveSeniorResolver({
    required this.appSessionRepository,
    required this.profileRepository,
  });

  final AppSessionRepository appSessionRepository;
  final ProfileRepository profileRepository;

  Future<String?> resolveActiveSeniorId() async {
    final session = await appSessionRepository.getSession();
    if (session == null) return null;

    return switch (session.activeRole) {
      AppRole.senior => session.activeProfileId,
      AppRole.guardian => _resolveSeniorForGuardian(session.activeProfileId),
    };
  }

  Future<String?> _resolveSeniorForGuardian(String guardianId) async {
    final linkedSeniors = await profileRepository.getLinkedSeniors(guardianId);
    if (linkedSeniors.isNotEmpty) {
      return linkedSeniors.first.id;
    }
    return null;
  }
}
